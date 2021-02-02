package Lemonldap::NG::Portal::UserDB::Facebook;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_MISSINGREQATTR);

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.11';

has vars => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return {
            %{ $_[0]->conf->{exportedVars} },
            %{ $_[0]->conf->{facebookExportedVars} }
        };
    }
);

# INITIALIZATION

sub init {
    return 1;
}

# RUNNING METHODS

sub getUser {

    # All is done by Auth::Facebook
    PE_OK;
}

sub findUser {

    # Nothing to do here
    PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;

    foreach my $k ( keys %{ $self->vars } ) {
        my $v        = $self->{vars}->{$k};
        my $attr     = $k;
        my $required = ( $attr =~ s/^!// ) ? 1 : 0;
        $req->{sessionInfo}->{$attr} = $req->data->{_facebookData}->{$v};
        if ( $required and not( defined $req->{sessionInfo}->{$attr} ) ) {
            $self->logger->warn(
"Required parameter $v is not provided by Facebook server, aborted"
            );

            $req->mustRedirect(0);
            return PE_MISSINGREQATTR;
        }
    }
    PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
