##@file
# Slave common functions

##@class
# Slave common functions
package Lemonldap::NG::Portal::_Slave;

use Exporter;
use base qw(Exporter);
use strict;

our @EXPORT  = qw(checkIP);
our $VERSION = '1.2.0';

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

1;
