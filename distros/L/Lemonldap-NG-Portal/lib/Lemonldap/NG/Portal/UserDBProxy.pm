## @file
# Proxy userDB mechanism

## @class
# Proxy userDB mechanism class
package Lemonldap::NG::Portal::UserDBProxy;

use strict;
use Lemonldap::NG::Portal::_Proxy;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_Proxy);

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Call Lemonldap::NG::Portal::_Proxy::proxyInit();
# @return Lemonldap::NG::Portal constant
*userDBInit = *Lemonldap::NG::Portal::_Proxy::proxyInit;

## @apmethod int getUser()
# Call Lemonldap::NG::Portal::_Proxy::proxyQuery()
# @return Lemonldap::NG::Portal constant
*getUser = *Lemonldap::NG::Portal::_Proxy::proxyQuery;

sub setGroups {
    PE_OK;
}
1;

