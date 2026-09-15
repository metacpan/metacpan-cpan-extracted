use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

{
    package T::OptionsHash;
    use parent 'Linux::Event::IO::Sock::Stream';
    our $CALLS = 0;
    sub stream_tuning ($class) {
        $CALLS++;
        return {
            read_size => 8, high_watermark => 1234,
            low_watermark => 123, max_buffer => 4096,
        };
    }
    sub on_data ($stream, $bytes) { }
}

{
    package T::OptionsOdd;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return 'read_size' }
    sub on_data ($stream, $bytes) { }
}

{
    package T::OptionsUnknown;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return imaginary => 1 }
    sub on_data ($stream, $bytes) { }
}

{
    package T::OptionsWatermark;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 1, low_watermark => 2;
    }
    sub on_data ($stream, $bytes) { }
}

{
    package T::OptionsZeroRead;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 0 }
    sub on_data ($stream, $bytes) { }
}

{
    package T::OptionsNegativeBudget;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_budget_bytes => -1 }
    sub on_data ($stream, $bytes) { }
}

my $loop = Linux::Event::Loop->new;
socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $first = T::OptionsHash->new(loop => $loop, fh => $a);
my $second = T::OptionsHash->new(loop => $loop, fh => $c);

is($T::OptionsHash::CALLS, 1, 'stream_tuning runs once per Stream subclass');
is(refaddr($first->{descriptor}), refaddr($second->{descriptor}),
    'instances reuse the cached class descriptor');
is_deeply(
    $first->{descriptor}{options},
    {
        read_size => 8, high_watermark => 1234,
        low_watermark => 123, max_pending_bytes => 0, max_buffer => 4096,
        read_budget_bytes => 0, read_batch_bytes => 0,
        message_batch_size => 0,
        idle_timeout => 0, read_timeout => 0, write_timeout => 0,
    },
    'hashref class options are validated and cached',
);
$first->close;
$second->close;
close $b;
close $d;

sub descriptor_error ($class) {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    eval { $class->new(loop => $loop, fh => $left) };
    my $error = $@;
    close $left if defined fileno($left);
    close $right;
    return $error;
}

like(descriptor_error('T::OptionsOdd'), qr/odd option list/,
    'odd stream_tuning list is rejected');
like(descriptor_error('T::OptionsUnknown'), qr/unknown options: imaginary/,
    'unknown class option is rejected');
like(descriptor_error('T::OptionsWatermark'), qr/low_watermark must be <=/,
    'invalid watermark relationship is rejected');
like(descriptor_error('T::OptionsZeroRead'), qr/read_size must be a positive/,
    'zero read size is rejected');
like(descriptor_error('T::OptionsNegativeBudget'),
    qr/read_budget_bytes must be a non-negative/,
    'negative read budget is rejected');

done_testing;
