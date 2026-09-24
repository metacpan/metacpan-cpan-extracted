use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Dgram;

{
    package T::IntrospectionTimer;
    use parent 'Linux::Event::Kernel::Timer';
    sub on_timer ($timer) {
        my $state = $timer->data;
        $state->{running_in_callback} = $timer->loop->running;
        $state->{present_in_callback} = $timer->loop->has($timer);
        $timer->loop->stop;
    }
}

my $loop = Linux::Event::Loop->new;
can_ok($loop, qw(running count has objects inspect census resources
    why_alive pressure profile stats reset_stats));
ok(!$loop->running, 'new Loop is not running');
is($loop->count, 0, 'new Loop has no managed objects');
ok(!defined $loop->resources->{timer_fd},
    'unused Timer resource is initially undef');

my $detached = T::IntrospectionTimer->new(after => 60);
is_deeply(
    $loop->inspect($detached),
    {
        type       => 'timer',
        class      => 'T::IntrospectionTimer',
        registered => 0,
    },
    'inspect identifies a supported object that is not in this Loop',
);

my $state = {};
my $timer = $loop->add(T::IntrospectionTimer->new(
    after => 0, data => $state,
));
ok($loop->has($timer), 'has recognizes the exact attached object');
ok(!$loop->has($detached), 'has rejects a detached object');
my $other_loop = Linux::Event::Loop->new;
ok(!$other_loop->has($timer), 'has rejects an object owned by another Loop');
is($other_loop->inspect($timer)->{registered}, 0,
    'inspect does not expose another Loop ownership as registration');
is($loop->count, 1, 'count includes one managed public object');

my $objects = $loop->objects;
is(ref($objects), 'ARRAY', 'objects returns an array reference');
is(scalar @$objects, 1, 'objects has one entry');
is(refaddr($objects->[0]), refaddr($timer), 'objects returns the exact object');

is_deeply(
    $loop->census,
    {
        pipe => 0, tty => 0, stream => 0, listener => 0, dgram => 0,
        timer => 1, signal => 0, event => 0, inotify => 0, process => 0,
    },
    'census includes stable public zero-valued type keys',
);

my $inspection = $loop->inspect($timer);
is($inspection->{type}, 'timer', 'Timer inspection has canonical type');
is($inspection->{class}, 'T::IntrospectionTimer', 'inspection has class');
is($inspection->{registered}, 1, 'inspection reports registration');
is($inspection->{state}, 'active', 'inspection has current state');
ok(exists $inspection->{deadline}, 'Timer inspection has deadline');
is($inspection->{interval}, 0, 'Timer inspection has interval');
is($inspection->{expirations}, 0, 'Timer inspection has expirations');

# Private helper used only to verify that backing timers are not public objects.
my $internal = Linux::Event::_Socket::Dgram::_ReadyTimer->new(after => 60);
$loop->add($internal);
is($loop->count, 1, 'internal Timer is excluded from managed objects');

pipe(my $reader, my $writer) or die "pipe: $!";
my $registration = $loop->watch(
    fh => $reader, read => sub ($watcher) { $watcher->cancel },
);
my $resources = $loop->resources;
ok($resources->{epoll_fd} >= 0, 'resources exposes epoll fd');
ok(defined $resources->{timer_fd}, 'resources exposes active timerfd');
cmp_ok($resources->{registered_fds}, '>=', 2,
    'resources counts native registrations');
is($resources->{public_registrations}, 1,
    'resources separates user-created raw registrations');
ok(grep($_ == fileno($reader), @{ $resources->{public_registration_fds} }),
    'resources identifies the public registration fd');

my $reasons = $loop->why_alive;
ok(grep($_->{type} eq 'timer' && $_->{object} == $timer, @$reasons),
    'why_alive reports a managed object');
ok(grep($_->{type} eq 'registration' && $_->{fd} == fileno($reader), @$reasons),
    'why_alive reports a user-created raw registration');

my $pressure = $loop->pressure;
is($pressure->{registrations}{active}, $resources->{registered_fds},
    'pressure uses the native registration count');
is($pressure->{timers}{active}, 2,
    'pressure includes public and internal active timers');
ok(!defined $pressure->{event_batch}{maximum},
    'event batch pressure is unknown before the Loop has run');

my $before = $loop->stats->{epoll_ctl_add_calls};
is(refaddr($loop->profile(1)), refaddr($loop), 'profile returns the Loop');
is($loop->stats->{profile_enabled}, 1, 'profile enables timing');
is($loop->stats->{epoll_ctl_add_calls}, $before,
    'profile does not reset accumulated statistics');
$loop->profile(0);
is($loop->stats->{profile_enabled}, 0, 'profile disables timing');

$internal->cancel;
$registration->cancel;
close $reader;
close $writer;

$loop->run;
ok($state->{running_in_callback}, 'running is true from inside run callback');
ok($state->{present_in_callback},
    'firing one-shot Timer remains introspectable during its callback');
ok(!$loop->running, 'running is false after run returns');
ok(!$loop->has($timer), 'expired Timer is no longer present');
is($loop->count, 0, 'terminal objects are pruned by query');

$loop->reset_stats;
is($loop->stats->{epoll_wait_calls}, 0, 'reset_stats clears counters');
is($loop->stats->{profile_enabled}, 0,
    'reset_stats preserves disabled profile state');

done_testing;
