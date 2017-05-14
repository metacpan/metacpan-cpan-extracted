## @file
# Remote userDB mechanism

## @class
# Remote userDB mechanism class
package Lemonldap::NG::Portal::UserDBRemote;

use strict;
use Lemonldap::NG::Portal::_Remote;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_Remote);

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Call Lemonldap::NG::Portal::_Remote::init();
# @return Lemonldap::NG::Portal constant
*userDBInit = *Lemonldap::NG::Portal::_Remote::init;

## @apmethod int getUser()
# Call checkRemoteId();
# @return Lemonldap::NG::Portal constant
*getUser = *Lemonldap::NG::Portal::_Remote::checkRemoteId;

## @apmethod int setSessionInfos
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;
    delete $self->{rSessionInfo}->{_session_id};
    $self->{sessionInfo} = $self->{rSessionInfo};
    PE_OK;
}

## @apmethod int setGroups
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my $self = shift;
    PE_OK;
}

1;

