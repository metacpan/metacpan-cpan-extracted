package Lemonldap::NG::Portal::Main::Auth;

use strict;
use Mouse;

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# PROPERTIES

has authnLevel => ( is => 'rw' );

sub stop { return 0 }

# initDisplay is called by the Choice module to prepare the request object.
# Before 2.20, AjaxInitScript and InitCmd were called separately.
sub initDisplay {
    my ( $self, $req ) = @_;

    if ( $self->{AjaxInitScript} ) {
        $self->logger->debug( 'Append ' . $self->{Name} . ' init/script' )
          if $self->{Name};
        $req->data->{customScript} .= $self->AjaxInitScript;
    }
    if ( $self->can('InitCmd') and my $cmd = $self->InitCmd ) {
        $self->logger->debug( 'Launch ' . $self->{Name} . ' init command' )
          if $self->{Name};
        my $res = eval( $self->{InitCmd} );
        if ($@) {
            die "Error running InitCmd: $@";
        }

    }
}

1;
