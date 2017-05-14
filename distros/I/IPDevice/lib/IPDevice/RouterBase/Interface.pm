#!/usr/bin/env perl
####
## This file provides a class for holding informations about a router
## interface.
####

package IPDevice::RouterBase::Interface;
use IPDevice::RouterBase::Atom;
use IPDevice::RouterBase::LogicalInterface;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom IPDevice::RouterBase::LogicalInterface);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::Interface

=head1 SYNOPSIS

 use IPDevice::RouterBase::Interface;
 my $interface = new IPDevice::RouterBase::Interface(name => '0/1/2');
 $interface->set_ip('192.168.0.1', '255.255.255.252');
 $interface->set_encapsulation('ppp');
 
 my($ip, $mask) = $interface->get_ip();

=head1 DESCRIPTION

This module provides routines for storing informations regarding an IP router
interface. If you have a logical interface, use the
L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface> implementation
instead.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: Store the interface name in the initial object.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new interface.
##
sub _init {
  my($self, %args) = @_;
  $self->set_name($args{name}) if $args{name};
  $self->set_active(1);
  $self->set_pfxlen(32);
  $self->set_duplex('full');
  return $self;
}


=head2 set_encapsulation($encapsulation)

Save the interface encapsulation.

=cut
sub set_encapsulation {
  my($self, $encap) = @_;
  $self->{encap} = $encap;
}


=head2 get_encapsulation()

Returns the interface encapsulation.

=cut
sub get_encapsulation {
  my $self = shift;
  return $self->{encap};
}


=head2 set_duplex($duplex)

Safe the interface duplex status.
Valid values for $duplex are 'half' or 'full'. Any other value will be
translated to 'unknown'.

=cut
sub set_duplex {
  my($self, $duplex) = @_;
  $self->{duplex} = 'full', return if $duplex =~ /^full$/i;
  $self->{duplex} = 'half', return if $duplex =~ /^half$/i;
  $self->{duplex} = 'unknown';
}


=head2 get_duplex()

Returns the interface duplex status ('half', 'full', 'unknown' or undef).

=cut
sub get_duplex {
  my $self = shift;
  return $self->{duplex};
}


=head2 set_dsubandwidth($dsubandwidth)

Safe the interface's configured dsu-bandwidth.

=cut
sub set_dsubandwidth {
  my($self, $dsubandwidth) = @_;
  $self->{dsubandwidth} = $dsubandwidth;
}


=head2 get_dsubandwidth()

Returns the interface's configured dsu-bandwidth.

=cut
sub get_dsubandwidth {
  my $self = shift;
  return $self->{dsubandwidth};
}


=head2 set_crc($crc)

Safe the interface crc length. $crc must be an integer value.

=cut
sub set_crc {
  my($self, $crc) = @_;
  $self->{crc} = $crc * 1;
}


=head2 get_crc()

Returns the interface crc length as an integer value.

=cut
sub get_crc {
  my $self = shift;
  return $self->{crc};
}


=head2 unit()

Returns the L<IPDevice::RouterBase::LogicalInterface|IPDevice::RouterBase::LogicalInterface> with
the given number. If it does not exist yet, it will be created.

=cut
sub unit {
  my($self, $unit) = @_;
  return $self->{units}->{$unit} if $self->{units}->{$unit};
  $self->{units}->{$unit} = new IPDevice::RouterBase::LogicalInterface(name => $unit);
  $self->{units}->{$unit}->set_toplevel($self->toplevel);
  $self->{units}->{$unit}->set_parent($self->parent);
  return $self->{units}->{$unit};
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
  for my $unitno (sort {$a <=> $b} keys %{$self->{units}}) {
    my $unit = $self->{units}->{$unitno};
    #print "DEBUG: IPDevice::RouterBase::Interface::foreach_unit(): Unit $unitno\n";
    return FALSE if !$func->($unit, %data);
  }
  return TRUE;
}


=head2 print_data()

Prints all data regarding the interface to STDOUT (e.g. for debugging).

=cut
sub print_data {
  my $self = shift;
  print "Interface Name:          ", $self->get_name, "\n";
  my($ip, $mask) = $self->get_ip;
  print "Interface IP/Mask:       $ip/$mask\n";
  print "Interface Unnumbered:    ", $self->get_unnumberedint, "\n";
  print "Interface Description:   ", $self->get_description,   "\n";
  print "Interface Encapsulation: ", $self->get_encapsulation, "\n";
  print "Interface Ratelimit:     ", $self->get_ratelimit,     "\n";
  print "Interface Duplex:        ", $self->get_duplex,        "\n";
  print "Interface Bandwidth:     ", $self->get_bandwidth,     "\n";
  print "Interface DSU-Bandwidth: ", $self->get_dsubandwidth,  "\n";
  print "Interface CRC length:    ", $self->get_crc,           "\n";
  print "Interface ISIS Status:   ", $self->get_isis_active,   "\n";
  print "Interface ISIS Level:    ", $self->get_isis_level,    "\n";
  print "Interface ISIS Metric:   ", $self->get_isis_metric,   "\n";
  print "Interface Flowsampling:  ", $self->get_routecache_flowsampling, "\n";
  print "Interface Status:        ", $self->get_active,        "\n";
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
