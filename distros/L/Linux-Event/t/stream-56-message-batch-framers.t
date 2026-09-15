use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::BatchFramer::Fixed;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 2;
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}
{
    package T::BatchFramer::Length;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'LengthPrefix', bytes => 1;
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}
{
    package T::BatchFramer::U32BE;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'U32BE';
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}
{
    package T::BatchFramer::Netstring;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Netstring';
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}
{
    package T::BatchFramer::Varint;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Varint';
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}
{
    package T::BatchFramer::Decimal;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength', separator => ' ';
    sub stream_tuning ($class) { return message_batch_size => 4 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}

sub run_case ($class, $wire) {
    socketpair(my $stream_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { batches => [] };
    my $stream = $class->new(
        loop => $loop, fh => $stream_fh, data => $state,
    );
    syswrite($peer_fh, $wire) == length($wire)
        or die "short fixture write: $!";
    $loop->run_once(100);
    my $stats = $stream->{xs_state}->stats;
    $stream->close;
    close $peer_fh;
    return ($state->{batches}, $stats);
}

my @cases = (
    ['Fixed', 'T::BatchFramer::Fixed', 'aabbccddee'],
    ['LengthPrefix', 'T::BatchFramer::Length',
        join('', map { "\x02$_" } qw(aa bb cc dd ee))],
    ['U32BE', 'T::BatchFramer::U32BE',
        join('', map { pack('N', 2) . $_ } qw(aa bb cc dd ee))],
    ['Netstring', 'T::BatchFramer::Netstring',
        join('', map { "2:$_," } qw(aa bb cc dd ee))],
    ['Varint', 'T::BatchFramer::Varint',
        join('', map { "\x02$_" } qw(aa bb cc dd ee))],
    ['DecimalLength', 'T::BatchFramer::Decimal',
        join('', map { "2 $_" } qw(aa bb cc dd ee))],
);

for my $case (@cases) {
    my ($name, $class, $wire) = @$case;
    subtest $name => sub {
        my ($batches, $stats) = run_case($class, $wire);
        is_deeply($batches, [[qw(aa bb cc dd)], ['ee']],
            "$name preserves frames across full and partial batches");
        is($stats->{frames_emitted}, 5, "$name counts semantic frames");
        is($stats->{message_batch_calls}, 2, "$name enters Perl twice");
        is($stats->{message_batch_peak_messages}, 4,
            "$name reaches configured batch limit");
    };
}

done_testing;
