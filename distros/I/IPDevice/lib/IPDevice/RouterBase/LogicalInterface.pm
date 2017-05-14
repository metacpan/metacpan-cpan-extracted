#!/usr/bin/env perl
####
## This file provides a base class for holding informations about a logical
## router interface.
####

package IPDevice::RouterBase::LogicalInterface;
use IPDevice::RouterBase::Atom;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::LogicalInterface

=head1 SYNOPSIS

 use IPDevice::RouterBase::LogicalInterface;
 my $interface = new IPDevice::RouterBase::LogicalInterface(name => '0/1/2');
 $interface->set_ip('192.168.0.1', '255.255.255.252');
 
 my($ip, $mask) = $interface->get_ip();

=head1 DESCRIPTION

This module provides routines for storing informations regarding an logical
IP router interface. If you have a pysical interface, use the
L<IPDevice::RouterBase::Interface|IPDevice::RouterBase::Interface> implementation instead.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: Store the logical interface name in the initial object.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self;
}


## Purpose: Initialize a new interface.
##
sub _init {
  my($self, %args) = @_;
  $self->set_name($args{name}) if $args{name};
  $self->set_pfxlen(32);
  $self->set_active(1);
  return $self;
}


=head2 set_name($name)

Set the logical interface name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the logical interface name.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_description($description)

Returns the interface description.

=cut
sub set_description {
  my($self, $descr) = @_;
  $self->{descr} = $descr;
}


=head2 get_description()

Returns the interface description.

=cut
sub get_description {
  my $self = shift;
  return $self->{descr};
}


=head2 set_active($active)

Safe the interface's enabled status. (BOOLEAN)

=cut
sub set_active {
  my($self, $active) = @_;
  $self->{active} = $active;
}


=head2 get_active()

Returns the interface's enabled status. (BOOLEAN)

=cut
sub get_active {
  my $self = shift;
  return $self->{active};
}


=head2 set_ip($ip, $mask)

Safe the logical interface's primary ip address/mask.

=cut
sub set_ip {
  my($self, $ip, $mask) = @_;
  $self->{ip}   = $ip;
  $self->{mask} = $mask;
}


=head2 get_ip()

Returns the logical interface's primary ip address/mask.

=cut
sub get_ip {
  my $self = shift;
  return($self->{ip}, $self->{mask});
}


=head2 C<set_pfxlen($pfxlen)>

Safe the interface's prefix length.

=cut
sub set_pfxlen {
  my($self, $pfxlen) = @_;
  $self->{mask} = IPDevice::IPv4::pfxlen2mask($pfxlen);
}


=head2 get_pfxlen()

Returns the interface's prefix length.

=cut
sub get_pfxlen {
  my $self = shift;
  return IPDevice::IPv4::mask2pfxlen($self->{mask});
}


=head2 C<push_secondary_ip($ip, $mask)>

Push a secondary ip address to an array.

=cut
sub push_secondary_ip {
  my($self, $ip, $mask) = @_;
  push(@{$self->{secondaryips}}, [ $ip, $mask ] );
}


=head2 get_secondary_ips()

Returns an array of all secondary ip addresses.

=cut
sub get_secondary_ips {
  my $self = shift;
  return @{pop(@{$self->{secondaryips}})};
}


=head2 pop_secondary_ip()

Pop a secondary ip address from an array.

=cut
sub pop_secondary_ip {
  my $self = shift;
  my($ip, $mask) = @{pop(@{$self->{secondaryips}})};
  return($ip, $mask);
}


=head2 C<set_unnumberedint($intname)>

Set the interface name from which the unnumbered IP will be taken.

=cut
sub set_unnumberedint {
  my($self, $intname) = @_;
  $self->{ipunnumbered} = $intname;
}


=head2 C<get_unnumberedint()>

Returns the interface name from which the unnumbered IP will be taken.

=cut
sub get_unnumberedint {
  my($self) = @_;
  return $self->{ipunnumbered};
}


=head2 set_bandwidth($bandwidth)

Safe the interface's configured bandwidth.

=cut
sub set_bandwidth {
  my($self, $bandwidth) = @_;
  $self->{bandwidth} = $bandwidth;
}


=head2 get_bandwidth()

