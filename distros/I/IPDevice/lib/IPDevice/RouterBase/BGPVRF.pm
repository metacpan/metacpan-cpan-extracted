#!/usr/bin/env perl
####
## This file provides a class for holding informations regarding a BGP VRF.
####

package RouterBase::BGPVRF;
use RouterBase::Atom;
use RouterBase::BGPNeighbor;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase::BGPVRF

=head1 SYNOPSIS

 use RouterBase::BGPVRF;
 my $vrf = new RouterBase::BGPVRF;
 $vrf->set_name('NeighborName');
 my $neigh = $vrf->add_neighbor('192.168.0.2');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a BGP VRF.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: The VRF name.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new bgp VRF.
##
sub _init {
  my($self, %args) = @_;
  $self->{name} = $args{name} if $args{name};
  return $self;
}


=head2 set_name($name)

Set the BGP BGPVRF name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the BGP VRF name.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_description($description)

Set the BGP VRF description.

=cut
sub set_description {
  my($self, $description) = @_;
  $self->{description} = $description;
}


=head2 get_description()

Returns the BGP VRF description.

=cut
sub get_description {
  my $self = shift;
  return $self->{description};
}


=head2 neighbor($ip)

Returns the BGP neighbor with the given IP. If the neighbor does not exist yet,
a newly created L<RouterBase::BGPNeighbor|RouterBase::BGPNeighbor> will be
returned.

=cut
sub neighbor {
  my($self, $ip) = @_;
  #print "DEBUG: RouterBase::BGPVRF::neighbor(): Called. ($ip)\n";
  return $self->{neighbors}->{$ip} if $self->{neighbors}->{$ip};
  my $neigh = new RouterBase::BGPNeighbor;
  $neigh->set_toplevel($self->toplevel);
  $neigh->set_parent($self->parent);
  $neigh->set_ip($ip);
  return $self->{neighbors}->{$ip} = $neigh;
}


=head2 foreach_neighbor($func, $data)

Walks through all BGP neighbors calling the function $func.
Args passed to $func are:

I<$neighbor>: The L<RouterBase::BGPNeighbor|RouterBase::BGPNeighbor>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the neighbor list evaluation will be stopped.

=cut
sub foreach_neighbor {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::BGPVRF::foreach_neighbor(): Called.\n";
  for my $neighborip (sort {$a <=> $b} keys %{$self->{neighbors}}) {
    my $neighbor = $self->{neighbors}->{$neighborip};
    #print "DEBUG: RouterBase::BGPVRF::foreach_neighbor(): NeighIP $neighborip\n";
    return FALSE if !$func->($neighbor, %data);
  }
  return TRUE;
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
