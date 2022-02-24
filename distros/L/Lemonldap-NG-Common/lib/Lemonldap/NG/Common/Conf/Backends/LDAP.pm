##@file
# LDAP configuration backend

##@class
# Implements LDAP backend for Lemonldap::NG
package Lemonldap::NG::Common::Conf::Backends::LDAP;

use strict;
use utf8;
use Net::LDAP;
use Lemonldap::NG::Common::Conf::Constants;    #inherits
use Lemonldap::NG::Common::Conf::Serializer;

our $VERSION = '2.0.0';

BEGIN {
    *Lemonldap::NG::Common::Conf::ldap = \&ldap;
}

sub prereq {
    my $self = shift;
    foreach ( 'ldapServer', 'ldapConfBase', 'ldapBindDN', 'ldapBindPassword' ) {
        unless ( $self->{$_} ) {
            $Lemonldap::NG::Common::Conf::msg .=
              "$_ is required in LDAP configuration type \n";
            return 0;
        }
    }
    $self->{ldapObjectClass}      ||= "applicationProcess";
    $self->{ldapAttributeId}      ||= "cn";
    $self->{ldapAttributeContent} ||= "description";
    1;
}

sub available {
    my $self = shift;

    unless ( $self->ldap ) {
        return 0;
    }

    my $search = $self->ldap->search(
        base   => $self->{ldapConfBase},
        filter => '(objectClass=' . $self->{ldapObjectClass} . ')',
        scope  => 'one',
        attrs  => [ $self->{ldapAttributeId} ],
    );

    if ( $search->code ) {
        $self->logError($search);
        return 0;
    }

    my @entries = $search->entries();
    my @conf;
    foreach (@entries) {
        my $cn = $_->get_value( $self->{ldapAttributeId} );
        my ($cfgNum) = ( $cn =~ /lmConf-(\d*)/ );
        push @conf, $cfgNum;
    }
    $self->ldap->unbind() && delete $self->{ldap};
    return sort { $a <=> $b } @conf;
}

sub lastCfg {
    my $self  = shift;
    my @avail = $self->available;
    return $avail[$#avail];
}

sub ldap {
    my $self = shift;
    return $self->{ldap} if ( $self->{ldap} );

    # Parse servers configuration
    my $useTls = 0;
    my $tlsParam;
    my @servers = ();
    foreach my $server ( split /[\s,]+/, $self->{ldapServer} ) {
        if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
            $useTls   = 1;
            $server   = $1;
            $tlsParam = $2 || "";
        }
        else {
            $useTls = 0;
        }
        push @servers, $server;
    }

    # Connect
    my $ldap = Net::LDAP->new(
        \@servers,
        keepalive => 1,
        onerror   => undef,
        verify    => ( $self->{ldapVerify} || "require" ),
        ( $self->{ldapCAFile} ? ( cafile => $self->{ldapCAFile} ) : () ),
        ( $self->{ldapCAPath} ? ( capath => $self->{ldapCAPath} ) : () ),
        ( $self->{ldapPort}   ? ( port   => $self->{ldapPort} )   : () ),
        raw => => qr/(?i:^jpegPhoto|;binary)/
    );

    unless ($ldap) {
        $Lemonldap::NG::Common::Conf::msg .= "$@\n";
        return;
    }
    elsif ( $Net::LDAP::VERSION < '0.64' ) {

        # CentOS7 has a bug in which IO::Socket::SSL will return a broken
        # socket when certificate validation fails. Net::LDAP does not catch
        # it, and the process ends up crashing.
        # As a precaution, make sure the underlying socket is doing fine:
        if (    $ldap->socket->isa('IO::Socket::SSL')
            and $ldap->socket->errstr < 0 )
        {
            $Lemonldap::NG::Common::Conf::msg .=
              "SSL connection error: " . $ldap->socket->errstr;
            return;
        }
    }

    # Start TLS if needed
    if ($useTls) {
        my %h = split( /[&=]/, $tlsParam );
        $h{verify} ||= $self->{ldapVerify} || "require";
        $h{cafile} ||= $self->{ldapCAFile} if ( $self->{ldapCAFile} );
        $h{capath} ||= $self->{ldapCAPath} if ( $self->{ldapCAPath} );
        my $start_tls = $ldap->start_tls(%h);
        if ( $start_tls->code ) {
            $self->logError($start_tls);
            return;
        }
    }

    # Bind with credentials
    my $bind =
      $ldap->bind( $self->{ldapBindDN}, password => $self->{ldapBindPassword} );
    if ( $bind->code ) {
        $self->logError($bind);
        return;
    }

    $self->{ldap} = $ldap;
    return $ldap;
}

