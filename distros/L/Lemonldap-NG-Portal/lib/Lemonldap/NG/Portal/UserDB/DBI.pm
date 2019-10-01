package Lemonldap::NG::Portal::UserDB::DBI;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_BADCREDENTIALS);

extends 'Lemonldap::NG::Portal::Lib::DBI';

our $VERSION = '2.0.6';

# PROPERTIES

has exportedVars => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $conf = $_[0]->{conf};
        return { %{ $conf->{exportedVars} }, %{ $conf->{dbiExportedVars} } };
    }
);

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    my $table = $self->table;
    my $pivot = $args{useMail} ? $self->mailField : $self->pivot;
    my $user  = $req->{user};
    my $sth;
    eval {
        $sth = $self->dbh->prepare("SELECT * FROM $table WHERE $pivot=?");
        $sth->execute($user);
    };
    if ($@) {

        # If connection isn't available, error is displayed by dbh()
        $self->logger->error("DBI error: $@") if ( $self->_dbh );
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_ERROR;
    }
    unless ( $req->data->{dbientry} = $sth->fetchrow_hashref() ) {
        $self->userLogger->warn("User $user not found");
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;

    # Set _user unless already defined
    $req->{sessionInfo}->{_user} ||= $req->user;

    foreach my $var ( keys %{ $self->exportedVars } ) {
        my $attr = $self->exportedVars->{$var};
        $req->{sessionInfo}->{$var} = $req->data->{dbientry}->{$attr}
          if ( defined $req->data->{dbientry}->{$attr} );
    }
    PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
