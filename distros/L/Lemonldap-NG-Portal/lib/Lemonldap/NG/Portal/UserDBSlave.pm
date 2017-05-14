## @file
# Slave userDB mechanism

## @class
# Slave userDB mechanism class
package Lemonldap::NG::Portal::UserDBSlave;

use strict;
use Lemonldap::NG::Portal::_Slave;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::UserDBNull;

our $VERSION = '1.9.1';
our @ISA     = qw(Lemonldap::NG::Portal::UserDBNull);

## @apmethod int setSessionInfo()
# Search exportedVars values in HTTP headers.
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    return PE_FORBIDDENIP
      unless ( $self->checkIP );

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{slaveExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        $v = 'HTTP_' . uc($v);
        $v =~ s/\-/_/g;
        $self->{sessionInfo}->{$k} = $ENV{$v};
    }

    return PE_OK;
}

1;

