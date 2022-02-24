package Lemonldap::NG::Portal::UserDB::LDAP;

use strict;
use Mouse;
use utf8;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

extends 'Lemonldap::NG::Portal::Lib::LDAP';

our $VERSION = '2.0.12';

has ldapGroupAttributeNameSearch => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $attributes = [];
        @$attributes =
          split( /\s+/, $_[0]->{conf}->{ldapGroupAttributeNameSearch} )
          if $_[0]->{conf}->{ldapGroupAttributeNameSearch};
        push( @$attributes, $_[0]->{conf}->{ldapGroupAttributeNameGroup} )
          if (  $_[0]->{conf}->{ldapGroupRecursive}
            and $_[0]->{conf}->{ldapGroupAttributeNameGroup} ne "dn" );
        return $attributes;
    }
);

# RUNNING METHODS
#
# getUser is provided by Portal::Lib::LDAP

# Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# a separator (param multiValuesSeparator)
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{_dn} = $req->data->{dn};

    my %vars = (
        %{ $self->conf->{exportedVars} },
        %{ $self->conf->{ldapExportedVars} }
    );
    while ( my ( $k, $v ) = each %vars ) {

        my $value = $self->ldap->getLdapValue( $req->data->{ldapentry}, $v );

        # getLdapValue returns an empty string for missing attribute
        # but we really want to return undef so they don't get stored in session
        # This has to be a string comparison because "0" is a valid attribute
        # value. See #2403
        $value = undef if ( $value eq "" );

        $req->sessionInfo->{$k} = $value;
    }

    return PE_OK;
}

# Load all groups in $groups.
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my ( $self, $req ) = @_;
    my $groups  = $req->{sessionInfo}->{groups}  || '';
    my $hGroups = $req->{sessionInfo}->{hGroups} || {};

    if ( $self->conf->{ldapGroupBase} ) {

        # Get value for group search
        my $group_value = $self->ldap->getLdapValue( $req->data->{ldapentry},
            $self->conf->{ldapGroupAttributeNameUser} );

        if ( $self->conf->{ldapGroupDecodeSearchedValue} ) {
            utf8::decode($group_value);
        }

        $self->logger->debug( "Searching LDAP groups in "
              . $self->conf->{ldapGroupBase}
              . " for $group_value" );

        # Call searchGroups
        my $ldapGroups = $self->ldap->searchGroups(
            $self->conf->{ldapGroupBase},
            $self->conf->{ldapGroupAttributeName},
            $group_value,
            $self->ldapGroupAttributeNameSearch,
            $req->{ldapGroupDuplicateCheck}
        );

        foreach ( keys %$ldapGroups ) {
            my $groupName = $_;
            $hGroups->{$groupName} = $ldapGroups->{$groupName};
            my $groupValues = [];
            foreach ( @{ $self->ldapGroupAttributeNameSearch } ) {
                next if $_ =~ /^name$/;
                my $firstValue = $ldapGroups->{$groupName}->{$_}->[0];
                push @$groupValues, $firstValue;
            }
            $groups .= $self->conf->{multiValuesSeparator} if $groups;
            $groups .= join( '|', @$groupValues );
        }

    }

    $req->{sessionInfo}->{groups}  = $groups;
    $req->{sessionInfo}->{hGroups} = $hGroups;

    return PE_OK;
}

1;
