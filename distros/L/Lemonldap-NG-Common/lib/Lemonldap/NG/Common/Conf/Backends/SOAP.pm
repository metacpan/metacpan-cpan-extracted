package Lemonldap::NG::Common::Conf::Backends::SOAP;

use strict;
use utf8;
use SOAP::Lite;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.0.0';

#parameter proxy Url of SOAP service
#parameter proxyOptions SOAP::Lite parameters

BEGIN {
    *Lemonldap::NG::Common::Conf::_soapCall = \&_soapCall;
    *Lemonldap::NG::Common::Conf::_connect  = \&_connect;

    sub SOAP::Transport::HTTP::Client::get_basic_credentials {
        return $Lemonldap::NG::Common::Conf::Backends::SOAP::username =>
          $Lemonldap::NG::Common::Conf::Backends::SOAP::password;
    }
}

our ( $username, $password ) = ( '', '' );

sub prereq {
    my $self = shift;
    unless ( $self->{proxy} ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "proxy parameter is required in SOAP configuration type \n";
        return 0;
    }
    1;
}

sub _connect {
    my $self = shift;
    return $self->{service} if ( $self->{service} );
    my @args = ( $self->{proxy} );
    if ( $self->{proxyOptions} ) {
        push @args, %{ $self->{proxyOptions} };
    }
    $self->{ns} ||= 'urn:/Lemonldap/NG/Common/PSGI/SOAPService';
    return $self->{service} = SOAP::Lite->ns( $self->{ns} )->proxy(@args);
}

sub _soapCall {
    my $self = shift;
    my $func = shift;
    $username = $self->{User};
    $password = $self->{Password};
    my $r = $self->_connect->$func(@_);
    if ( $r->fault() ) {
        print STDERR "SOAP error : " . $r->fault()->{faultstring};
        return ();
    }
    return $r->result;
}

sub available {
    my $self = shift;
    return @{ $self->_soapCall( 'available', @_ ) };
}

sub lastCfg {
    my $self = shift;
    return $self->_soapCall( 'lastCfg', @_ );
}

# lock and unlock must not be requested by the SOAP client, since
# they will be done by the SOAP server when storing the config
sub lock {
    return 1;
}

sub unlock {
    return 1;
}

sub isLocked {
    return 1;
}

sub store {
    my $self = shift;
    return $self->_soapCall( 'store', @_ );
}

sub load {
    my $self = shift;
    my $conf = $self->_soapCall( 'getConfig', @_ );

    # Force empty hash that are not converted by SOAP
    foreach ( keys %{ $conf || {} } ) {
        if ( $_ =~ /$hashParameters/ ) {
            $conf->{$_} ||= {};
        }
    }

    return $conf;
}

1;
