use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::Kernel::Inotify;
use Linux::Event::Loop;

sub pump_until ($loop, $predicate, $turns = 20) {
    for (1 .. $turns) {
        return 1 if $predicate->();
        $loop->run_once(100);
    }
    return $predicate->() ? 1 : 0;
}

my $dir = tempdir(CLEANUP => 1);
my $loop = Linux::Event::Loop->new;
my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);

my (@created, @moved_from, @moved_to, @deleted, @all);
my $dir_watch = $inotify->watch(
    $dir,
    on_create => sub ($event) { push @created, $event },
    on_moved_from => sub ($event) { push @moved_from, $event },
    on_moved_to => sub ($event) { push @moved_to, $event },
    on_delete => sub ($event) { push @deleted, $event },
    on_event => sub ($event) { push @all, $event },
);

my $a = File::Spec->catfile($dir, 'a.txt');
open my $fh, '>', $a or die "open $a: $!";
close $fh;
ok(pump_until($loop, sub { @created }),
    'directory watch receives create event');
is($created[0]->name, 'a.txt', 'directory event exposes child name');
is($created[0]->path, $a, 'directory event composes useful child path');
ok(!$created[0]->is_directory, 'regular child is not marked as a directory');

my $subdir = File::Spec->catdir($dir, 'child-dir');
mkdir $subdir or die "mkdir $subdir: $!";
ok(pump_until($loop, sub {
    scalar grep { defined($_->name) && $_->name eq 'child-dir' } @created
}), 'directory creation is delivered');
my ($dir_event) = grep {
    defined($_->name) && $_->name eq 'child-dir'
} @created;
ok($dir_event->is_directory, 'IN_ISDIR is exposed as event metadata');

my $b = File::Spec->catfile($dir, 'b.txt');
rename $a, $b or die "rename $a -> $b: $!";
ok(pump_until($loop, sub { @moved_from && @moved_to }),
    'rename produces moved-from and moved-to events');
is($moved_from[0]->name, 'a.txt', 'moved-from reports old name');
is($moved_to[0]->name, 'b.txt', 'moved-to reports new name');
ok($moved_from[0]->cookie, 'rename event exposes nonzero cookie');
is($moved_from[0]->cookie, $moved_to[0]->cookie,
    'rename pair preserves matching kernel cookie');

unlink $b or die "unlink $b: $!";
ok(pump_until($loop, sub { @deleted }), 'directory watch receives delete event');
is($deleted[0]->path, $b, 'delete event reports deleted child path');
ok(@all >= @created + @moved_from + @moved_to + @deleted,
    'on_event observes delivered requested records');

my $generic_path = File::Spec->catfile($dir, 'generic.txt');
open my $generic_seed, '>', $generic_path or die "open $generic_path: $!";
close $generic_seed;
$loop->run_once(0);

my @generic;
my $generic = $inotify->watch(
    $generic_path,
    on_event => sub ($event) { push @generic, $event },
);
open my $generic_out, '>>', $generic_path or die "open $generic_path: $!";
print {$generic_out} "x\n";
close $generic_out;
ok(pump_until($loop, sub { @generic }),
    'on_event by itself requests ordinary inotify events');
is($generic[0]->watch, $generic, 'event retains its logical Watch');

my @order;
my $ordered_path = File::Spec->catfile($dir, 'ordered.txt');
open my $ordered_seed, '>', $ordered_path or die "open $ordered_path: $!";
close $ordered_seed;

my %ordered_callback = map {
    my $name = $_;
    $name => sub ($event) { push @order, $name };
} qw(
    on_create on_open on_access on_modify on_attrib on_close_write
    on_close_nowrite on_moved_from on_moved_to on_move_self on_delete
    on_delete_self on_unmount on_ignored
);
$ordered_callback{on_event} = sub ($event) { push @order, 'on_event' };

my $ordered = $inotify->watch($ordered_path, %ordered_callback);
my $combined =
      Linux::Event::Kernel::Inotify::IN_CREATE()
    | Linux::Event::Kernel::Inotify::IN_OPEN()
    | Linux::Event::Kernel::Inotify::IN_ACCESS()
    | Linux::Event::Kernel::Inotify::IN_MODIFY()
    | Linux::Event::Kernel::Inotify::IN_ATTRIB()
    | Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE()
    | Linux::Event::Kernel::Inotify::IN_CLOSE_NOWRITE()
    | Linux::Event::Kernel::Inotify::IN_MOVED_FROM()
    | Linux::Event::Kernel::Inotify::IN_MOVED_TO()
    | Linux::Event::Kernel::Inotify::IN_MOVE_SELF()
    | Linux::Event::Kernel::Inotify::IN_DELETE()
    | Linux::Event::Kernel::Inotify::IN_DELETE_SELF()
    | Linux::Event::Kernel::Inotify::IN_UNMOUNT()
    | Linux::Event::Kernel::Inotify::IN_IGNORED();

$inotify->_dispatch_record([$ordered->_wd, $combined, 17, undef]);
is_deeply(
    \@order,
    [qw(
        on_create on_open on_access on_modify on_attrib on_close_write
        on_close_nowrite on_moved_from on_moved_to on_move_self on_delete
        on_delete_self on_unmount on_ignored on_event
    )],
    'specific callbacks use documented deterministic order and on_event is last',
);
is($ordered->state, 'ignored', 'IN_IGNORED terminates an active Watch after callbacks');

