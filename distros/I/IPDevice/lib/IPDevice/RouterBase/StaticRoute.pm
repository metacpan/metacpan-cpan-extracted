#!/usr/bin/env perl
####
## This file provides a class for holding informations about a prefixlist
## entry.
####

package IPDevice::RouterBase::StaticRoute;
use IPDevice::RouterBase::Atom;
use IPDevice::IPv4;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::StaticRoute

=head1 SYNOPSIS

 use IPDevice::RouterBase::StaticRoute;
 my $route = new IPDevice::RouterBase::StaticRoute;
 $route->set_network('192.168.0.0', '255.255.255.0');
 $route->set_destination('10.10.10.1);

=head1 DESCRIPTION

This module provides routines for storing informations regarding a single IP
route.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments: none.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new ip route.
##
sub _init {
  my($self, %args) = @_;
  $self->{network} = 0;
  $self->{mask}    = 0;
  $self->{dest}    = 0;
  return $self;
}


=head2 set_prefix($prefix)

Check & set the IP prefix to be routed.
Returns FALSE if the prefix is invalid, otherwise TRUE.

=cut
sub set_prefix {
  my($self, $prefix) = @_;
  return FALSE if $prefix !~ /^([^\/]+)\/(\d+)$/;
  return FALSE if !IPDevice::IPv4::check_ip($1);
  return FALSE if !IPDevice::IPv4::check_prefixlen($2);
  $self->{network} = $1;
  $self->{mask}    = IPDevice::IPv4::pfxlen2mask($2);
  return TRUE;
}


=head2 get_prefix()

Returns the IP prefix.

=cut
sub get_prefix {
  my $self = shift;
  my $pfxlen = IPDevice::IPv4::mask2pfxlen($self->{mask});
  return "$self->{network}/$pfxlen";
}


=head2 C<set_network($network[, $mask])>

Set the IP network address and, optionally, the mask.

=cut
sub set_network {
  my($self, $network, $mask) = @_;
  return FALSE if !IPDevice::IPv4::check_ip($network);
  $self->{network} = $network;
  $self->{mask}    = $mask if $mask;
  $self->{mask}    = '255.255.255.0' if !$mask;
}


=head2 get_network()

Returns the IP network address.

=cut
sub get_network {
  my $self = shift;
  return $self->{network};
}


=head2 set_mask($mask)

Set the IP mask.

=cut
sub set_mask {
  my($self, $mask) = @_;
  return $self->{mask};
}


=head2 get_mask()

Returns the IP mask.

=cut
sub get_mask {
  my $self = shift;
  return $self->{mask};
}


=head2 set_destination($ip)

Set the destination IP address.
Returns TRUE if the ip is valid, otherwise FALSE.

=cut
sub set_prefixlen {
  my($self, $ip) = @_;
  return FALSE if !IPDevice::IPv4::check_ip($ip);
  $self->{dest} = $ip;
}


=head2 get_destination()

Returns the destination IP address.

=cut
sub get_destination {
  my $self = shift;
  return $self->{dest};
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
