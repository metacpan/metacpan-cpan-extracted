package Lemonldap::NG::Portal::UserDB::LDAP;

use strict;
use Mouse;
use utf8;
use Lemonldap::NG::Portal::Main::Constants
  qw(PE_OK PE_LDAPCONNECTFAILED PE_LDAPERROR PE_BADCREDENTIALS);

extends 'Lemonldap::NG::Portal::Lib::LDAP';

our $VERSION = '2.0.2';

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

has attrs => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return [
            values %{ $_[0]->{conf}->{exportedVars} },
            values %{ $_[0]->{conf}->{ldapExportedVars} }
        ];
    }
);

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    return PE_LDAPCONNECTFAILED unless $self->ldap and $self->bind();
    my $mesg = $self->ldap->search(
        base   => $self->conf->{ldapBase},
        scope  => 'sub',
        filter => (
              $args{useMail}
            ? $self->mailFilter->($req)
            : $self->filter->($req)
        ),
        defer => $self->conf->{ldapSearchDeref} || 'find',
        attrs => $self->attrs,
    );
    if ( $mesg->code() != 0 ) {
        $self->logger->error( 'LDAP Search error: ' . $mesg->error );
        return PE_LDAPERROR;
    }
    if ( $mesg->count() > 1 ) {
        $self->logger->error('More than one entry returned by LDAP directory');
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    unless ( $req->data->{entry} = $mesg->entry(0) ) {
        $self->userLogger->warn("$req->{user} was not found in LDAP directory");
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    $req->data->{dn} = $req->data->{entry}->dn();
    PE_OK;
}

# Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# a separator (param multiValuesSeparator)
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{_dn} = $req->data->{dn};

    my %vars = ( %{ $self->conf->{exportedVars} },
        %{ $self->conf->{ldapExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        $req->sessionInfo->{$k} =
          $self->ldap->getLdapValue( $req->data->{entry}, $v ) || "";
    }

    PE_OK;
}

# Load all groups in $groups.
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my ( $self, $req ) = @_;
    my $groups  = $req->{sessionInfo}->{groups};
    my $hGroups = $req->{sessionInfo}->{hGroups};

    if ( $self->conf->{ldapGroupBase} ) {

        # Get value for group search
        my $group_value = $self->ldap->getLdapValue( $req->data->{entry},
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
    PE_OK;
}

1;
