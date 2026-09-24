use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::Kernel::Inotify;
use Linux::Event::Loop;

sub append_file ($path, $text) {
    open my $fh, '>>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
}

my $dir = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($dir, 'log.txt');
open my $seed, '>', $path or die "open $path: $!";
print {$seed} "start\n";
close $seed;

my $loop = Linux::Event::Loop->new;
my $inotify = Linux::Event::Kernel::Inotify->new;
my @seen;

my $watch = $inotify->watch(
    $path,
    on_modify => sub ($event) {
        push @seen, ['modify', $event->path];
    },
    on_close_write => sub ($event) {
        push @seen, ['close_write', $event->path];
    },
);

is($inotify->state, 'unattached', 'new Inotify starts unattached');
is($watch->state, 'pending', 'detached watch is only a pending specification');
ok(!$watch->is_active, 'pending watch is not active');
ok(!defined($inotify->fd), 'detached Inotify has no kernel fd');

append_file($path, "before attach\n");
$loop->add($inotify);

ok($inotify->is_active, 'Loop add activates Inotify');
ok($watch->is_active, 'Loop add activates pending watch');
ok(defined($inotify->fd), 'attached Inotify owns a kernel fd');
is($loop->run_once(0), 0, 'pre-attachment filesystem activity was not queued');
is_deeply(\@seen, [], 'no callback reports pre-attachment activity');

append_file($path, "after attach\n");
ok($loop->run_once(1000) >= 1, 'attached inotify fd becomes ready');
ok((grep { $_->[0] eq 'modify' } @seen), 'on_modify receives live activity');
ok((grep { $_->[0] eq 'close_write' } @seen),
    'on_close_write receives writer close');
is((grep { $_->[1] eq $path } @seen), scalar(@seen),
    'file events report the watched absolute path');

my $before_cancel = scalar @seen;
$watch->cancel;
ok($watch->is_terminal, 'cancel is terminal for a child Watch');
is($watch->state, 'cancelled', 'cancel records terminal state');

append_file($path, "after cancel\n");
$loop->run_once(100);
is(scalar(@seen), $before_cancel, 'cancelled Watch receives no later callbacks');

my $ignored = 0;
my $cancelled = $inotify->watch(
    $path,
    on_modify => sub ($event) { },
    on_ignored => sub ($event) { $ignored++ },
);
$cancelled->cancel;
$loop->run_once(100);
is($ignored, 0, 'explicit cancellation does not deliver on_ignored');

$inotify->close;
ok($inotify->is_terminal, 'parent close is terminal');
is($inotify->state, 'closed', 'parent close records closed state');
ok(!defined($inotify->loop), 'closed Inotify releases Loop ownership');
ok(!defined($inotify->fd), 'closed Inotify releases kernel fd');

my $attached = Linux::Event::Kernel::Inotify->new(loop => $loop);
ok($attached->is_active, 'loop constructor option attaches immediately');
is($attached->watch_count, 0, 'attached Inotify may start with zero watches');

my $late = $attached->watch(
    $path,
    on_modify => sub ($event) { },
);
ok($late->is_active, 'watch on attached parent activates immediately');

my $missing = File::Spec->catfile($dir, 'missing.txt');
my $before = $attached->watch_count;
my $live_error = eval {
    $attached->watch(
        $missing,
        on_modify => sub ($event) { },
    );
    '';
};
$live_error = $@ if !defined($live_error) || $live_error eq '';
like($live_error, qr/inotify_add_watch .*No such file|inotify_add_watch .*not found/i,
    'live watch activation fails synchronously for missing path');
is($attached->watch_count, $before,
    'failed live watch does not leave a half-created subscription');

$attached->close;

my $retry_loop = Linux::Event::Loop->new;
my $retry = Linux::Event::Kernel::Inotify->new;
my $pending = $retry->watch(
    $missing,
    on_modify => sub ($event) { },
);

my $attach_ok = eval { $retry_loop->add($retry); 1 };
my $attach_error = $@;
ok(!$attach_ok, 'attachment fails when a pending watch cannot be installed');
like($attach_error, qr/inotify_add_watch .*No such file|inotify_add_watch .*not found/i,
    'attachment reports the failed path');
is($retry->state, 'unattached', 'failed attachment is transactional');
is($pending->state, 'pending', 'failed attachment restores pending Watch state');
ok(!defined($retry->fd), 'failed attachment closes temporary inotify fd');

open my $created, '>', $missing or die "open $missing: $!";
close $created;
$retry_loop->add($retry);
ok($retry->is_active, 'transactionally failed parent can attach after path exists');
ok($pending->is_active, 'restored pending Watch activates on retry');
$retry->close;

done_testing;