Returns the interface's configured bandwidth.

=cut
sub get_bandwidth {
  my $self = shift;
  return $self->{bandwidth};
}


=head2 set_ratelimit($ratelimit)

Safe the interface ratelimit.

=cut
sub set_ratelimit {
  my($self, $ratelimit) = @_;
  $self->{ratelimit} = $ratelimit;
}


=head2 get_ratelimit()

Returns the interface ratelimit.

=cut
sub get_ratelimit {
  my $self = shift;
  return $self->{ratelimit};
}


=head2 set_isis_active($status)

Safe the interface's isis status. (BOOLEAN)

=cut
sub set_isis_active {
  my($self, $status) = @_;
  $self->{isis} = $status;
}


=head2 get_isis_active()

Returns the interface's isis status. (BOOLEAN)

=cut
sub get_isis_active {
  my $self = shift;
  return $self->{isis};
}


=head2 set_isis_level($level)

Safe the interface's isis level. ('1', '2', '3' or '1-2', where 3 will be
translated into '1-2')

=cut
sub set_isis_level {
  my($self, $level) = @_;
  $level = '1-2' if $level == 3;
  $self->{isislevel} = $level     if $level eq '1-2';
  $self->{isislevel} = $level * 1 if $level >= 1 and $level < 3;
}


=head2 get_isis_level()

Returns the interface's isis level. ('1', '2' or '1-2')

=cut
sub get_isis_level {
  my $self = shift;
  return $self->{isislevel};
}


=head2 C<set_isis_metric($level, $metric)>

Safe the interface's isis metric for the given isis level.
I<$metric> must be an integer value.

=cut
sub set_isis_metric {
  my($self, $level, $metric) = @_;
  return if !$level;
  $self->{isisl1metric} = $metric if $level =~ /1/;
  $self->{isisl2metric} = $metric if $level =~ /2/;
}


=head2 get_isis_metric($level)

Returns the interface's isis metric for the given isis level.
Valid values for I<$level> are '1' and '2'.

=cut
sub get_isis_metric {
  my($self, $level) = @_;
  return $self->{"isisl${level}metric"};
}


=head2 set_isis_passive($status)

Defines, whether the interface is isis-passive. (BOOLEAN)

=cut
sub set_isis_passive {
  my($self, $status) = @_;
  $self->set_isis_active($status) if !$self->get_isis_active;
  $self->{isis_passive} = $status;
}


=head2 get_isis_passive()

Returns the whether the interface is isis-passive. (BOOLEAN)

=cut
sub get_isis_passive {
  my $self = shift;
  return $self->{isis_passive};
}


=head2 set_routecache_flowsampling($rcflowsampled)

Safe the interface's flowsampling status. (BOOLEAN)

=cut
sub set_routecache_flowsampling {
  my($self, $rcflowsampled) = @_;
  return if $rcflowsampled != 0 and $rcflowsampled != 1;
  $self->{rcflowsampled} = $rcflowsampled;
}


=head2 get_routecache_flowsampling()

Returns the interface's flowsampling status. (BOOLEAN)

=cut
sub get_routecache_flowsampling {
  my $self = shift;
  return $self->{rcflowsampled};
}


=head2 print_data()

Prints all data regarding the interface to STDOUT (e.g. for debugging).

=cut
sub print_data {
  my $self = shift;
  print "Unit Name:          ", $self->get_name, "\n";
  my($ip, $mask) = $self->get_ip;
  print "Unit IP/Mask:       $ip/$mask\n";
  print "Unit Unnumbered:    ", $self->get_unnumberedint, "\n";
  print "Unit Description:   ", $self->get_description,   "\n";
  print "Unit Ratelimit:     ", $self->get_ratelimit,     "\n";
  print "Unit Bandwidth:     ", $self->get_bandwidth,     "\n";
  print "Unit ISIS Status:   ", $self->get_isis_active,   "\n";
  print "Unit ISIS Level:    ", $self->get_isis_level,    "\n";
  print "Unit ISIS Metric:   ", $self->get_isis_metric,   "\n";
  print "Unit Flowsampling:  ", $self->get_routecache_flowsampling, "\n";
  print "Unit Status:        ", $self->get_active,        "\n";
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
