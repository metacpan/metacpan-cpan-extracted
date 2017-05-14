#!/usr/bin/env perl
####
## This file provides a class for holding informations about a prefixlist
## entry.
####

package IPDevice::RouterBase::PrefixlistEntry;
use IPDevice::RouterBase::Atom;
use IPDevice::IPv4;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::RouterBase::PrefixlistEntry

=head1 SYNOPSIS

 use IPDevice::RouterBase::PrefixlistEntry;
 my $entry = new IPDevice::RouterBase::PrefixlistEntry;
 $entry->set_prefix('192.168.0.0/22');
 $entry->set_ge(20);
 $entry->set_le(24);
 
 print "Prefix matches!\n" if $entry->match('192.168.1.12');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a single IP
prefix list entry.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments: none.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new prefixlist entry.
##
sub _init {
  my($self, %args) = @_;
  $self->{network} = 0;
  $self->{mask}    = 0;
  return $self;
}


=head2 set_sequence($seq)

Defines the sequence number of the entry.

=cut
sub set_sequence {
  my($self, $seq) = @_;
  $self->{seq} = $seq * 1;
}


=head2 get_sequence()

Returns the sequence number of the entry.

=cut
sub get_sequence {
  my $self = shift;
  return $self->{seq};
}


=head2 set_prefix($prefix)

Check & set the IP prefix.

=cut
sub set_prefix {
  my($self, $prefix) = @_;
  return FALSE if $prefix !~ /^([^\/]+)\/(\d+)$/;
  return FALSE if IPDevice::IPv4::check_ip($1) < 0;
  return FALSE if IPDevice::IPv4::check_prefixlen($2) < 0;
  $self->{network} = $1;
  $self->{mask}    = IPDevice::IPv4::pfxlen2mask($2);
  return TRUE;
}


=head2 get_prefix()

Returns the IP prefix.

=cut
sub get_prefix {
  my $self = shift;
  my $pfxlen = IPDevice::IPv4::mask2pfxlen($self->{mask});
  return "$self->{network}/$pfxlen";
}


=head2 set_network($network)

Set the IP network address.

=cut
sub set_network {
  my($self, $network) = @_;
  return FALSE if !IPDevice::IPv4::check_ip($network);
  $self->{network} = $network;
}


=head2 get_network()

Returns the IP network address.

=cut
sub get_network {
  my $self = shift;
  return $self->{network};
}


=head2 set_mask($mask)

Set the IP prefix mask.

=cut
sub set_mask {
  my($self, $mask) = @_;
  return $self->{mask};
}


=head2 get_mask()

Returns the IP prefix mask.

=cut
sub get_mask {
  my $self = shift;
  return $self->{mask};
}


=head2 set_prefixlen($prefixlength)

Set the IP prefix length.

=cut
sub set_prefixlen {
  my($self, $pfxlen) = @_;
  $self->{mask} = IPDevice::IPv4::pfxlen2mask($pfxlen);
}


=head2 get_prefixlen()

Returns the IP prefix length.

=cut
sub get_prefixlen {
  my $self = shift;
  return IPDevice::IPv4::mask2pfxlen($self->{mask});
}


=head2 set_permitdeny(('permit'|'deny'))

Defines whether this prefix is explicitly allowed or explicitly denied.

=cut
sub set_permitdeny {
  my($self, $permitdeny) = @_;
  return FALSE if $permitdeny ne 'permit' and $permitdeny ne 'deny';
  $self->{permitdeny} = $permitdeny;
  return TRUE;
}


=head2 get_permitdeny()

Returns whether this prefix is explicitly allowed or explicitly denied.
Returns either 'permit' or 'deny'.

=cut
sub get_permitdeny {
  my($self) = @_;
  return $self->{permitdeny};
}


=head2 set_le($prefixlength)

Defines, until which prefixlength this item will match (less-equal settings).

=cut
sub set_le {
  my($self, $pfxlen) = @_;
  $self->{lessequal} = $pfxlen;
}


=head2 get_le()

Returns an integer indicating to which prefixlength this item will match
(less-equal setting).

=cut
sub get_le {
  my($self) = @_;
  return $self->{lessequal};
}


=head2 set_ge($prefixlength)

Defines, until which prefixlength this item will match (greater-equal setting).

=cut
sub set_ge {
  my($self, $pfxlen) = @_;
  $self->{greaterequal} = $pfxlen;
}


=head2 get_ge()

Returns an integer indicating to which prefixlength this item will match
(greater-equal settings).

=cut
sub get_ge {
  my($self) = @_;
  return $self->{greaterequal};
}


=head2 matches_prefix($prefix)

Returns TRUE if the given prefix matches this prefix, otherwise FALSE.

=cut
sub matches_prefix {
  my($self, $prefix) = @_;
  return IPDevice::IPv4::prefix_match($self->{network},
                          $self->{mask},
                          $self->{lessequal},
                          $self->{greaterequal},
                          $prefix);
}


=head2 matches_ip($ip)

Returns TRUE if the ip address is in the range of this prefix, otherwise FALSE.

=cut
sub prefix_matches {
  my($self, $ip) = @_;
  return IPDevice::IPv4::prefix_match($self->{network},
                          $self->{mask},
                          32,
                          0,
                          "$ip/32");
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
