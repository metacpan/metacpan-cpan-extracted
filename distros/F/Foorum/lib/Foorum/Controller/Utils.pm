package Foorum::Controller::Utils;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub captcha : Global {
    my ( $self, $c ) = @_;
    $c->create_captcha();
}

sub print_message : Private {
    my ( $self, $c, $msg ) = @_;

    if ( ref($msg) ne 'HASH' ) {
        $msg = { msg => $msg };
    }

    $c->stash->{message}  = $msg;
    $c->stash->{template} = 'simple/message.html';
}

sub print_error : Private {
    my ( $self, $c, $error ) = @_;

    if ( ref($error) ne 'HASH' ) {
        $error = { msg => $error };
    }

    $c->stash->{error}    = $error;
    $c->stash->{template} = 'simple/error.html';
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