sub lock {

    # No lock for LDAP
    return 1;
}

sub isLocked {

    # No lock for LDAP
    return 0;
}

sub unlock {

    # No lock for LDAP
    return 1;
}

sub store {
    my ( $self, $fields ) = @_;

    unless ( $self->ldap ) {
        return 0;
    }

    $fields = $self->serialize($fields);

    my $lastCfg = $self->lastCfg;

    my $confName = "lmConf-" . $fields->{cfgNum};
    my $confDN =
      $self->{ldapAttributeId} . "=$confName," . $self->{ldapConfBase};

    # Store values as {key}value
    my @confValues;
    while ( my ( $k, $v ) = each(%$fields) ) {
        push @confValues, "{$k}$v";
    }

    my $operation;

    if ( $lastCfg == $fields->{cfgNum} ) {
        $operation =
          $self->ldap->modify( $confDN,
            replace => { $self->{ldapAttributeContent} => \@confValues } );
    }
    else {
        $operation = $self->ldap->add(
            $confDN,
            attrs => [
                objectClass              => [ 'top', $self->{ldapObjectClass} ],
                $self->{ldapAttributeId} => $confName,
                $self->{ldapAttributeContent} => \@confValues,
            ]
        );
    }

    if ( $operation->code ) {
        $self->logError($operation);
        return 0;
    }

    $self->ldap->unbind() && delete $self->{ldap};
    return $fields->{cfgNum};
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;

    unless ( $self->ldap ) {
        return;
    }

    my $f;
    my $confName = "lmConf-" . $cfgNum;
    my $confDN =
      $self->{ldapAttributeId} . "=$confName," . $self->{ldapConfBase};

    my $search = $self->ldap->search(
        base   => $confDN,
        filter => '(objectClass=' . $self->{ldapObjectClass} . ')',
        scope  => 'base',
        attrs  => [ $self->{ldapAttributeContent} ],
    );

    if ( $search->code ) {
        $self->logError($search);
        return;
    }

    my $entry      = $search->shift_entry();
    my @confValues = $entry->get_value( $self->{ldapAttributeContent} );
    foreach (@confValues) {
        my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/s );
        if ($fields) {
            $f->{$k} = $v if ( grep { $_ eq $k } @$fields );
        }
        else {
            $f->{$k} = $v;
        }
    }
    $self->ldap->unbind() && delete $self->{ldap};
    return $self->unserialize($f);
}

sub delete {
    my ( $self, $cfgNum ) = @_;

    unless ( $self->ldap ) {
        return 0;
    }

    my $confDN =
        $self->{ldapAttributeId}
      . "=lmConf-"
      . $cfgNum . ","
      . $self->{ldapConfBase};
    my $delete = $self->ldap->delete($confDN);
    $self->ldap->unbind() && delete $self->{ldap};
    $self->logError($delete) if ( $delete->code );
}

sub logError {
    my $self           = shift;
    my $ldap_operation = shift;
    $Lemonldap::NG::Common::Conf::msg .=
        "LDAP error "
      . $ldap_operation->code . ": "
      . $ldap_operation->error . " \n";
}

1;
__END__
