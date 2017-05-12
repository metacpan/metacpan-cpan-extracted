##@file
# LDAP user database backend file

##@class
# LDAP user database backend class
package Lemonldap::NG::Portal::UserDBLDAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap

our $VERSION = '1.4.9';

## @method int userDBInit()
# Transform ldapGroupAttributeNameSearch in ARRAY ref
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    unless ( ref $self->{ldapGroupAttributeNameSearch} eq 'ARRAY' ) {
        my @values = split( /\s/, $self->{ldapGroupAttributeNameSearch} );
        $self->{ldapGroupAttributeNameSearch} = \@values;
    }

    PE_OK;
}

## @apmethod int getUser()
# 7) Launch formateFilter() and search()
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;
    return $self->_subProcess(qw(formateFilter search));
}

## @apmethod protected int formateFilter()
# Set the LDAP filter.
# By default, the user is searched in the LDAP server with its UID.
# @return Lemonldap::NG::Portal constant
sub formateFilter {
    my $self = shift;
    $self->{LDAPFilter} =
        $self->{mail}
      ? $self->{mailLDAPFilter}
      : $self->{AuthLDAPFilter}
      || $self->{LDAPFilter};
    if ( $self->{LDAPFilter} ) {
        $self->lmLog( "LDAP submitted filter: " . $self->{LDAPFilter},
            'debug' );
    }
    else {
        $self->{LDAPFilter} =
          $self->{mail}
          ? '(&(mail=$mail)(objectClass=inetOrgPerson))'
          : '(&(uid=$user)(objectClass=inetOrgPerson))';
    }
    $self->{LDAPFilter} =~ s/\$(user|_?password|mail)/$self->{$1}/g;
    $self->{LDAPFilter} =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/g;
    $self->lmLog( "LDAP transformed filter: " . $self->{LDAPFilter}, 'debug' );
    PE_OK;
}

## @apmethod protected int search()
# Search the LDAP DN of the user.
# @return Lemonldap::NG::Portal constant
sub search {
    my $self = shift;
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }
    my @attrs = (
        values %{ $self->{exportedVars} },
        values %{ $self->{ldapExportedVars} }
    );
    my $mesg = $self->ldap->search(
        base   => $self->{ldapBase},
        scope  => 'sub',
        filter => $self->{LDAPFilter},
        attrs  => \@attrs,
    );
    $self->lmLog(
        'LDAP Search with base: '
          . $self->{ldapBase}
          . ' and filter: '
          . $self->{LDAPFilter},
        'debug'
    );
    if ( $mesg->code() != 0 ) {
        $self->lmLog( 'LDAP Search error: ' . $mesg->error, 'error' );
        $self->ldap->unbind;
        $self->{flags}->{ldapActive} = 0;
        return PE_LDAPERROR;
    }
    if ( $mesg->count() > 1 ) {
        $self->lmLog( 'More than one entry returned by LDAP directory',
            'error' );
        $self->ldap->unbind;
        $self->{flags}->{ldapActive} = 0;
        return PE_BADCREDENTIALS;
    }
    unless ( $self->{entry} = $mesg->entry(0) ) {
        my $user = $self->{mail} || $self->{user};
        $self->_sub( 'userError', "$user was not found in LDAP directory" );
        $self->ldap->unbind;
        $self->{flags}->{ldapActive} = 0;
        return PE_BADCREDENTIALS;
    }
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

## @apmethod int setSessionInfo()
# 7) Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# a separator (param multiValuesSeparator)
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;
    $self->{sessionInfo}->{dn} = $self->{dn};

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{ldapExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        $self->{sessionInfo}->{$k} =
          $self->{ldap}->getLdapValue( $self->{entry}, $v )
          || "";
    }

    PE_OK;
}

## @apmethod int setGroups()
# Load all groups in $groups.
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my $self    = shift;
    my $groups  = $self->{sessionInfo}->{groups};
    my $hGroups = $self->{sessionInfo}->{hGroups};

    if ( $self->{ldapGroupBase} ) {

        # Push group attribute value for recursive search
        push(
            @{ $self->{ldapGroupAttributeNameSearch} },
            $self->{ldapGroupAttributeNameGroup}
          )
          if (  $self->{ldapGroupRecursive}
            and $self->{ldapGroupAttributeNameGroup} ne "dn" );

        # Get value for group search
        my $group_value =
          $self->{ldap}
          ->getLdapValue( $self->{entry}, $self->{ldapGroupAttributeNameUser} );

        $self->lmLog(
            "Searching LDAP groups in "
              . $self->{ldapGroupBase}
              . " for $group_value",
            'debug'
        );

        # Call searchGroups
        my $ldapGroups = $self->{ldap}->searchGroups(
            $self->{ldapGroupBase}, $self->{ldapGroupAttributeName},
            $group_value,           $self->{ldapGroupAttributeNameSearch}
        );

        foreach ( keys %$ldapGroups ) {
            my $groupName = $_;
            $hGroups->{$groupName} = $ldapGroups->{$groupName};
            my $groupValues = [];
            foreach ( @{ $self->{ldapGroupAttributeNameSearch} } ) {
                next if $_ =~ /^name$/;
                my $firstValue = $ldapGroups->{$groupName}->{$_}->[0];
                push @$groupValues, $firstValue;
            }
            $groups .=
              $self->{multiValuesSeparator} . join( '|', @$groupValues );
        }

    }

    $self->{sessionInfo}->{groups}  = $groups;
    $self->{sessionInfo}->{hGroups} = $hGroups;
    PE_OK;
}

## @apmethod int userDBFinish()
# Unbind.
# @return Lemonldap::NG::Portal constant
sub userDBFinish {
    my $self = shift;

    if ( ref( $self->{ldap} ) && $self->{flags}->{ldapActive} ) {
        $self->ldap->unbind();
        $self->{flags}->{ldapActive} = 0;
    }

    PE_OK;
}

1;

