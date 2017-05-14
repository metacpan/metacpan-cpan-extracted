## @file
# Null userDB mechanism

## @class
# Null userDB mechanism class
package Lemonldap::NG::Portal::UserDBNull;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    PE_OK;
}

## @apmethod int getUser()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub getUser {
    PE_OK;
}

## @apmethod int setSessionInfo()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    PE_OK;
}

## @apmethod int setGroups()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    PE_OK;
}

1;

