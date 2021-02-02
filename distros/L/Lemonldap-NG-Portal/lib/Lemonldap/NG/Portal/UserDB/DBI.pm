package Lemonldap::NG::Portal::UserDB::DBI;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_USERNOTFOUND
  PE_BADCREDENTIALS
);

extends 'Lemonldap::NG::Portal::Lib::DBI';

our $VERSION = '2.0.11';

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

    return PE_OK;
}

sub findUser {
    my ( $self, $req, %args ) = @_;
    my $plugin =
      $self->p->loadedModules->{"Lemonldap::NG::Portal::Plugins::FindUser"};
    my ( $searching, $excluding ) = $plugin->retreiveFindUserParams($req);
    eval { $self->p->_authentication->setSecurity($req) };
    return PE_OK unless scalar @$searching;

    my $table = $self->table;
    my $pivot = $args{useMail} ? $self->mailField : $self->pivot;
    my @args;
    my $request = "SELECT $pivot FROM $table WHERE ";
    my ( $iswc, $sth );
    my $wildcard = $self->conf->{findUserWildcard};
    $self->logger->info("DBI UserDB with wildcard ($wildcard)") if $wildcard;
    foreach (@$searching) {
        $iswc = $_->{value} =~ s/\Q$wildcard\E+/%/g if $wildcard;
        $request .= $iswc ? "$_->{key} LIKE ? AND " : "$_->{key} = ? AND ";
        push @args, $_->{value};
    }
    foreach (@$excluding) {
        $request .= "$_->{key} != ? AND ";
        push @args, $_->{value};
    }
    $request =~ s/AND\s$//;
    $self->logger->debug("DBI UserDB built condition: $request");
    $self->logger->debug( "DBI UserDB built args: " . join '|', @args );

    eval {
        $sth = $self->dbh->prepare($request);
        $sth->execute(@args);
    };
    if ($@) {

        # If connection isn't available, error is displayed by dbh()
        $self->logger->error("DBI error: $@") if ( $self->_dbh );
        return PE_ERROR;
    }

    my $results = $sth->fetchall_arrayref();
    if ( $results->[0]->[0] ) {
        my $rank = int( rand( scalar @$results ) );
        $self->logger->debug(
            'DBI UserDB number of result(s): ' . scalar @$results );
        $self->logger->debug("Demo UserDB random rank: $rank");
        $self->userLogger->info(
            "FindUser: DBI UserDB returns $results->[$rank]->[0]");
        $req->data->{findUser} = $results->[$rank]->[0];
        return PE_OK;
    }

    return PE_USERNOTFOUND;
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

    return PE_OK;
}

sub setGroups {

    return PE_OK;
}

1;
