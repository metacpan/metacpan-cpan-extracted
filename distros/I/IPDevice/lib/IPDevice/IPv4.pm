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
## This file provides methods for IP Version 4 based checks and conversions.
####

package IPDevice::IPv4;
use strict;

use constant TRUE  => 1;
use constant FALSE => 0;

my $BYTE = '[1-2]?[0-9]?[0-9]';   # Matches an integer representing a byte.

=head1 NAME

IPDevice::IPv4

=head1 DESCRIPTION

This module provides routines for IP Version 4 based checks and conversions.

=head1 SYNOPSIS

 use IPDevice::IPv4;
 if (IPDevice::IPv4::check_ip("10.131.10.1")) { print "Valid IP address.";  }
 else                         { print "Invalid IP address"; }
 if (IPDevice::IPv4::check_ip("10.131.10.1/24")) { print "Valid prefix.";  }
 else                            { print "Invalid prefix"; }

=head1 METHODS

=cut
## Purpose: Evaluates the logarithm to a variable base.
##
sub _log_base {
  my($base, $val) = @_;
  return(log($val) / log($base));
}


=head2 check_ip($ip)

Check the syntax of an IP address for validity.

=cut
sub check_ip {
  my $ip = shift;
  my @bytes = ($ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  return -1 if @bytes != 4;             # Wir brauchen mindestens vier
                                        # Substrings.
  map {                                 # Prüfe, ob jede Zahl > 0 und < 255 ist.
    return -2 if $_ eq '';              # Keine der Zahlen darf leer sein.
    return -3 if ($_ < 0 or $_ > 255);  # Prüfe den Zahlenwert.
  } @bytes;
  return 0;
}


=head2 check_prefix($prefix)

Check the syntax of an IP address prefix for validity.

=cut
sub check_prefix {
  my $prefix = shift;
  $prefix =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})$/;
  my($ip, $pfxlen) = ($1, $2);
  return -1 if check_ip($ip) < 0;                    # Prüfe den IP-Adressanteil.
  return -2 if $pfxlen eq '';                  # Wir brauchen die Prefixlänge.
  return -3 if ($pfxlen < 0 or $pfxlen > 32);  # Prefixlängen-Check.
  return 0;
}


=head2 check_prefixlen($prefixlength)

Check the syntax of an IP prefix length.

=cut
sub check_prefixlen {
  my $pfxlen = shift;
  return FALSE if $pfxlen !~ /^\d+$/;
  return FALSE if $pfxlen < 0;
  return FALSE if $pfxlen > 32;
  return TRUE;
}


=head2 pfxlen2mask($prefixlength)

Convert a prefixlength to an IP mask address.

=cut
sub pfxlen2mask {
  my $pfxlen = shift;
  return FALSE if !check_prefixlen($pfxlen);
  my $mask = 0xFFFFFFFF << (32 - $pfxlen);
  return integer2ip($mask);
}


=head2 mask2pfxlen($mask)

Convert an IP mask address to a prefixlength.

=cut
sub mask2pfxlen {
  my $mask = shift;
  return FALSE if check_ip($mask) < 0;
  my $pfxlen = ip2integer($mask);   # Convert to an integer.
  $pfxlen = $pfxlen ^ 0xFFFFFFFF;   # Invert the value.
  return 32 if $pfxlen <= 0;        # That would be invalid.
  return 32 - (int(_log_base(2, $pfxlen)) + 1);  # Calculate the prefix length.
}


=head2 ip2integer($ip)

Convert a human readable (byte notated) ip address to a 4-byte integer value.

=cut
sub ip2integer {
  my $ip = shift;
  return if check_ip($ip) != 0;
  $ip =~ /($BYTE)\.($BYTE)\.($BYTE)\.($BYTE)/;
  return(($1 << 24) | ($2 << 16) | ($3 << 8) | $4);
}


=head2 integer2ip($integer)

Convert a 4 byte integer value into a human readable (byte notated) ip address.

=cut
sub integer2ip {
  my $integer = shift;
  my $ip;
  $ip  =        (($integer >> 24) & 0x000000FF);
  $ip .=  '.' . (($integer >> 16) & 0x000000FF);
  $ip .=  '.' . (($integer >>  8) & 0x000000FF);
  $ip .=  '.' . ( $integer        & 0x000000FF);
  return $ip;
}


=head2 prefix_match($network, $mask, $lessequal, $greaterequal, $prefix)

Returns TRUE if I<$prefix> matches all of the given criterias.

=cut
sub prefix_match {
  my($network_txt, $mask_txt, $le, $ge, $prefix_txt) = @_;
  return FALSE if check_prefix($prefix_txt) < 0;
  $prefix_txt =~ /^([^\/]+)\/(\d+)$/;
  my $network  = ip2integer($network_txt);
  my $mask     = ip2integer($mask_txt);
  my $network2 = ip2integer($1);
  my $pfxlen   = $2;
  my $mask2    = ip2integer(pfxlen2mask($pfxlen));
  
  return ($network != $network2 and $mask != $mask2) if !$le and !$ge;
  
  my $match = ($network & $mask) == ($network2 & $mask);
  return $match && ($pfxlen <= $le) && ($pfxlen >= $ge);
}


=head2 get_remote_ip_from_local_ip($local)

Given an IP address from a /30 network, this function returns the IP
address of the remote site.
If the IP address is invalid, the function returns FALSE.

=cut
sub get_remote_ip_from_local_ip {
  my($local) = @_;
  return FALSE if check_ip($local) < 0;
  my $localint  = ip2integer($local);
  my $mask      = ip2integer(pfxlen2mask(30));
  my $network   = $localint & $mask;
  return FALSE if $local == $network;
  my $remoteint = $network + 1;
  $remoteint = $localint + 1 if $remoteint == $localint;
  return integer2ip($remoteint);
}


=head1 COPYRIGHT

Copyright (c) 2004 Samuel Abels, Ronny Weinreich.
All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Samuel Abels <spam debain org>
Ronny Weinreich <rw AD nmc-m dtag de>

=cut

1;

__END__
