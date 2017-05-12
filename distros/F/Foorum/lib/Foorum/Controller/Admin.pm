package Foorum::Controller::Admin;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub auto : Private {
    my ( $self, $c ) = @_;

    # default template
    $c->stash->{template} = 'admin/index.html';

    unless ( $c->user_exists ) {
        $c->res->redirect('/login');
        return 0;
    }

    # we have admin or moderator for 'site' field
    unless ( $c->model('Policy')->is_moderator( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }

    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
