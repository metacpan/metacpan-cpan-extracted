##@file
# DBI authentication backend file

##@class
# LDAP authentication backend class
package Lemonldap::NG::Portal::AuthDBI;

use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_WebForm Lemonldap::NG::Portal::_DBI);
use strict;

our $VERSION = '1.9.1';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @apmethod int authInit()
# Check DBI paramaters
#@return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    return PE_OK if ($initDone);

    unless ($self->{dbiAuthChain}
        and $self->{dbiAuthTable}
        and $self->{dbiAuthUser}
        and $self->{dbiAuthPassword}
        and $self->{dbiAuthLoginCol}
        and $self->{dbiAuthPasswordCol} )
    {
        $self->lmLog( "Missing configuration parameters for DBI authentication",
            'error' );
        return PE_ERROR;
    }

    $self->{_authnLevel} = $self->{dbiAuthnLevel};

    $initDone = 1;
    PE_OK;
}

## @apmethod int authenticate()
# Find row in DBI backend with user and password criterions
#@return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiAuthChain}, $self->{dbiAuthUser},
        $self->{dbiAuthPassword} );
    return PE_ERROR unless $dbh;

    # Check credentials
    my $result = $self->check_password($dbh);
    if ($result) {
        return PE_OK;
    }
    else {
        return PE_BADCREDENTIALS;
    }
}

## @apmethod int authFinish()
# Disconnect.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    my $self = shift;

    eval { $self->{_dbh}->disconnect(); };

    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "standardform";
}

1;
