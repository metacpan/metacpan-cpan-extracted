##@file
# AD user database backend file

##@class
# AD user database backend class
package Lemonldap::NG::Portal::UserDBAD;

use strict;

our $VERSION = '1.9.1';

use base qw(Lemonldap::NG::Portal::UserDBLDAP);

## @apmethod protected int formateFilter()
# Set the default LDAP filter for AD.
# By default, the user is searched in the LDAP server with sAMAccountName.
# @return Lemonldap::NG::Portal constant
sub formateFilter {
    my $self = shift;

    $self->{AuthLDAPFilter} ||= '(&(sAMAccountName=$user)(objectClass=person))';
    $self->{mailLDAPFilter} ||= '(&(mail=$mail)(objectClass=person))';

    return $self->SUPER::formateFilter;
}

1;

