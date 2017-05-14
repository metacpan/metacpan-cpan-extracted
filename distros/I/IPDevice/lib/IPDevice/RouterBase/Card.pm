#!/usr/bin/env perl
####
## This file provides a class for holding informations about a router card.
####

package IPDevice::RouterBase::Card;
use IPDevice::RouterBase::Atom;
use IPDevice::RouterBase::Module;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::Card

=head1 SYNOPSIS

 use IPDevice::RouterBase::Card;
 my $card = new IPDevice::RouterBase::Card;
 $card->module(1)->interface(2)->set_encapsulation('ppp');

=head1 DESCRIPTION

This module provides routines for storing informations regarding an IP router
card.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: Store the card name in the initial object.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new card.
##
sub _init {
  my($self, %args) = @_;
  $self->set_memory_size(0);
  $self->set_linememory_size(0);
  return $self;
}


=head2 set_number($number)

Defines the card number. When created via any class from the IPDevice::RouterBase
namespace, this is automatically set.

=cut
sub set_number {
  my($self, $number) = @_;
  $self->{number} = $number;
}


=head2 get_number()

Returns the card number.

=cut
sub get_number {
  my $self = shift;
  return $self->{number};
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


=head2 set_speed($speed)

Defines the card's interface speed.

=cut
sub set_speed {
  my($self, $speed) = @_;
  $self->{speed} = $speed;
}


=head2 get_speed()

Returns the card's speed.

=cut
sub get_speed {
  my $self = shift;
  return $self->{speed};
}


=head2 set_memory_size($memorysize)

Defines the card's memory size.

=cut
sub set_memory_size {
  my($self, $memorysize) = @_;
  $self->{memorysize} = $memorysize;
}


=head2 get_memory_size()

Returns the card's memory size.

=cut
sub get_memory_size {
  my $self = shift;
  return $self->{memorysize};
}


=head2 set_linememory_size($memorysize)

Defines the card's line-memory size.

=cut
sub set_linememory_size {
  my($self, $linememorysize) = @_;
  $self->{linememorysize} = $linememorysize;
}


=head2 get_linememory_size()

Returns the card's line-memory size.

=cut
sub get_linememory_size {
  my $self = shift;
  return $self->{linememorysize};
}


=head2 set_serialnumber($serialumber)

Defines the card's serial number.

=cut
sub set_serialnumber {
  my($self, $serialnumber) = @_;
  $self->{serialnumber} = $serialnumber;
}


=head2 get_serialnumber()

Returns the card's serial number.

=cut
sub get_serialnumber {
  my $self = shift;
  return $self->{serialnumber};
}


=head2 set_partnumber($partnumber)

Defines the card vendor's part number.

=cut
sub set_partnumber {
  my($self, $partnumber) = @_;
  $self->{partnumber} = $partnumber;
}


=head2 get_partnumber()

Returns the card vendor's part number.

=cut
sub get_partnumber {
  my $self = shift;
  return $self->{partnumber};
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


=head2 set_processor($processor)

Defines the processor type.

=cut
sub set_processor {
  my($self, $processor) = @_;
  $self->{processor} = $processor;
}


=head2 get_processor()

Returns the processor type.

=cut
sub get_processor {
  my $self = shift;
  return $self->{processor};
}


=head2 set_slave($speed)

Defines whether the card is slave.

=cut
sub set_slave {
  my($self, $slave) = @_;
  $self->{slave} = $slave;
}


=head2 get_slave()

Returns whether the card is slave.

=cut
sub get_slave {
  my $self = shift;
  return $self->{slave};
}


=head2 set_slot_size($slotnumber, $size)

Defines the slot size of the slot with the given number.

=cut
sub set_slot_size {
  my($self, $slotnumber, $size) = @_;
  $self->{"slotsize-$slotnumber"} = $size;
}


=head2 get_slot_size($slotnumber)

Returns the slot size for the slot with the given number.

=cut
sub get_slot_size {
  my($self, $slotnumber) = @_;
  return $self->{"slotsize-$slotnumber"};
}


=head2 set_slot_content($slotnumber, $content)

Defines a string describing the slot content for the slot with the given number.

=cut
sub set_slot_content {
  my($self, $slotnumber, $content) = @_;
  $self->{"slotcontent-$slotnumber"} = $content;
}


=head2 get_slot_content($slotnumber)

Returns a string describing the slot content for the slot with the given number.

=cut
sub get_slot_content {
  my($self, $slotnumber) = @_;
  return $self->{"slotcontent-$slotnumber"};
}


=head2 set_bootimage($bootimage)

Defines the active boot image.

=cut
sub set_bootimage {
  my($self, $bootimage) = @_;
  $self->{bootimage} = $bootimage;
}


=head2 get_bootimage()

Returns the active boot image.

=cut
sub get_bootimage {
  my $self = shift;
  return $self->{bootimage};
}


=head2 module($modulenumber)

Returns the module with the given number. If it doesn't exist, it will be
created.
If no module number is given, a virtual module will be returned.
You can, for example, add interfaces that do not have a pysical module
there.

=cut
sub module {
  my($self, $moduleno) = @_;
  $moduleno = -1 if !defined $moduleno;
  my $module = $self->{modules}->{$moduleno};
  if (!$module) {
    $module = new IPDevice::RouterBase::Module;
    $module->set_toplevel($self->toplevel);
    $module->set_parent($self->parent);
    $module->set_number($moduleno);
    $self->{modules}->{$moduleno} = $module;
  }
  return $module;
}


=head2 interface($interfacenumber)

Returns the interface with the given number. If it doesn't exist, it will be
created. Returns undef only on an error.

=cut
sub interface {
  my($self, $interfaceno) = @_;
  my $moduleno;
  $moduleno = $1 if $interfaceno =~ /^(\d+\/\d+)\/\d+/;
  $moduleno = $1 if $interfaceno =~ /^(\d+)\/\d+$/;
  $moduleno = -1 if $interfaceno =~ /^\d+$/;
  return if !defined $moduleno;
  
  my $module = $self->{modules}->{$moduleno};
  if (!$module) {
    $module = new IPDevice::RouterBase::Module;
    $module->set_name($moduleno);
    $self->{modules}->{$moduleno} = $module;
  }
  
  return $module->interface($interfaceno);
}


=head2 foreach_module($func, %data)

Walks through all modules calling the function $func.
Args passed to $func are:

I<$module>: The L<IPDevice::RouterBase::Module|IPDevice::RouterBase::Module>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_module {
  my($self, $func, %data) = @_;
  for my $moduleno (keys %{$self->{modules}}) {
    my $module = $self->{modules}->{$moduleno};
    #print "DEBUG: IPDevice::RouterBase::Card::foreach_module(): Module $moduleno\n";
    return FALSE if !$func->($module, %data);
  }
  return TRUE;
}


=head2 foreach_interface($func, %data)

Walks through all interfaces calling the function $func.
Args passed to $func are:

I<$interface>: The L<IPDevice::RouterBase::Interface|IPDevice::RouterBase::Interface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_interface {
  my($self, $func, %data) = @_;
  for my $moduleno (sort {$a <=> $b} keys %{$self->{modules}}) {
    my $module = $self->{modules}->{$moduleno};
    #print "DEBUG: IPDevice::RouterBase::Card::foreach_interface(): Module $moduleno\n";
    return FALSE if !$module->foreach_interface($func, %data);
  }
  return TRUE;
}


=head2 foreach_unit($func, %data)

Walks through all L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface>
calling the function $func. Args passed to $func are:

I<$unit>: The L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_unit {
  my($self, $func, %data) = @_;
  for my $moduleno (sort {$a <=> $b} keys %{$self->{modules}}) {
    my $module = $self->{modules}->{$moduleno};
    #print "DEBUG: IPDevice::RouterBase::Card::foreach_unit(): Module $moduleno\n";
    return FALSE if !$module->foreach_unit($func, %data);
  }
  return TRUE;
}


=head2 print_data()

Prints all data regarding the card to STDOUT (e.g. for debugging).

=cut
sub print_data {
  my $self = shift;
  print "Card number:          ", $self->get_number,          "\n";
  print "Card type:            ", $self->get_type,            "\n";
  print "Card description:     ", $self->get_description,     "\n";
  print "Card serialno.:       ", $self->get_serialnumber,    "\n";
  print "Card memory:          ", $self->get_memory_size,     "\n";
  print "Card line-memory:     ", $self->get_linememory_size, "\n";
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
