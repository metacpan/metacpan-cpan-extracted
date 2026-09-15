use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

sub exception ($code) {
    local $@;
    eval { $code->(); 1 };
    return $@;
}

like(exception(sub { Linux::Event::_ByteStream::Descriptor::Native->new([]) }),
    qr/requires a hash reference/,
    'native descriptor requires a named hash specification');
like(exception(sub {
    Linux::Event::_ByteStream::Descriptor::Native->new({ unexpected => 1 });
}), qr/unknown ordered-byte descriptor field 'unexpected'/,
    'native descriptor rejects unknown specification fields');
like(exception(sub { Linux::Event::_ByteStream::Descriptor::Native->new({}) }),
    qr/missing ordered-byte descriptor field 'read_size'/,
    'native descriptor rejects missing specification fields');
like(exception(sub {
    Linux::Event::_ByteStream::Descriptor::Native->_new_validated({});
}), qr/requires a complete validated specification/,
    'native constructor retains a defensive completeness backstop');

my %unnormalized_spec = (
    (map { $_ => undef } qw(
        deliver_cb message_cb message_batch_cb drain_cb eof_cb read_error_cb
        write_error_cb output_limit_cb write_empty_cb framing_error_cb
        delimiter max_frame consumer_provider
    )),
    read_size => '4096',
    read_budget_bytes => undef,
    read_batch_bytes => '0',
    message_batch_size => '0',
    high_watermark => '8192',
    low_watermark => '2048',
    max_pending_bytes => '0',
    max_buffer => '16384',
    read_mode => '0',
    include_delimiter => 7,
    fixed_size => undef,
    prefix_bytes => undef,
    prefix_little => '',
    include_prefix => 'yes',
    consumer_abi_version => undef,
    consumer_ops_address => undef,
);
my $normalized_spec
    = Linux::Event::_ByteStream::Descriptor::_validate_native_spec(
        \%unnormalized_spec,
    );
is($normalized_spec->{read_size}, 4096,
    'Perl descriptor boundary normalizes numeric fields');
is($normalized_spec->{read_budget_bytes}, 0,
    'Perl descriptor boundary normalizes absent numeric values');
is($normalized_spec->{include_delimiter}, 1,
    'Perl descriptor boundary normalizes true flags');
is($normalized_spec->{prefix_little}, 0,
    'Perl descriptor boundary normalizes false flags');
is($unnormalized_spec{include_delimiter}, 7,
    'descriptor normalization does not mutate its caller');

{
    package T::SharedLineStream;
    use parent 'Linux::Event::_ByteStream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub stream_tuning ($class) { return read_size => 2 }
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        $state->{got} = $message;
    }
}

socketpair(my $sa, my $ca, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
socketpair(my $sb, my $cb, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state_a = { got => undef };
my $state_b = { got => undef };

my $a = T::SharedLineStream->new(loop => $loop, fh => $sa, data => $state_a);
my $b = T::SharedLineStream->new(loop => $loop, fh => $sb, data => $state_b);

is(refaddr($a->{descriptor}), refaddr($b->{descriptor}),
    'same subclass shares one Perl descriptor');
is(refaddr($a->{descriptor}{native}), refaddr($b->{descriptor}{native}),
    'same subclass shares one XS descriptor');
isnt(refaddr($a->{xs_state}), refaddr($b->{xs_state}),
    'connections retain independent mutable XS state');
is(refaddr($a->{descriptor}{callbacks}{on_message}),
    refaddr(\&T::SharedLineStream::on_message),
    'descriptor caches the named callback CV');

syswrite($ca, 'hel');
syswrite($cb, "world\n");
$loop->run_for(0.01);
is($state_a->{got}, undef, 'partial connection A frame remains buffered');
is($state_b->{got}, 'world', 'connection B parses independently');
syswrite($ca, "lo\n");
$loop->run_for(0.01);
is($state_a->{got}, 'hello', 'connection A completes its own parser state');

$a->close;
$b->close;
close $ca;
close $cb;
done_testing;
