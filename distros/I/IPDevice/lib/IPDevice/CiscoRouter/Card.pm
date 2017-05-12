#!/usr/bin/env perl
####
## This file provides a base class for holding informations regarding a Cisco
## card.
####

package IPDevice::CiscoRouter::Card;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Card);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::CiscoRouter::Card

=head1 SYNOPSIS

 use IPDevice::CiscoRouter::Card;
 my $card = new IPDevice::CiscoRouter::Card;
 $card->module(1)->interface(2)->set_encapsulation('ppp');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a Cisco Router
card.

=head1 CONSTRUCTOR AND METHODS

This class provides, in addition to all methods from
L<IPDevice::RouterBase::Card|IPDevice::RouterBase::Card>, the following methods.

=head2 set_l3engine($name)

Defines the l3 engine name.

=cut
sub set_l3engine {
  my($self, $name) = @_;
  $self->{l3engine} = $name;
}


=head2 get_l3engine()

Returns the l3 engine name.

=cut
sub get_l3engine {
  my $self = shift;
  return $self->{l3engine};
}


=head2 set_rommon($rommon)

Defines the rom monitor type.

=cut
sub set_rommon {
  my($self, $rommon) = @_;
  $self->{rommon} = $rommon;
}


=head2 get_rommon()

Returns the rom monitor type.

=cut
sub get_rommon {
  my $self = shift;
  return $self->{rommon};
}


=head2 set_fabric($fabric)

Defines the fabric type.

=cut
sub set_fabric {
  my($self, $fabric) = @_;
  $self->{fabric} = $fabric;
}


=head2 get_fabric()

Returns the fabric type.

=cut
sub get_fabric {
  my $self = shift;
  return $self->{fabric};
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
