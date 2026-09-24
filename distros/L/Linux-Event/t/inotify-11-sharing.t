use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::Kernel::Inotify;
use Linux::Event::Loop;

sub fdinfo_mask ($fd, $wanted_wd) {
    my $path = "/proc/self/fdinfo/$fd";
    open my $fh, '<', $path or return undef;
    while (my $line = <$fh>) {
        next if $line !~ /^inotify\s+/;
        my ($wd_hex) = $line =~ /\bwd:([0-9a-f]+)\b/i;
        my ($mask_hex) = $line =~ /\bmask:([0-9a-f]+)\b/i;
        next if !defined($wd_hex) || !defined($mask_hex);
        next if hex($wd_hex) != $wanted_wd;
        close $fh;
        return hex($mask_hex);
    }
    close $fh;
    return undef;
}

sub append_file ($path, $text) {
    open my $fh, '>>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
}

my $dir = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($dir, 'shared.txt');
my $alias = File::Spec->catfile($dir, 'shared-link.txt');
open my $seed, '>', $path or die "open $path: $!";
close $seed;
link $path, $alias or die "link $path -> $alias: $!";

my $loop = Linux::Event::Loop->new;
my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);

my (@modify, @close_write);
my $a = $inotify->watch(
    $path,
    on_modify => sub ($event) { push @modify, $event->path },
);
my $b = $inotify->watch(
    $alias,
    on_close_write => sub ($event) { push @close_write, $event->path },
);

is($a->_wd, $b->_wd,
    'hard-link aliases share one underlying kernel watch descriptor');
is($inotify->watch_count, 2,
    'shared kernel descriptor still has two logical Watch objects');

my $wd = $a->_wd;
my $mask = fdinfo_mask($inotify->fd, $wd);
SKIP: {
    skip '/proc fdinfo does not expose inotify masks on this system', 3
        if !defined $mask;
    ok($mask & Linux::Event::Kernel::Inotify::IN_MODIFY(),
        'shared kernel mask contains first logical event');
    ok($mask & Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE(),
        'shared kernel mask contains second logical event');

    $a->cancel;
    my $shrunk = fdinfo_mask($inotify->fd, $wd);
    ok(defined($shrunk)
        && !($shrunk & Linux::Event::Kernel::Inotify::IN_MODIFY())
        && ($shrunk & Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE()),
        'cancelling one logical Watch shrinks the shared kernel mask');
}
$a->cancel if !$a->is_terminal;

append_file($alias, "shared\n");
$loop->run_once(1000);
is_deeply(\@modify, [], 'cancelled shared Watch receives no callback');
is_deeply(\@close_write, [$alias],
    'surviving shared Watch receives event with its own logical path');

my @dir_events;
my $dir_watch = $inotify->watch(
    $dir,
    on_create => sub ($event) { push @dir_events, $event->name },
);
my $dir_wd = $dir_watch->_wd;
my $before_mask = fdinfo_mask($inotify->fd, $dir_wd);
my $before_count = $inotify->watch_count;

my $conflict_ok = eval {
    $inotify->watch(
        $dir,
        excl_unlink => 1,
        on_delete => sub ($event) { },
    );
    1;
};
my $conflict_error = $@;
ok(!$conflict_ok, 'incompatible excl_unlink policy is rejected for shared inode');
like($conflict_error, qr/excl_unlink must match/,
    'shared-inode option conflict reports the policy mismatch');
is($inotify->watch_count, $before_count,
    'rejected shared-inode Watch is not retained');

my $after_mask = fdinfo_mask($inotify->fd, $dir_wd);
is($after_mask, $before_mask,
    'rejected shared-inode Watch does not clobber existing kernel mask')
    if defined($before_mask) && defined($after_mask);

my $only_dir_ok = eval {
    $inotify->watch(
        $path,
        only_dir => 1,
        on_modify => sub ($event) { },
    );
    1;
};
my $only_dir_error = $@;
ok(!$only_dir_ok, 'only_dir rejects a regular file');
like($only_dir_error, qr/Not a directory|ENOTDIR/i, 'only_dir failure is synchronous');

$b->cancel;
$dir_watch->cancel;
$inotify->close;

done_testing;
