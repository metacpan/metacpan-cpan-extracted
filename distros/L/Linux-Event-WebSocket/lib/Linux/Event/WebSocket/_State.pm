package Linux::Event::WebSocket::_State;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);

sub new ($class, %option) {
    my $endpoint_type = delete $option{endpoint_type};
    croak 'new(): endpoint_type must be client or server'
        if !defined($endpoint_type)
        || ($endpoint_type ne 'client' && $endpoint_type ne 'server');

    my $callbacks = delete($option{callbacks}) // {};
    croak 'new(): callbacks must be a hash reference'
        if ref($callbacks) ne 'HASH';

    my $subprotocols = delete($option{subprotocols}) // [];
    croak 'new(): subprotocols must be an array reference'
        if ref($subprotocols) ne 'ARRAY';

    my $close_timeout = exists($option{close_timeout})
        ? delete($option{close_timeout}) : 5;
    croak 'new(): close_timeout must be a non-negative number'
        if !defined($close_timeout) || ref($close_timeout)
        || $close_timeout !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;

    my $max_message_size = delete $option{max_message_size};
    croak 'new(): max_message_size must be a positive integer'
        if defined($max_message_size)
        && (ref($max_message_size)
            || "$max_message_size" !~ /\A[0-9]+\z/
            || $max_message_size < 1);

    my $self = bless {
        endpoint_type   => $endpoint_type,
        callbacks       => { %$callbacks },
        subprotocols    => [ @$subprotocols ],
        data            => delete $option{data},
        handshake       => delete $option{handshake},
        request         => delete $option{request},
        response        => delete $option{response},
        secure          => delete($option{secure}) ? 1 : 0,
        url             => delete $option{url},
        close_timeout   => 0 + $close_timeout,
        max_message_size => $max_message_size,
        engine          => undef,
        open            => 0,
        closing         => 0,
        close_notified  => 0,
        close_timer     => undef,
    }, $class;

    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    return $self;
}

1;
