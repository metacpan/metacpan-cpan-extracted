#!/usr/bin/env perl
####
## This file provides a class for holding informations about a router module.
####

package IPDevice::RouterBase::Module;
use IPDevice::RouterBase::Atom;
use IPDevice::RouterBase::Interface;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::Module

=head1 SYNOPSIS

 use IPDevice::RouterBase::Module;
 my $module = new IPDevice::RouterBase::Module;
 $module(0)->interface(1)->set_encapsulation('ppp');

=head1 DESCRIPTION

This module provides routines for storing informations regarding an IP router
module.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: Store the module name in the initial object.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new router module.
##
sub _init {
  my($self, %args) = @_;
  $self->set_name($args{name}) if $args{name};
  return $self;
}


=head2 set_name($name)

Set the module name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the module name.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_description($description)

Defines the card description.

=cut
sub set_description {
  my($self, $description) = @_;
  $self->{description} = $description;
}


=head2 get_description()

Returns the card description.

=cut
sub get_description {
  my $self = shift;
  return $self->{description};
}


=head2 set_number($name)

Defines the module number. When created via any class from the IPDevice::RouterBase
namespace, this is automatically set.

=cut
sub set_number {
  my($self, $number) = @_;
  $self->{number} = $number;
}


=head2 get_number()

Returns the module number.

=cut
sub get_number {
  my $self = shift;
  return $self->{number};
}


=head2 set_serialnumber($serialumber)

Defines the card's memory size.

=cut
sub set_serialnumber {
  my($self, $serialnumber) = @_;
  $self->{serialnumber} = $serialnumber;
}


=head2 get_serialnumber()

Returns the card's memory size.

=cut
sub get_serialnumber {
  my $self = shift;
  return $self->{serialnumber};
}


=head2 set_type($type)

Defines the card type.

=cut
sub set_type {
  my($self, $type) = @_;
  $self->{type} = $type;
}


=head2 get_type()

Returns the card type.

=cut
sub get_type {
  my $self = shift;
  return $self->{type};
}


=head2 interface($interfacenumber)

Returns the interface with the given number. If it doesn't exist yet, it will
be created.

=cut
sub interface {
  my($self, $intno) = @_;
  my $iface = $self->{interfaces}->{$intno};
  if (!$iface) {
    $iface = new IPDevice::RouterBase::Interface(name => $intno);
    $iface->set_toplevel($self->toplevel);
    $iface->set_parent($self->parent);
    $iface->set_name($intno);  # Set a default name.
    $self->{interfaces}->{$intno} = $iface;
  }
  return $iface;
}


=head2 foreach_interface($func, $data)

Walks through all interfaces calling the function $func.
Args passed to $func are:

I<$interface>: The L<IPDevice::RouterBase::Interface|IPDevice::RouterBase::Interface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped and the function returns
FALSE.

=cut
sub foreach_interface {
  my($self, $func, %data) = @_;
  for my $intno (sort {$a <=> $b} keys %{$self->{interfaces}}) {
    my $iface = $self->{interfaces}->{$intno};
    #print "DEBUG: IPDevice::RouterBase::Module::foreach_interface(): Iface $intno\n";
    return FALSE if !$func->($iface, %data);
  }
  return TRUE;
}


=head2 foreach_unit($func, $data)

Walks through all L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface>
calling the function $func. Args passed to $func are:

I<$unit>: The L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_unit {
  my($self, $func, %data) = @_;
  for my $intno (sort {$a <=> $b} keys %{$self->{interfaces}}) {
    my $int = $self->{interfaces}->{$intno};
    #print "DEBUG: IPDevice::RouterBase::Module::foreach_unit(): Interface $intno\n";
    return FALSE if !$int->foreach_unit($func, %data);
  }
  return TRUE;
}


=head2 print_data()

Prints all data regarding the module to STDOUT (e.g. for debugging).

=cut
sub print_data {
  my $self = shift;
  print "Module number:          ", $self->get_number,         "\n";
  print "Module type:            ", $self->get_type,           "\n";
  print "Module description:     ", $self->get_description,    "\n";
  print "Module serialno.:       ", $self->get_serialnumber,   "\n";
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
