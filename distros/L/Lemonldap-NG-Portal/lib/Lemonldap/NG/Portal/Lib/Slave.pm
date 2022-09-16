##@file
# Slave common functions

##@class
# Slave common functions
package Lemonldap::NG::Portal::Lib::Slave;

use strict;
use Mouse;

our $VERSION = '2.0.15';

# RUNNING METHODS

## @method Lemonldap::NG::Portal::_Slave checkIP()
# @return true if remote IP is accredited in LL::NG conf
sub checkIP {
    my ( $self, $req ) = @_;
    my $remoteIP = $req->address;
    return 1
      if (!$self->conf->{slaveMasterIP}
        || $self->conf->{slaveMasterIP} =~ /\b$remoteIP\b/ );

    $self->userLogger->warn('Client IP not accredited for Slave module');
    return 0;
}

## @method Lemonldap::NG::Portal::_Slave checkHeader()
# @return true if header content matches LL::NG conf
sub checkHeader {
    my ( $self, $req ) = @_;
    return 1
      unless ( $self->conf->{slaveHeaderName}
        and $self->conf->{slaveHeaderContent} );

    my $slave_header = 'HTTP_' . uc( $self->conf->{slaveHeaderName} );
    $slave_header =~ s/\-/_/g;
    my $headerContent = $req->env->{$slave_header};
    $self->logger->debug(
        "Required Slave header => $self->{conf}->{slaveHeaderName}");
    $self->logger->debug("Received Slave header content => $headerContent");
    return 1
      if (  $headerContent
        and $self->conf->{slaveHeaderContent} =~ /\b$headerContent\b/ );

    $self->userLogger->warn('Matching header not found for Slave module ');
    return 0;
}

1;
