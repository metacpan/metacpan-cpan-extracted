use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::DeadlineDefaults;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub stream_tuning ($class) {
        return (
            idle_timeout  => 30,
            read_timeout  => 20,
            write_timeout => 10,
        );
    }

    sub on_data ($stream, $bytes) { return }
}

{
    package T::DeadlineInvalid;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return (idle_timeout => -1) }
    sub on_data ($stream, $bytes) { return }
}

{
    package T::DeadlineTransition;
    use parent -norequire, 'T::DeadlineDefaults';
    sub stream_tuning ($class) {
        return (
            idle_timeout  => 4,
            read_timeout  => 3,
            write_timeout => 2,
        );
    }
}

sub pair () {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, 0)
        or die "socketpair: $!";
    return ($left, $right);
}

{
    my ($left, $right) = pair();
    my $stream = T::DeadlineDefaults->new(fh => $left);
    is $stream->idle_timeout, 30, 'idle timeout comes from subclass defaults';
    is $stream->read_timeout, 20, 'read timeout comes from subclass defaults';
    is $stream->write_timeout, 10,
        'write timeout comes from subclass defaults';
    is $stream->deadline, undef, 'no explicit operation deadline by default';
    is $stream->deadline_operation, undef,
        'no explicit operation name by default';
    $stream->close;
    close $right;
}

{
    my $stream = T::DeadlineDefaults->connect(
        host => '127.0.0.1', port => 9,
        idle_timeout => 6, read_timeout => 5, write_timeout => 4,
        deadline => { after => 3, operation => 'connect-result' },
    );
    is $stream->state, 'unattached', 'connect Stream remains detached';
    is $stream->idle_timeout, 6, 'connect passes idle constructor override';
    is $stream->read_timeout, 5, 'connect passes read constructor override';
    is $stream->write_timeout, 4,
        'connect passes write constructor override';
    is $stream->deadline_operation, 'connect-result',
        'connect passes initial operation deadline';
    $stream->close;
}

{
    my ($left, $right) = pair();
    my $loop = Linux::Event::Loop->new;
    my $stream = $loop->add(T::DeadlineDefaults->new(
        fh => $left, idle_timeout => 0,
    ));
    $stream->transition_to('T::DeadlineTransition');
    is $stream->idle_timeout, 0,
        'constructor timeout override survives protocol transition';
    is $stream->read_timeout, 3,
        'target subclass supplies non-overridden read policy';
    is $stream->write_timeout, 2,
        'target subclass supplies non-overridden write policy';
    is $stream->{xs_state}->stats->{activity_tracking}, 1,
        'transition enables native tracking for target policy';
    $stream->close;
    close $right;
}

{
    my ($left, $right) = pair();
    my $stream = T::DeadlineDefaults->new(
        fh            => $left,
        idle_timeout  => 0,
        read_timeout  => 2.5,
        write_timeout => 4,
        deadline      => { after => 8, operation => 'session' },
    );
    is $stream->idle_timeout, 0,
        'constructor zero disables a subclass timeout default';
    is $stream->read_timeout, 2.5, 'constructor overrides read timeout';
    is $stream->write_timeout, 4, 'constructor overrides write timeout';
    is $stream->deadline, undef,
        'detached relative operation deadline has no absolute value';
    is $stream->deadline_operation, 'session',
        'detached operation label is available';

    my $loop = Linux::Event::Loop->new;
    $loop->add($stream);
    ok defined($stream->deadline), 'relative deadline becomes absolute at attach';
    cmp_ok $stream->deadline, '>', Linux::Event::Kernel::Timer->now,
        'constructor deadline starts from established attachment';
    $stream->clear_deadline;
    is $stream->deadline, undef, 'clear_deadline removes constructor deadline';
    is $stream->deadline_operation, undef,
        'clear_deadline removes operation label';
    $stream->set_deadline(after => 7, operation => 'response');
    is $stream->deadline_operation, 'response',
        'set_deadline replaces the operation label';
    cmp_ok $stream->deadline, '>', Linux::Event::Kernel::Timer->now,
        'runtime relative deadline becomes absolute immediately';
    $stream->close;
    close $right;
}

for my $case (
    [ idle_timeout => -1, qr/idle_timeout must be a non-negative/ ],
    [ read_timeout => 'x', qr/read_timeout must be a non-negative/ ],
    [ write_timeout => [], qr/write_timeout must be a non-negative/ ],
    [ idle_timeout => 'Inf', qr/idle_timeout must be a non-negative/ ],
    [ read_timeout => 'NaN', qr/read_timeout must be a non-negative/ ],
    [ write_timeout => '99999999999999999999',
        qr/write_timeout exceeds the supported timer range/ ],
) {
    my ($left, $right) = pair();
    my ($name, $value, $pattern) = @$case;
    my $ok = eval {
        T::DeadlineDefaults->new(fh => $left, $name => $value);
        1;
    };
    ok !$ok, "$name validation rejects invalid constructor value";
    like $@, $pattern, "$name validation explains the contract";
    close $left if defined fileno($left);
    close $right;
}

{
    my ($left, $right) = pair();
    my $ok = eval { T::DeadlineInvalid->new(fh => $left); 1 };
    ok !$ok, 'invalid subclass timeout is rejected';
    like $@, qr/idle_timeout must be a non-negative/,
        'subclass timeout validation explains the contract';
    close $left if defined fileno($left);
    close $right;
}

for my $case (
    [ undef, qr/deadline must be a hash reference/ ],
    [ {}, qr/requires exactly one of after or at/ ],
    [ { after => 1, at => 2, operation => 'x' },
        qr/requires exactly one of after or at/ ],
    [ { after => 1 }, qr/operation must be a non-empty string/ ],
    [ { after => -1, operation => 'x' },
        qr/after must be a non-negative/ ],
    [ { after => 1, operation => 'x', extra => 1 },
        qr/unknown deadline options: extra/ ],
    [ { after => '99999999999999999999', operation => 'x' },
        qr/after exceeds the supported timer range/ ],
) {
    my ($left, $right) = pair();
    my ($deadline, $pattern) = @$case;
    my $ok = eval {
        T::DeadlineDefaults->new(fh => $left, deadline => $deadline);
        1;
    };
    ok !$ok, 'invalid constructor deadline is rejected';
    like $@, $pattern, 'constructor deadline validation is specific';
    close $left if defined fileno($left);
    close $right;
}

{
    my ($left, $right) = pair();
    my $stream = T::DeadlineDefaults->new(fh => $left);
    $stream->close;
    my $ok = eval {
        $stream->set_deadline(after => 1, operation => 'closed');
        1;
    };
    ok !$ok, 'closed Stream rejects set_deadline';
    like $@, qr/stream is closed/, 'closed set_deadline error is clear';
    close $right;
}

done_testing;
