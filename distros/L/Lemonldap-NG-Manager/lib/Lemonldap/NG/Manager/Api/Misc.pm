# Miscenalleous endpoints
package Lemonldap::NG::Manager::Api::Misc;

our $VERSION = '2.0.10';

package Lemonldap::NG::Manager::Api;

use strict;
use Mouse;
extends 'Lemonldap::NG::Manager::Api::Common';

# Health-check endpoint
sub status {
    my ( $self, $req ) = @_;
    my $code     = 200;
    my $response = {
        name             => "LemonLDAP::NG Manager API",
        version          => $Lemonldap::NG::Manager::VERSION,
        status           => "ok",
        status_config    => "ok",
        status_sessions  => "ok",
        status_psessions => "ok",
    };

    # Test configuration backend
    my $conf =
      $self->_confAcc->getDBConf( { cfgNum => $self->_confAcc->lastCfg } );
    unless ( $conf->{cfgNum} ) {
        $code                      = 503;
        $response->{status}        = "ko";
        $response->{status_config} = "ko";

    }

    # Test session backend
    my $status = $self->_getSessionDBState( $self->_getSSOMod );
    if ( $status == 0 ) {
        $code                        = 503;
        $response->{status}          = "ko";
        $response->{status_sessions} = "ko";
    }
    elsif ( $status == 2 ) {
        $response->{status_sessions} = "unknown";
    }

    # Test psession backend
    $status = $self->_getSessionDBState( $self->_getPersistentMod );
    if ( $status == 0 ) {
        $code                         = 503;
        $response->{status}           = "ko";
        $response->{status_psessions} = "ko";
    }
    elsif ( $status == 2 ) {
        $response->{status_psessions} = "unknown";
    }

    return $self->sendJSONresponse(
        $req, $response,
        code   => $code,
        pretty => 1
    );
}

# Apache::Session has no API for healthchecking yet. Until it does, we have to
# break the encapsulation model to get the info. This needs to be reworked.
# So far, we only implement the check for:
# * Apache::Session::DBI
# * Apache::Session::Browseable::DBI (Postgresq, MySQL)
# * Apache::Session::MongoDB
#
# Returns 0 for ko, 1 for ok and 2 for unknown
sub _getSessionDBState {
    my ( $self, $mod ) = @_;

    my $fakeobj;

    eval { $fakeobj = $self->_getObjectSessionModule($mod); };

    # If we could not instanciate the session module directly, bail
    return 2 unless $fakeobj;

    my $fakeobj_store = $fakeobj->{object_store};

    # If the Apache::Session object does not have an object store, bail
    return 2 unless $fakeobj_store;

    # Handle DBI-type session stores
    if ( $fakeobj->{object_store}->isa("Apache::Session::Store::DBI") ) {

        # The 'connection' method will fail if the DB is unreachable
        # this is good enough a test for now
        eval { $fakeobj->{object_store}->connection($fakeobj) };
        return $@ ? 0 : 1;
    }

    # Handle MongoDB
    if ( $fakeobj->{object_store}->isa("Apache::Session::Store::MongoDB") ) {

        # Try to find collection
        eval {
            $fakeobj->{object_store}->connection($fakeobj);
            $fakeobj->{object_store}->{collection}->estimated_document_count;
        };
        return $@ ? 0 : 1;
    }

    # We don't know
    return 2;
}

sub _getObjectSessionModule {
    my ( $self, $mod ) = @_;
    my $class = $mod->{module};
    eval "require $class;";

    my $fakeSession = { args => $mod->{options}, };
    bless $fakeSession, $class;
    $fakeSession->populate;
    return $fakeSession;
}

1;
