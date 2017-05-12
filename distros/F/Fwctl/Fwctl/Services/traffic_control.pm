#
#    traffic_control.pm: Fwctl module to handle ICMP traffic control.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (c) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwctl::Services::traffic_control;

use strict;

use Fwctl::RuleSet qw(:ip_rulesets :masq);
use IPChains;

use vars qw( @TYPES );

@TYPES = qw( ttl-exceeded parameter-problem source-quench 
	     destination-unreachable );

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'icmp',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($icmp) = $self->prototypes( $target, $options );

  for (@TYPES) {
    $icmp->attribute( ICMP => $_ );
    block_ip_ruleset( $icmp, $src, $src_if, $dst, $dst_if );
  }
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($icmp) = $self->prototypes( $target, $options );

  for (@TYPES) {
    $icmp->attribute( ICMP => $_ );
    accept_ip_ruleset( $icmp, $src, $src_if, $dst, $dst_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
  }
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($icmp) = $self->prototypes( $target, $options );

  for (@TYPES) {
    $icmp->attribute( ICMP => $_ );
    acct_ip_ruleset( $icmp, $src, $src_if, $dst, $dst_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
  }
}

sub valid_options {
  (); # No options
}

1;
=pod

=head1 NAME

Fwctl::Services::traffic_control - Fwctl module to handle the necessary 
ICMP traffic.

=head1 SYNOPSIS

    accept   traffic_control -src INTERNET --account
    accept   traffic_control 

=head1 DESCRIPTION

This module handles rules for the necessary ICMP traffic control types:
destination-unreachable, source-quench, ttl-exceeded and parameter-problem.

You should really accept this with any network you want to communicate.
Failure to do so, will hinder communication severly. YHBW.

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

fwctl(8) Fwctl(3) Fwctl::RuleSet(3)

=cut

