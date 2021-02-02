package Lemonldap::NG::Portal::UserDB::REST;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_USERNOTFOUND
  PE_BADCREDENTIALS
);

extends qw(
  Lemonldap::NG::Common::Module
  Lemonldap::NG::Portal::Lib::REST
);

our $VERSION = '2.0.11';

# INITIALIZATION

sub init {
    my $self = shift;

    # Add warning in log
    unless ( $self->conf->{restUserDBUrl} ) {
        $self->logger->error('User REST URL ids not set');
        return 0;
    }
    if ( !$self->conf->{restFindUserDBUrl} && $self->conf->{findUser} ) {
        $self->logger->error('findUser REST URL is not set');
        return 0;
    }
    return 1;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    my $res;
    $res = eval {
        $self->restCall(
            $self->conf->{restUserDBUrl},
            {
                ( $args{useMail} ? 'mail' : 'user' ) => $req->user,
                'useMail' => ( $args{useMail} ? JSON::true : JSON::false ),

            }
        );
    };
    if ($@) {
        $self->logger->error("UserDB REST error: $@");
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_ERROR;
    }
    unless ( $res->{result} ) {
        $self->userLogger->warn( 'User ' . $req->user . ' not found' );
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    $req->data->{restUserDBInfo} = $res->{info} || {};

    return PE_OK;
}

sub findUser {
    my ( $self, $req, %args ) = @_;
    my $plugin =
      $self->p->loadedModules->{"Lemonldap::NG::Portal::Plugins::FindUser"};
    my ( $searching, $excluding ) = $plugin->retreiveFindUserParams($req);
    eval { $self->p->_authentication->setSecurity($req) };
    return PE_OK unless scalar @$searching;

    my $res;
    $searching = [
        map {
            { $_->{key} => $_->{value} }
        } @$searching
    ];
    $excluding = [
        map {
            { $_->{key} => $_->{value} }
        } @$excluding
    ];
    $res = eval {
        $self->restCall(
            $self->conf->{restFindUserDBUrl},
            {
                searchingAttributes => to_json($searching),
                (
                    scalar @$excluding
                    ? ( excludingAttributes => to_json($excluding) )
                    : ()
                )
            }
        );
    };
    if ($@) {
        $self->logger->error("UserDB REST error: $@");
        return PE_ERROR;
    }
    unless ( $res->{result} ) {
        $self->userLogger->info('FindUser: no user found from REST UserDB');
        return PE_USERNOTFOUND;
    }

    my $results = $res->{users};
    $self->logger->debug(
        'REST UserDB number of result(s): ' . scalar @$results );
    if ( scalar @$results ) {
        my $rank = int( rand( scalar @$results ) );
        $self->logger->debug("REST UserDB random rank: $rank");
        $self->userLogger->info(
            "FindUser: REST UserDB returns $results->[$rank]");
        $req->data->{findUser} = $results->[$rank];
        return PE_OK;
    }

    return PE_USERNOTFOUND;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{$_} = $req->data->{restUserDBInfo}->{$_}
      foreach ( keys %{ $req->data->{restUserDBInfo} } );
    PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
