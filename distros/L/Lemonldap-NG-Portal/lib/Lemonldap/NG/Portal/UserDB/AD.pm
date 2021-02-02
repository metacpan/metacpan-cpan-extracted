# UserDB::AD inherits from UserDB::LDAP. It just redefined default filter
package Lemonldap::NG::Portal::UserDB::AD;

use strict;
use Mouse;

our $VERSION = '2.0.11';

extends 'Lemonldap::NG::Portal::UserDB::LDAP';

# PROPERTIES

has filter => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->{conf}->{AuthLDAPFilter} ||=
          '(&(sAMAccountName=$user)(objectClass=person))';
        $_[0]->{conf}->{mailLDAPFilter} ||=
          '(&(mail=$mail)(objectClass=person))';
        return $_[0]->buildFilter;
    }
);

has findUserFilter => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{AuthLDAPFilter}
          || $_[0]->conf->{LDAPFilter}
          || '(&(sAMAccountName=$user)(objectClass=person))';
    }
);

1;
