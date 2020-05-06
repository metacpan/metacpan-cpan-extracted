package Lemonldap::NG::Manager::Plugin;

use strict;
use Mouse;
our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Common::Module';

has _confAcc => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return $_[0]->p->{_confAcc} },
);

sub sendError {
    my $self = shift;
    return $self->p->sendError(@_);
}

sub sendJSONresponse {
    my $self = shift;
    return $self->p->sendJSONresponse(@_);
}

sub addRoute {
    my ( $self, $word, $subName, $methods, $transform ) = @_;
    $transform //= sub {
        my ($sub) = @_;
        if ( ref $sub ) {
            return sub {
                shift;
                return $sub->( $self, @_ );
            }
        }
        else {
            return sub {
                shift;
                return $self->$sub(@_);
            }
        }
    };
    $self->p->addRoute( $word, $subName, $methods, $transform );
    return $self;
}

sub loadTemplate {
    my $self = shift;
    return $self->p->loadTemplate(@_);
}

1;
