#!/usr/bin/env perl
####
## This file provides a class for holding informations regarding an
## hostname <-> IP mapping.
####

package IPDevice::RouterBase::IPHost;
use IPDevice::RouterBase::Atom;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::IPHost

=head1 SYNOPSIS

 use IPDevice::RouterBase::IPHost;
 my $map = new IPDevice::RouterBase::IPHost("localhost", "80");
 $map->set_ip('127.0.0.1');

=head1 DESCRIPTION

This module provides a base class, providing routines for storing informations
regarding an hostname <-> IP mapping.

=head1 CONSTRUCTOR AND METHODS

=head2 new($hostname, ($port|-1), [%args])

Object constructor. Valid arguments:

I<hostname>: The hostname to be mapped.

I<port>: The port number to be mapped, or -1 for all ports.

=cut
sub new {
  my($class, $hostname, $port, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init($hostname, $port, %args);
}


## Purpose: Initialize a new router.
##
sub _init {
  my($self, $hostname, $port, %args) = @_;
  $self->{hostname} = $hostname;
  $self->{port}     = $port ? $port : 0;
  return $self;
}


=head2 set_hostname($hostname)

Set the hostname.

=cut
sub set_hostname {
  my($self, $hostname) = @_;
  $self->{hostname} = $hostname;
}


=head2 get_hostname()

Returns the hostname.

=cut
sub get_hostname {
  my $self = shift;
  return $self->{hostname};
}


=head2 set_port($port)

Defines the port number.

=cut
sub set_port {
  my($self, $port) = @_;
  $self->{port} = $port;
}


=head2 get_port()

Returns the port number.

=cut
sub get_port {
  my $self = shift;
  return $self->{port};
}


=head2 set_ip($ip)

Defines the destination IP address.

=cut
sub set_ip {
  my($self, $ip) = @_;
  $self->{ip} = $ip;
}


=head2 get_ip()

Returns the destination IP address.

=cut
sub get_ip {
  my $self = shift;
  return $self->{ip};
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
