#!/usr/bin/env perl
####
## This file provides a base class for holding informations regarding a BGP
## neighbor.
####

package RouterBase::BGPNeighbor;
use RouterBase::Atom;
use IPv4;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase::BGPNeighbor

=head1 SYNOPSIS

 use RouterBase::BGPNeighbor;
 my $neigh = new RouterBase::BGPNeighbor;
 $neigh->set_name('Neighbor Name');
 $neigh->set_ip('192.168.0.2');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a BGP neighbor.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: The neighbor name.
I<ip>:   The neighbor ip.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new bgp neighbor.
##
sub _init {
  my($self, %args) = @_;
  $self->{name}       = $args{name} if $args{name};
  $self->{ip}         = $args{ip}   if $args{ip};
  $self->{mhdistance} = 1;
  $self->{active}     = 1;
  return $self;
}


=head2 set_name($name)

Set the BGP neighbor name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the BGP neighbor name.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_groupname($name)

Set the BGP group name.

=cut
sub set_groupname {
  my($self, $name) = @_;
  $self->{groupname} = $name;
}


=head2 get_groupname()

Returns the BGP group name.

=cut
sub get_groupname {
  my $self = shift;
  return $self->{groupname};
}


=head2 set_description($description)

Set the BGP neighbor description.

=cut
sub set_description {
  my($self, $description) = @_;
  $self->{description} = $description;
}


=head2 get_description()

Returns the BGP neighbor description.

=cut
sub get_description {
  my $self = shift;
  return $self->{description};
}


=head2 set_ip($ip)

Checks & sets the neighbor IP address.
Returns FALSE if the ip is invalid, otherwise TRUE.

=cut
sub set_ip {
  my($self, $ip) = @_;
  return FALSE if IPv4::check_ip($ip) != 0;
  $self->{ip} = $ip;
  return TRUE;
}


=head2 get_ip()

Returns the neighbor IP address.

=cut
sub get_ip {
  my($self) = @_;
  return $self->{ip};
}


=head2 set_as($as)

Set the BGP neighbor AS number. (INTEGER)

=cut
sub set_as {
  my($self, $as) = @_;
  #print "DEBUG: BGPNeighbor::set_as(): Called.\n";
  $self->{as} = $as * 1;
}


=head2 get_as()

Returns the BGP neighbor AS number. (INTEGER)

=cut
sub get_as {
  my $self = shift;
  return $self->{as};
}


=head2 set_multihop($distance)

Set the BGP neighbor eBGP multihop distance. (INTEGER)

=cut
sub set_multihop {
  my($self, $distance) = @_;
  $self->{mhdistance} = $distance * 1;
}


=head2 get_multihop()

Returns the BGP neighbor eBGP multihop distance. (INTEGER)

=cut
sub get_multihop {
  my $self = shift;
  return $self->{mhdistance};
}


=head2 set_nhs($yesno)

Define, whether or not to use BGP next-hop-self. (BOOLEAN)

=cut
sub set_nhs {
  my($self, $yesno) = @_;
  $self->{nhs} = $yesno * 1;
}


=head2 get_nhs()

Returns whether or not to use BGP next-hop-self. (BOOLEAN)

=cut
sub get_nhs {
  my $self = shift;
  return $self->{nhs};
}


=head2 set_updatesource($updatesource)

Defines the BGP session update source.

=cut
sub set_updatesource {
  my($self, $updatesource) = @_;
  $self->{updatesource} = $updatesource;
}


=head2 get_updatesource()

Returns the BGP session update source.

=cut
sub get_updatesource {
  my $self = shift;
  return $self->{updatesource};
}


=head2 set_softreconf_in($onoff)

Set whether inbound soft-reconfiguration is enabled. (BOOLEAN)

=cut
sub set_softreconf_in {
  my($self, $onoff) = @_;
  $self->{softreconf_in} = $onoff * 1;
}


=head2 get_softreconf_in()

Returns whether inbound soft-reconfiguration is enabled. (BOOLEAN)

=cut
sub get_softreconf_in {
  my $self = shift;
  return $self->{softreconf_in};
}


=head2 set_softreconf_out($onoff)

Set whether outbound soft-reconfiguration is enabled. (BOOLEAN)

=cut
sub set_softreconf_out {
  my($self, $onoff) = @_;
  $self->{softreconf_out} = $onoff * 1;
}


=head2 get_softreconf_out()

Returns whether outbound soft-reconfiguration is enabled. (BOOLEAN)

=cut
sub get_softreconf_out {
  my $self = shift;
  return $self->{softreconf_out};
}


=head2 set_active($yesno)

Define, whether or not the neigbor is enabled. (BOOLEAN)

=cut
sub set_active {
  my($self, $yesno) = @_;
  $self->{active} = $yesno * 1;
}


=head2 get_active()

Returns whether or not the neigbor is enabled. (BOOLEAN)

=cut
sub get_active {
  my $self = shift;
  return $self->{active};
}


=head2 print_data()

Prints the BGP neighbor's data out.

=cut
sub print_data {
  my $self = shift;
  print "Neighbor IP:                ", $self->get_ip(),             "\n";
  print "Neighbor AS:                ", $self->get_as(),             "\n";
  print "Neighbor name:              ", $self->get_name(),           "\n";
  print "Neighbor description:       ", $self->get_description(),    "\n";
  print "Neighbor group:             ", $self->get_groupname(),      "\n";
  print "Neighbor multihop distance: ", $self->get_multihop(),       "\n";
  print "Neighbor NHS:               ", $self->get_nhs(),            "\n";
  print "Neighbor soft-reconfig-in:  ", $self->get_softreconf_in(),  "\n";
  print "Neighbor soft-reconfig-out: ", $self->get_softreconf_out(), "\n";
  print "Neighbor active:            ", $self->get_active(),         "\n";
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
