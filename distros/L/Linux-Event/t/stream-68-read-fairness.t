use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::DefaultReadFairness;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_data ($stream, $bytes) {
        $stream->data->{bytes} += length $bytes;
    }
}

{
    package T::UnlimitedReadFairness;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub stream_tuning ($class) {
        return read_budget_bytes => 0;
    }

    sub on_data ($stream, $bytes) {
        $stream->data->{bytes} += length $bytes;
    }
}

sub preloaded_pair ($class, $payload_bytes) {
    socketpair(my $stream_fh, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";

    my $payload = 'x' x $payload_bytes;
    my $written = syswrite($peer, $payload);
    die "preload short write: " . (defined($written) ? $written : $!)
        if !defined($written) || $written != length($payload);

    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => 0 };
    my $stream = $class->new(
        loop => $loop,
        fh   => $stream_fh,
        data => $state,
    );
    return ($loop, $stream, $peer, $state);
}

my $payload_bytes = 96 * 1024;

{
    my ($loop, $stream, $peer, $state)
        = preloaded_pair('T::DefaultReadFairness', $payload_bytes);

    $loop->run_once(100);

    is($stream->{xs_state}->stats->{bytes_read}, 65_536,
        'default ordered-byte readiness turn stops at the 64 KiB read budget');
    is($state->{bytes}, 65_536,
        'default raw callback receives only the bounded first-turn input');

    $loop->run_once(100);
    is($stream->{xs_state}->stats->{bytes_read}, $payload_bytes,
        'later Loop turn continues reading data left ready by the fairness bound');
    is($state->{bytes}, $payload_bytes,
        'bounded default loses no queued input');

    $stream->close;
    close $peer;
}

{
    my ($loop, $stream, $peer, $state)
        = preloaded_pair('T::UnlimitedReadFairness', $payload_bytes);

    $loop->run_once(100);

    is($stream->{xs_state}->stats->{bytes_read}, $payload_bytes,
        'explicit zero read budget retains drain-until-EAGAIN behavior');
    is($state->{bytes}, $payload_bytes,
        'explicit unlimited mode drains all preloaded input in one Loop turn');

    $stream->close;
    close $peer;
}

done_testing;
