#!/usr/bin/env perl
####
## This file provides a class for holding informations regarding ISIS.
####

package IPDevice::RouterBase::ISIS;
use IPDevice::RouterBase::Atom;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::ISIS

=head1 SYNOPSIS

 use IPDevice::RouterBase::ISIS;
 my $isis = new IPDevice::RouterBase::ISIS;
 $isis->set_level(1);

=head1 DESCRIPTION

This module provides a base class, providing routines for storing informations
regarding an ISIS instance of a router.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new ISIS instance.
##
sub _init {
  my($self, %args) = @_;
  $self->{level}  = 1;
  $self->{active} = 1;
  return $self;
}


=head2 set_active($active)

Defines whether ISIS is active (BOOLEAN).

=cut
sub set_active {
  my($self, $active) = @_;
  $self->{active} = $active;
}


=head2 get_active()

Returns whether ISIS is active (BOOLEAN).

=cut
sub get_active {
  my $self = shift;
  return $self->{active};
}


=head2 set_level($level)

Defines the ISIS level.

=cut
sub set_level {
  my($self, $level) = @_;
  $self->{level} = $level;
}


=head2 get_level()

Returns the ISIS level.

=cut
sub get_level {
  my $self = shift;
  return $self->{level};
}


=head2 set_network($network)

Defines the ISIS network address (ISO).

=cut
sub set_network {
  my($self, $network) = @_;
  $self->{network} = $network;
}


=head2 get_network()

Returns ISIS network address (ISO).

=cut
sub get_network {
  my $self = shift;
  return $self->{network};
}


=head2 print_data()

Prints all ISIS informations to STDOUT.

=cut
sub print_data {
  my $self = shift;
  print "ISIS status:          ", $self->get_active(),  "\n";
  print "ISIS level:           ", $self->get_level(),   "\n";
  print "ISIS network address: ", $self->get_network(), "\n";
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
