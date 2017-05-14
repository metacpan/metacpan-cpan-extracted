##@file
# Slave common functions

##@class
# Slave common functions
package Lemonldap::NG::Portal::_Slave;

use Exporter;
use base qw(Exporter);
use strict;

our @EXPORT  = qw(checkIP checkHeader);
our $VERSION = '1.9.3';

## @method Lemonldap::NG::Portal::_Slave checkIP()
# @return true if remote IP is accredited in LL::NG conf
sub checkIP {
    my $self     = shift;
    my $remoteIP = $self->remote_addr;
    return 1
      if (!$self->{slaveMasterIP}
        || $self->{slaveMasterIP} =~ /\b$remoteIP\b/ );

    $self->_sub( 'userError', "Client IP not accredited for Slave module" );
    return 0;
}

## @method Lemonldap::NG::Portal::_Slave checkHeader()
# @return true if header content matches LL::NG conf
sub checkHeader {
    my $self = shift;
    return 1
      unless ( $self->{slaveHeaderName} and $self->{slaveHeaderContent} );
    my $headerContent = $self->http( $self->{slaveHeaderName} );
    return 1 if ( $self->{slaveHeaderContent} =~ /\b$headerContent\b/ );

    $self->_sub( 'userError', "Matching header not found for Slave module" );
    return 0;
}

1;
