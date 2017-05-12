package ex::interface;

use strict;
no strict 'refs';

require 5.6.0;
our $VERSION = "0.2";


sub import {
    my $self = shift;
    my %__METHOD = map {$_ => 1} @_;
    my $interface = caller;
    *{"$interface\::__METHOD"} = \%__METHOD;
    *{"$interface\::AUTOLOAD"} = \&their_AUTOLOAD;
}

sub their_AUTOLOAD {
    our $AUTOLOAD = $AUTOLOAD;
    $AUTOLOAD =~ s/(.*):://;
    return if $AUTOLOAD eq 'DESTROY';
    my $interface = $1;
    if ($ {"$interface\::__METHOD"}{$AUTOLOAD}) {
        require Carp;
        Carp::croak("The interface method '$AUTOLOAD' has not been implemented");
    }
    else {
        my $self = shift;
        $AUTOLOAD =~ s/^/SUPER::/;
        $self->$AUTOLOAD(@_);
    }
}

sub DESTROY { return }

1;
