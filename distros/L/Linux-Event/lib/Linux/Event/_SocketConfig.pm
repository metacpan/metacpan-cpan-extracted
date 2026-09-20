package Linux::Event::_SocketConfig;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use POSIX qw(ceil isfinite);
use Scalar::Util qw(looks_like_number);
use Socket qw(
    AF_INET AF_INET6
    IPPROTO_TCP SOL_SOCKET
    SO_KEEPALIVE SO_RCVBUF SO_SNDBUF
    TCP_KEEPCNT TCP_KEEPIDLE TCP_KEEPINTVL TCP_NODELAY
);
use Socket ();

use Linux::Event::Error;

use constant _SO_BINDTODEVICE => Socket::SO_BINDTODEVICE();
use constant _TCP_USER_TIMEOUT => Socket::TCP_USER_TIMEOUT();

my %SPEC = (
    tcp_nodelay => {
        level => IPPROTO_TCP, option => TCP_NODELAY, type => 'boolean', tcp => 1,
    },
    keepalive => {
        level => SOL_SOCKET, option => SO_KEEPALIVE, type => 'boolean', tcp => 1,
    },
    keepalive_idle => {
        level => IPPROTO_TCP, option => TCP_KEEPIDLE, type => 'positive', tcp => 1,
    },
    keepalive_interval => {
        level => IPPROTO_TCP, option => TCP_KEEPINTVL, type => 'positive', tcp => 1,
    },
    keepalive_count => {
        level => IPPROTO_TCP, option => TCP_KEEPCNT, type => 'positive', tcp => 1,
    },
    tcp_user_timeout => {
        level => IPPROTO_TCP, option => _TCP_USER_TIMEOUT, type => 'timeout', tcp => 1,
    },
    send_buffer => {
        level => SOL_SOCKET, option => SO_SNDBUF, type => 'positive', tcp => 0,
    },
    receive_buffer => {
        level => SOL_SOCKET, option => SO_RCVBUF, type => 'positive', tcp => 0,
    },
);

sub names () { sort keys %SPEC }
sub is_option ($name) { exists $SPEC{$name} }

sub _target ($method, $name) {
    return "$method(): $name" if $method =~ /\A(?:new|connect)\z/;
    return "$method $name";
}

sub normalize ($method, $name, $value) {
    croak "$method(): unknown socket option: $name" if !exists $SPEC{$name};
    my $type = $SPEC{$name}{type};
    my $target = _target($method, $name);
    if ($type eq 'boolean') {
        croak "$target must be zero or one"
            if !defined($value) || ref($value) || $value !~ /\A[01]\z/;
        return $value ? 1 : 0;
    }
    if ($type eq 'positive') {
        croak "$target must be a positive integer"
            if !defined($value) || ref($value) || $value !~ /\A\d+\z/
            || $value == 0;
        croak "$target must be at most 2147483647"
            if $value > 2_147_483_647;
        return 0 + $value;
    }
    my $seconds = !defined($value) || ref($value) || !looks_like_number($value)
        ? undef : 0 + $value;
    croak "$target must be a non-negative number of seconds"
        if !defined($seconds) || !isfinite($seconds) || $seconds < 0;
    croak "$target exceeds the Linux TCP_USER_TIMEOUT range"
        if $seconds > 4_294_967.295;
    return $seconds;
}

sub normalize_policy ($method, $policy) {
    for my $name (keys %$policy) {
        next if !defined $policy->{$name};
        $policy->{$name} = normalize($method, $name, $policy->{$name});
    }
    return $policy;
}

sub extract ($method, $option) {
    my %socket;
    for my $name (names()) {
        $socket{$name} = delete $option->{$name} if exists $option->{$name};
    }
    return normalize_policy($method, \%socket);
}

sub _is_tcp ($family) { $family == AF_INET || $family == AF_INET6 }

sub _error ($operation, $name, $errno, $message = undef) {
    local $! = $errno;
    return Linux::Event::Error->new(
        type      => 'socket_configuration',
        operation => $operation,
        option    => $name,
        errno     => $errno || undef,
        message   => $message // "$!",
    );
}

sub _packed_value ($spec, $value) {
    if ($spec->{type} eq 'timeout') {
        my $milliseconds = $value == 0 ? 0 : ceil($value * 1000);
        return pack('I', $milliseconds);
    }
    return pack('i', $value);
}

sub set_option ($fh, $family, $name, $value) {
    my $spec = $SPEC{$name} // croak "unknown socket option: $name";
    $value = normalize('socket option', $name, $value);
    die _error('setsockopt', $name, 0,
        "$name is valid only for TCP sockets")
        if $spec->{tcp} && !_is_tcp($family);
    if (!setsockopt(
        $fh, $spec->{level}, $spec->{option}, _packed_value($spec, $value),
    )) {
        my $errno = 0 + $!;
        die _error('setsockopt', $name, $errno);
    }
    return;
}

sub get_option ($fh, $family, $name) {
    my $spec = $SPEC{$name} // croak "unknown socket option: $name";
    die _error('getsockopt', $name, 0,
        "$name is valid only for TCP sockets")
        if $spec->{tcp} && !_is_tcp($family);
    my $packed = getsockopt($fh, $spec->{level}, $spec->{option});
    if (!defined $packed) {
        my $errno = 0 + $!;
        die _error('getsockopt', $name, $errno);
    }
    die _error('getsockopt', $name, 0,
        "kernel returned an invalid value for $name") if length($packed) < 4;
    my $value = $spec->{type} eq 'timeout'
        ? unpack('I', $packed) : unpack('i', $packed);
    return $value / 1000 if $spec->{type} eq 'timeout';
    return $value ? 1 : 0 if $spec->{type} eq 'boolean';
    return $value;
}

sub apply_policy ($fh, $family, $policy) {
    for my $name (names()) {
        next if !exists($policy->{$name}) || !defined($policy->{$name});
        set_option($fh, $family, $name, $policy->{$name});
    }
    return;
}

sub bind_device ($fh, $device) {
    croak 'bind_device must be a non-empty interface name'
        if !defined($device) || ref($device) || $device eq ''
        || $device =~ /\0/;
    if (!setsockopt($fh, SOL_SOCKET, _SO_BINDTODEVICE, "$device\0")) {
        my $errno = 0 + $!;
        die _error('setsockopt', 'bind_device', $errno);
    }
    return;
}

1;
