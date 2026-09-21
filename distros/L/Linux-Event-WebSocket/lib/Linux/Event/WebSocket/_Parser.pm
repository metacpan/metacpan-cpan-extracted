package Linux::Event::WebSocket::_Parser;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use utf8 ();

use Linux::Event::WebSocket::_Frame;

sub new ($class, %option) {
    my $endpoint_type = delete $option{endpoint_type};
    croak 'new(): endpoint_type must be client or server'
        if !defined($endpoint_type)
        || ($endpoint_type ne 'client' && $endpoint_type ne 'server');

    my $max_frame_size = delete $option{max_frame_size};
    croak 'new(): max_frame_size must be a positive integer'
        if !defined($max_frame_size) || ref($max_frame_size)
        || "$max_frame_size" !~ /\A[0-9]+\z/ || $max_frame_size < 1;
    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    return bless {
        endpoint_type  => $endpoint_type,
        max_frame_size => 0 + $max_frame_size,
        input          => '',
    }, $class;
}

sub feed ($self, $bytes) {
    croak 'feed(): bytes must be a defined scalar'
        if !defined($bytes) || ref($bytes);

    if (utf8::is_utf8($bytes)) {
        my $copy = "$bytes";
        croak 'feed(): input must contain bytes'
            if !utf8::downgrade($copy, 1);
        $self->{input} .= $copy;
    } else {
        $self->{input} .= $bytes;
    }
    return $self;
}

sub buffered_bytes ($self) {
    return length $self->{input};
}

sub _check_size ($self, $high, $low) {
    my $max = $self->{max_frame_size};
    if (!$high) {
        die "WebSocket frame payload exceeds configured limit\n"
            if $low > $max;
        return $low;
    }

    my $max_high = int($max / 4_294_967_296);
    my $max_low = $max % 4_294_967_296;
    if ($high > $max_high || ($high == $max_high && $low > $max_low)) {
        die "WebSocket frame payload exceeds configured limit\n";
    }
    return $high * 4_294_967_296 + $low;
}

sub next_frame ($self) {
    return undef if length($self->{input}) < 2;

    my ($first, $second) = unpack(
        'CC',
        substr($self->{input}, 0, 2),
    );
    my $fin = $first & 0x80 ? 1 : 0;
    my $rsv = $first & 0x70;
    my $opcode = $first & 0x0f;
    my $masked = $second & 0x80 ? 1 : 0;
    my $length_code = $second & 0x7f;

    die "WebSocket frame uses reserved bits without a negotiated extension\n"
        if $rsv;
    my $type = Linux::Event::WebSocket::_Frame->type($opcode);
    die "WebSocket frame uses an unknown opcode $opcode\n"
        if !defined $type;
    die "WebSocket client frame is not masked\n"
        if $self->{endpoint_type} eq 'server' && !$masked;
    die "WebSocket server frame is masked\n"
        if $self->{endpoint_type} eq 'client' && $masked;

    my $control = $opcode >= 8;
    die "WebSocket control frame is fragmented\n" if $control && !$fin;
    die "WebSocket control frame payload exceeds 125 bytes\n"
        if $control && $length_code > 125;

    my $cursor = 2;
    my $length;
    if ($length_code < 126) {
        $length = $length_code;
        die "WebSocket frame payload exceeds configured limit\n"
            if $length > $self->{max_frame_size};
    } elsif ($length_code == 126) {
        return undef if length($self->{input}) < $cursor + 2;
        $length = unpack('n', substr($self->{input}, $cursor, 2));
        $cursor += 2;
        die "WebSocket frame uses a non-minimal 16-bit payload length\n"
            if $length < 126;
        die "WebSocket frame payload exceeds configured limit\n"
            if $length > $self->{max_frame_size};
    } else {
        return undef if length($self->{input}) < $cursor + 8;
        my ($high, $low) = unpack('NN', substr($self->{input}, $cursor, 8));
        $cursor += 8;
        die "WebSocket frame 64-bit payload length has its most significant bit set\n"
            if $high & 0x80000000;
        die "WebSocket frame uses a non-minimal 64-bit payload length\n"
            if $high == 0 && $low < 65_536;
        $length = $self->_check_size($high, $low);
    }

    my $mask = '';
    if ($masked) {
        return undef if length($self->{input}) < $cursor + 4;
        $mask = substr($self->{input}, $cursor, 4);
        $cursor += 4;
    }

    return undef if length($self->{input}) < $cursor + $length;
    my $payload = substr($self->{input}, $cursor, $length);
    $payload = Linux::Event::WebSocket::_Frame->mask($payload, $mask)
        if $masked;

    substr($self->{input}, 0, $cursor + $length, '');
    return {
        fin     => $fin,
        opcode  => $opcode,
        type    => $type,
        payload => $payload,
    };
}

1;
