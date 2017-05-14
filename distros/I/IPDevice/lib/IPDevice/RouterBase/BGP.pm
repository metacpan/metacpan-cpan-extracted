#!/usr/bin/env perl
####
## This file provides a class for holding informations regarding a BGP instance.
####

package IPDevice::RouterBase::BGP;
use IPDevice::RouterBase::Atom;
use IPDevice::RouterBase::BGPGroup;
use IPDevice::RouterBase::BGPVRF;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom IPDevice::RouterBase::BGPVRF);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::BGP

=head1 SYNOPSIS

 use IPDevice::RouterBase::BGP;
 my $bgp = new IPDevice::RouterBase::BGP;
 $bgp->set_localas(1234);
 my $vrf   = $bgp->vrf('9999');
 my $neigh = $bgp->add_neighbor('192.168.0.2');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a BGP instance.

=head1 CONSTRUCTOR AND METHODS

This module provides, in addition to all methods from
L<IPDevice::RouterBase::BGPVRF|IPDevice::RouterBase::BGPVRF>, the following methods.

=cut


## Purpose: Initialize a new BGP instance.
##
sub _init {
  my($self, %args) = @_;
  $self->{localas} = $args{localas} if $args{localas};
  return $self;
}


=head2 set_localas($localas)

Set the BGP local AS number. (INTEGER)

=cut
sub set_localas {
  my($self, $localas) = @_;
  $self->{localas} = $localas * 1;
}


=head2 get_localas()

Returns the BGP local AS number. (INTEGER)

=cut
sub get_localas {
  my $self = shift;
  return $self->{localas};
}


=head2 set_routerid($routerid)

Set the BGP router id.

=cut
sub set_routerid {
  my($self, $routerid) = @_;
  $self->{routerid} = $routerid;
}


=head2 get_routerid()

Returns the BGP router id.

=cut
sub get_routerid {
  my $self = shift;
  return $self->{routerid};
}


=head2 group($name)

Returns the L<IPDevice::RouterBase::BGPGroup|IPDevice::RouterBase::BGPGroup> with the given name.
If the group does not exist yet, a newly created
L<IPDevice::RouterBase::BGPGroup|IPDevice::RouterBase::BGPGroup> will be returned.

=cut
sub group {
  my($self, $name) = @_;
  #print "DEBUG: IPDevice::RouterBase::BGP::group(): Called. ($name)\n";
  return $self->{groups}->{$name} if $self->{groups}->{$name};
  my $group = new IPDevice::RouterBase::BGPGroup;
  $group->set_toplevel($self->toplevel);
  $group->set_parent($self->parent);
  $group->set_name($name);
  return $self->{groups}->{$name} = $group;
}


=head2 vrf($vrfname)

Returns the L<IPDevice::RouterBase::BGPVRF|IPDevice::RouterBase::BGPVRF> with the given name, or,
if none found, a new L<IPDevice::RouterBase::BGPVRF|IPDevice::RouterBase::BGPVRF>.

=cut
sub vrf {
  my($self, $vrfname) = @_;
  #print "DEBUG: IPDevice::RouterBase::BGPVRF::vrf(): Called. ($vrfname)\n";
  return $self->{vrfs}->{$vrfname} if $self->{vrfs}->{$vrfname};
  $self->{vrfs}->{$vrfname} = new IPDevice::RouterBase::BGPVRF(name => $vrfname);
  $self->{vrfs}->{$vrfname}->set_toplevel($self->toplevel);
  $self->{vrfs}->{$vrfname}->set_parent($self->parent);
  return $self->{vrfs}->{$vrfname};
}


=head2 foreach_vrf($func, $data)

Walks through all VRFs calling the function $func.
Args passed to $func are:

I<$vrf>: The L<IPDevice::RouterBase::BGPVRF|IPDevice::RouterBase::BGPVRF>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the VRF list evaluation will be stopped.

=cut
sub foreach_vrf {
  my($self, $func, %data) = @_;
  #print "DEBUG: IPDevice::RouterBase::BGP::foreach_vrf(): Called.\n";
  for my $vrfname (sort {$a <=> $b} keys %{$self->{vrfs}}) {
    my $vrf = $self->{vrfs}->{$vrfname};
    #print "DEBUG: IPDevice::RouterBase::BGP::foreach_vrf(): VRF $vrfname\n";
    return FALSE if !$func->($vrf, %data);
  }
  return TRUE;
}


=head2 foreach_neighbor($func, $data)

Walks through all VRFs/BGP neighbors calling the function $func.
Args passed to $func are:

I<$neighbor>: The L<IPDevice::RouterBase::BGPNeighbor|IPDevice::RouterBase::BGPNeighbor>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the neighbor list evaluation will be stopped.

=cut
sub foreach_neighbor {
  my($self, $func, %data) = @_;
  #print "DEBUG: IPDevice::RouterBase::BGP::foreach_neighbor(): Called.\n";
  for my $vrfname (sort {$a <=> $b} keys %{$self->{vrfs}}) {
    my $vrf = $self->{vrfs}->{$vrfname};
    #print "DEBUG: IPDevice::RouterBase::BGP::foreach_neighbor(): VRF $vrfname\n";
    return FALSE if !$vrf->foreach_neighbor($func, %data);
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
