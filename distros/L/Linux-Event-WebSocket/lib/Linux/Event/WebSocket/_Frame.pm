package Linux::Event::WebSocket::_Frame;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use utf8 ();

use Linux::Event::WebSocket::_Random;
use Linux::Event::WebSocket::_UTF8;

my %OPCODE = (
    continuation => 0,
    text         => 1,
    binary       => 2,
    close        => 8,
    ping         => 9,
    pong         => 10,
);
my %TYPE = reverse %OPCODE;

my %CLOSE_CODE = (
    SUCCESS                => 1000,
    ENDPOINT_UNAVAILABLE   => 1001,
    PROTOCOL_ERROR         => 1002,
    INVALID_DATA_TYPE      => 1003,
    INVALID_PAYLOAD        => 1007,
    POLICY_VIOLATION       => 1008,
    MESSAGE_TOO_BIG        => 1009,
    UNSUPPORTED_EXTENSIONS => 1010,
    INTERNAL_ERROR         => 1011,
    SERVER_ERROR           => 1011,
    SERVICE_RESTART        => 1012,
    TRY_AGAIN_LATER        => 1013,
    BAD_GATEWAY            => 1014,
);

sub type ($class, $opcode) {
    return $TYPE{$opcode};
}

sub opcode ($class, $type) {
    return $OPCODE{$type};
}

sub mask ($class, $payload, $key) {
    croak 'mask(): key must contain exactly four bytes'
        if !defined($key) || ref($key) || length($key) != 4;
    return '' if !length $payload;
    my $mask = $key x (int(length($payload) / 4) + 1);
    substr($mask, length($payload)) = '';
    return $payload ^. $mask;
}

sub _mask_data ($payload, $key) {
    return '' if !length $payload;
    my $mask = $key x (int(length($payload) / 4) + 1);
    substr($mask, length($payload)) = '';
    return $payload ^. $mask;
}

sub encode_data ($class, $opcode, $bytes, $masked) {
    my $length = length $bytes;
    my $mask_bit = $masked ? 0x80 : 0;
    my $header;

    if ($length < 126) {
        $header = pack('CC', 0x80 | $opcode, $mask_bit | $length);
    } elsif ($length < 65_536) {
        $header = pack('CCn', 0x80 | $opcode, $mask_bit | 126, $length);
    } else {
        my $high = int($length / 4_294_967_296);
        my $low = $length % 4_294_967_296;
        $header = pack(
            'CCNN',
            0x80 | $opcode,
            $mask_bit | 127,
            $high,
            $low,
        );
    }

    return $header . $bytes if !$masked;

    my $mask = Linux::Event::WebSocket::_Random->mask_key;
    return $header . $mask . _mask_data($bytes, $mask);
}

sub encode ($class, $type, $payload, %option) {
    croak "encode(): unknown frame type '$type'"
        if !defined($type) || ref($type) || !exists $OPCODE{$type};
    croak 'encode(): payload must be a defined scalar'
        if !defined($payload) || ref($payload);

    my $bytes = "$payload";
    croak 'encode(): payload must contain bytes'
        if !utf8::downgrade($bytes, 1);

    my $fin = exists($option{fin}) ? delete($option{fin}) : 1;
    my $masked = delete($option{masked}) ? 1 : 0;
    my $mask_key = delete $option{mask_key};
    croak 'encode(): mask_key requires masked output'
        if defined($mask_key) && !$masked;
    croak 'encode(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    my $opcode = $OPCODE{$type};
    my $control = $opcode >= 8;
    croak 'encode(): control frames must be final' if $control && !$fin;
    croak 'encode(): control frame payload exceeds 125 bytes'
        if $control && length($bytes) > 125;

    my $length = length $bytes;
    my ($length_code, $extended);
    if ($length < 126) {
        $length_code = $length;
        $extended = '';
    } elsif ($length < 65_536) {
        $length_code = 126;
        $extended = pack('n', $length);
    } else {
        $length_code = 127;
        my $high = int($length / 4_294_967_296);
        my $low = $length % 4_294_967_296;
        $extended = pack('NN', $high, $low);
    }

    my $first = $opcode | ($fin ? 0x80 : 0);
    my $second = $length_code | ($masked ? 0x80 : 0);
    my $mask = '';
    if ($masked) {
        $mask = defined($mask_key)
            ? "$mask_key"
            : Linux::Event::WebSocket::_Random->bytes(4);
        croak 'encode(): mask_key must contain exactly four bytes'
            if length($mask) != 4;
        $bytes = $class->mask($bytes, $mask);
    }

    return chr($first) . chr($second) . $extended . $mask . $bytes;
}

sub valid_close_code ($class, $code) {
    return 1 if grep { $_ == $code } values %CLOSE_CODE;
    return $code >= 3000 && $code < 5000;
}

sub close_code ($class, $value) {
    croak 'close code is required' if !defined($value) || ref($value);
    return $CLOSE_CODE{$value} if exists $CLOSE_CODE{$value};
    croak "invalid WebSocket close code '$value'"
        if "$value" !~ /\A[0-9]+\z/ || !$class->valid_close_code(0 + $value);
    return 0 + $value;
}

sub close_payload ($class, $code, $reason = '') {
    croak 'close reason must be a defined scalar'
        if !defined($reason) || ref($reason);
    croak 'close reason requires a close code'
        if !defined($code) && length($reason);
    return '' if !defined $code;

    my $number = $class->close_code($code);
    my $bytes = "$reason";
    croak 'close reason must contain UTF-8 bytes'
        if !utf8::downgrade($bytes, 1);
    croak 'close reason exceeds 123 bytes' if length($bytes) > 123;
    eval { Linux::Event::WebSocket::_UTF8->validate_bytes($bytes); 1 }
        or croak 'close reason contains invalid UTF-8';
    return pack('n', $number) . $bytes;
}

sub parse_close_payload ($class, $payload) {
    my $length = length $payload;
    die "WebSocket close frame has a one-byte payload\n" if $length == 1;
    return (undef, '') if !$length;

    my ($code, $reason) = unpack('na*', $payload);
    die "WebSocket close frame contains invalid status code $code\n"
        if !$class->valid_close_code($code);
    eval { Linux::Event::WebSocket::_UTF8->validate_bytes($reason); 1 }
        or die "WebSocket close frame contains invalid UTF-8 reason\n";
    return ($code, $reason);
}

1;
