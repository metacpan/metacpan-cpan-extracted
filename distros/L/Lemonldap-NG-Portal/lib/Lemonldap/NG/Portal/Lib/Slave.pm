##@file
# Slave common functions

##@class
# Slave common functions
package Lemonldap::NG::Portal::Lib::Slave;

use strict;
use Mouse;
use Net::CIDR;

our $VERSION = '2.23.0';

# RUNNING METHODS

## @method Lemonldap::NG::Portal::_Slave checkIP()
# @return true if remote IP is accredited in LL::NG conf
sub checkIP {
    my ( $self, $req ) = @_;
    my ( @networks, @IPs );
    my $remoteIP = $req->address;

    return 1
      unless $self->conf->{slaveMasterIP};

    @IPs = grep {
        if ( m#/# && Net::CIDR::cidrvalidate($_) ) {
            push @networks, $_;
            $self->logger->debug("Found netblock: $_");
            0;
        }
        elsif ( Net::CIDR::cidrvalidate($_) ) {
            $self->logger->debug("Found IP address: $_");
            1;
        }
        else {
            $self->logger->warn("Found a non valid IP: $_");
            0;
        }
    } split /[,\s]/, $self->conf->{slaveMasterIP};

    foreach (@IPs) {
        return 1
          if $remoteIP eq $_;
    }
    return 1 if Net::CIDR::cidrlookup( $remoteIP, @networks );

    $self->userLogger->warn('Client IP not accredited for Slave module');
    return 0;
}

## @method Lemonldap::NG::Portal::_Slave checkHeader()
# @return true if header content matches LL::NG conf
sub checkHeader {
    my ( $self, $req ) = @_;
    return 1
      unless ( $self->conf->{slaveHeaderName}
        && $self->conf->{slaveHeaderContent} );

    my $slave_header = 'HTTP_' . uc( $self->conf->{slaveHeaderName} );
    $slave_header =~ s/\-/_/g;
    my $headerContent = $req->env->{$slave_header};
    if ( $headerContent && length $headerContent ) {
        $self->logger->debug(
                "Required Slave header: $self->{conf}->{slaveHeaderName}"
              . "\nReceived Slave header content: $headerContent" );
        return 1
          if ( $self->conf->{slaveHeaderContent} =~ /\b$headerContent\b/ );
    }
    else {
        $self->logger->notice("No Slave header content received");
    }

    $self->userLogger->warn('Matching header not found for Slave module');
    return 0;
}

## @method Lemonldap::NG::Portal::_Slave checkCertificate()
# @return true if value matches LL::NG conf
sub checkCertificate {
    my ( $self, $req ) = @_;
    return 1
      unless ( $self->conf->{slaveCertificateField}
        && $self->conf->{slaveCertificateRegexp} );

    my $regexp = $self->conf->{slaveCertificateRegexp};
    my $value  = $req->env->{ $self->conf->{slaveCertificateField} };
    if ( $value && length $value ) {
        $self->logger->debug(
                "Required Slave field: $self->{conf}->{slaveCertificateField}"
              . "\nReceived Slave value: $value" );
        return 1
          if ( $value =~ qr/$regexp/ );
    }
    else {
        $self->logger->notice(
            "No subject found in certificate, check your configuration");
    }

    $self->userLogger->warn(
        'Client certificate not accredited for Slave module');
    return 0;
}

1;
