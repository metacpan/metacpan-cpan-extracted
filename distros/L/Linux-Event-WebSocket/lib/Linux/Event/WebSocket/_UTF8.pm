package Linux::Event::WebSocket::_UTF8;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use utf8 ();

sub _byte_copy ($bytes) {
    croak 'UTF-8 input must be a defined scalar'
        if !defined($bytes) || ref($bytes);

    my $copy = "$bytes";
    croak 'UTF-8 input must contain bytes'
        if !utf8::downgrade($copy, 1);
    return $copy;
}

sub _decode_copy ($copy) {
    my $byte_length = length $copy;
    my $decoded = $copy;
    croak 'invalid RFC 3629 UTF-8' if !utf8::decode($decoded);

    # A valid UTF-8 byte string can keep the original byte scalar when every
    # code point was ASCII. Comparing decoded character count with input byte
    # count is much cheaper here than scanning the entire payload with a regex.
    return $copy if length($decoded) == $byte_length;

    # Perl accepts surrogate and out-of-range code points in its internal UTF-8
    # representation, while RFC 3629 forbids them.
    croak 'invalid RFC 3629 UTF-8'
        if $decoded =~ /[\x{d800}-\x{dfff}]|[^\x{0}-\x{10ffff}]/;

    return $decoded;
}

sub _decode_bytes ($bytes) {
    return _decode_copy(_byte_copy($bytes));
}

sub validate_bytes ($class, $bytes) {
    _decode_bytes($bytes);
    return 1;
}

sub decode ($class, $bytes) {
    return _decode_bytes($bytes);
}

sub encode ($class, $text) {
    croak 'UTF-8 text must be a defined scalar'
        if !defined($text) || ref($text);

    my $copy = "$text";
    if (!utf8::is_utf8($copy)) {
        _decode_copy($copy);
        return $copy;
    }

    croak 'UTF-8 text contains a non-Unicode scalar value'
        if $copy =~ /[\x{d800}-\x{dfff}]|[^\x{0}-\x{10ffff}]/;

    utf8::encode($copy);
    return $copy;
}

1;
