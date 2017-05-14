#!/usr/bin/env perl
####
## Copyright (C) 2003 Samuel Abels, <spam debain org>
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
####

####
## This file provides a class for holding informations regarding a Cisco
## router.
####

package IPDevice::JuniperRouter;
use IPDevice::RouterBase;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::JuniperRouter

=head1 SYNOPSIS

 use IPDevice::JuniperRouter;
 my $router = new IPDevice::JuniperRouter;
 $router->set_hostname('hostname');
 my $card = $router->add_card('0');
 $card->add_module('0/1');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a Juniper
router.

=head1 CONSTRUCTOR AND METHODS

This module provides, in addition to all methods from L<IPDevice::RouterBase|IPDevice::RouterBase>,
the following methods.

=head2 new([%args])

Object constructor. Valid arguments:

I<hostname>: The initial router hostname.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  $self->set_vendor('juniper');
  return $self->_init(%args);
}


=head2 interfacename($interfacename)

Returns the L<IPDevice::RouterBase::Interface|IPDevice::RouterBase::Interface> with the given name.
Valid names have the format 'so-1/2/3', 'lo0', 'lo0.0', 'fe-0/1/2.1', or
just '1/2/3'.
If the interface does not yet exist, it will be created.

=cut
sub interfacename {
  my($self, $logintname) = @_;
  #print "IPDevice::JuniperRouter::interfacename(): $logintname\n";
  my $logintno =  $logintname;   # Logical interface name without the type.
  my $intname  =  $logintname;   # Interface name without the unit number.
  my $intno    =  $logintname;   # Interface name without type.
  my $unit;                      # Logical unit number.
  $logintno    =~ s/^[^\d]*//;
  $intname     =~ s/\..*$//;
  $intno       =~ s/^[^\d]*([^\.]+).*/$1/;
  $unit        = $1 if $logintname =~ /\.(\d+)$/;
  
  # Extract the interface, module and card from the name.
  my($card, $mod);
  $card  = $1, $mod = $2 if $intno =~ /^(\d+)\/(\d+)\/\d+$/;
  #FIXME: Damn Juniper - there can be two fxp0 interfaces - what should we do?
  #print "IPDevice::JuniperRouter::interfacename(): $logintname, $card/$mod/x.$unit\n";
  #FIXME: If new, set unitname. I have to go home now ;).
  return $self->card($card)->module($mod)->interface($intname) if !defined $unit;
  return $self->card($card)->module($mod)->interface($intname)->unit($unit);
}


=head1 COPYRIGHT

Copyright (c) 2004 Samuel Abels.
All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Samuel Abels <spam debain org>

=cut

1;

__END__
