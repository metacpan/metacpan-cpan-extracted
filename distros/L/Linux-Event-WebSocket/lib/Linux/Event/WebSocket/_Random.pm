package Linux::Event::WebSocket::_Random;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Fcntl qw(FD_CLOEXEC F_GETFD F_SETFD O_RDONLY);

my $RANDOM_FH;

sub _random_fh () {
    return $RANDOM_FH if $RANDOM_FH;

    sysopen($RANDOM_FH, '/dev/urandom', O_RDONLY)
        or die "open /dev/urandom: $!";

    my $flags = fcntl($RANDOM_FH, F_GETFD, 0);
    die "fcntl(F_GETFD) /dev/urandom: $!" if !defined $flags;
    fcntl($RANDOM_FH, F_SETFD, $flags | FD_CLOEXEC)
        or die "fcntl(F_SETFD) /dev/urandom: $!";

    return $RANDOM_FH;
}

sub mask_key ($class) {
    my $fh = $RANDOM_FH // _random_fh();
    my $bytes = '';
    while (length($bytes) < 4) {
        my $read = sysread($fh, $bytes, 4 - length($bytes), length($bytes));
        next if !defined($read) && $!{EINTR};
        die "read /dev/urandom: $!" if !defined $read;
        die "read /dev/urandom: unexpected EOF" if $read == 0;
    }
    return $bytes;
}

sub bytes ($class, $length) {
    croak 'bytes(): length must be a positive integer'
        if !defined($length) || ref($length)
        || "$length" !~ /\A[0-9]+\z/ || $length < 1;

    my $fh = _random_fh();
    my $bytes = '';
    while (length($bytes) < $length) {
        my $read = sysread($fh, $bytes, $length - length($bytes), length($bytes));
        next if !defined($read) && $!{EINTR};
        die "read /dev/urandom: $!" if !defined $read;
        die "read /dev/urandom: unexpected EOF" if $read == 0;
    }

    return $bytes;
}

1;