my $throw_path = File::Spec->catfile($dir, 'throw.txt');
open my $throw_seed, '>', $throw_path or die "open $throw_path: $!";
close $throw_seed;
my @throw_order;
my $throw_watch = $inotify->watch(
    $throw_path,
    on_modify => sub ($event) {
        push @throw_order, 'modify';
        die "expected callback failure\n";
    },
    on_close_write => sub ($event) { push @throw_order, 'close_write' },
    on_event => sub ($event) { push @throw_order, 'event' },
);
my $throw_error = eval {
    $inotify->_dispatch_record([
        $throw_watch->_wd,
        Linux::Event::Kernel::Inotify::IN_MODIFY()
            | Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE(),
        0,
        undef,
    ]);
    '';
};
$throw_error = $@ if !defined($throw_error) || $throw_error eq '';
like($throw_error, qr/expected callback failure/,
    'specific callback exception propagates');
is_deeply(\@throw_order, ['modify'],
    'first exception suppresses later specific callback and on_event');

my $cancel_path = File::Spec->catfile($dir, 'cancel.txt');
open my $cancel_seed, '>', $cancel_path or die "open $cancel_path: $!";
close $cancel_seed;
my @cancel_order;
my $cancel_watch = $inotify->watch(
    $cancel_path,
    on_modify => sub ($event) {
        push @cancel_order, 'modify';
        $event->watch->cancel;
    },
    on_close_write => sub ($event) { push @cancel_order, 'close_write' },
    on_event => sub ($event) { push @cancel_order, 'event' },
);
$inotify->_dispatch_record([
    $cancel_watch->_wd,
    Linux::Event::Kernel::Inotify::IN_MODIFY()
        | Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE(),
    0,
    undef,
]);
is_deeply(\@cancel_order, ['modify'],
    'self-cancellation suppresses later callbacks for the same record');
is($cancel_watch->state, 'cancelled', 'self-cancellation is terminal');

my $invalid_path = File::Spec->catfile($dir, 'invalidated.txt');
open my $invalid_seed, '>', $invalid_path or die "open $invalid_path: $!";
close $invalid_seed;
my @invalid;
my $invalid = $inotify->watch(
    $invalid_path,
    on_delete_self => sub ($event) { push @invalid, 'delete_self' },
    on_ignored => sub ($event) { push @invalid, 'ignored' },
    on_event => sub ($event) { push @invalid, 'event' },
);
unlink $invalid_path or die "unlink $invalid_path: $!";
ok(pump_until($loop, sub { $invalid->is_terminal }),
    'kernel invalidation eventually terminates active Watch');
is($invalid->state, 'ignored', 'kernel invalidation records ignored state');
ok((grep { $_ eq 'ignored' } @invalid),
    'kernel invalidation delivers on_ignored while Watch is active');

my $sibling_path = File::Spec->catfile($dir, 'siblings.txt');
open my $sibling_seed, '>', $sibling_path or die "open $sibling_path: $!";
close $sibling_seed;
my @sibling_order;
my ($first_sibling, $second_sibling);
$first_sibling = $inotify->watch(
    $sibling_path,
    on_modify => sub ($event) {
        push @sibling_order, 'first';
        $second_sibling->cancel;
    },
);
$second_sibling = $inotify->watch(
    $sibling_path,
    on_modify => sub ($event) {
        push @sibling_order, 'second';
    },
);
$inotify->_dispatch_record([
    $first_sibling->_wd,
    Linux::Event::Kernel::Inotify::IN_MODIFY(),
    0,
    undef,
]);
is_deeply(\@sibling_order, ['first'],
    'cancelling a sibling during fan-out suppresses its callback');
$first_sibling->cancel;

my $close_loop = Linux::Event::Loop->new;
my $close_parent = Linux::Event::Kernel::Inotify->new(loop => $close_loop);
my $close_path = File::Spec->catfile($dir, 'close-parent.txt');
open my $close_seed, '>', $close_path or die "open $close_path: $!";
close $close_seed;
my @close_order;
my $close_watch = $close_parent->watch(
    $close_path,
    on_modify => sub ($event) {
        push @close_order, 'modify';
        $close_parent->close;
    },
    on_close_write => sub ($event) { push @close_order, 'close_write' },
    on_event => sub ($event) { push @close_order, 'event' },
);
$close_parent->_dispatch_record([
    $close_watch->_wd,
    Linux::Event::Kernel::Inotify::IN_MODIFY()
        | Linux::Event::Kernel::Inotify::IN_CLOSE_WRITE(),
    0,
    undef,
]);
is_deeply(\@close_order, ['modify'],
    'closing parent during callback suppresses later callbacks safely');
ok($close_parent->is_terminal, 'reentrant parent close is terminal');
ok($close_watch->is_terminal, 'reentrant parent close terminates child Watch');

my $overflow = 0;
my $overflow_parent = Linux::Event::Kernel::Inotify->new(
    loop => $loop,
    on_overflow => sub ($parent) { $overflow++ },
);
$overflow_parent->_dispatch_record([
    -1,
    Linux::Event::Kernel::Inotify::IN_Q_OVERFLOW(),
    0,
    undef,
]);
is($overflow, 1, 'queue overflow is delivered at parent level');
$overflow_parent->close;

my @source_error;
my $error_parent = Linux::Event::Kernel::Inotify->new(
    loop => $loop,
    on_error => sub ($parent, $error) {
        push @source_error, $error;
    },
);
$error_parent->_runtime_fail("expected inotify source failure\n");
is(scalar(@source_error), 1, 'fatal source failure invokes parent on_error once');
like($source_error[0], qr/expected inotify source failure/,
    'parent on_error receives the source failure');
ok($error_parent->is_terminal, 'fatal source failure closes parent after on_error');

$inotify->close;
done_testing;
