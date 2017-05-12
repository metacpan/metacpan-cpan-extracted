#
#    snmp.pm: Fwctl service module to handle the snmp protocol.
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
package Fwctl::Services::snmp;

use strict;

use Fwctl::RuleSet qw( :ip_rulesets :udp_rulesets :masq :ports);
use Net::IPv4Addr qw(ipv4_in_network);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 DestPort   => 'snmp',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => 'snmp',
		 DestPort   => 'snmp-trap',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($snmp,$trap) = $self->prototypes( $target, $options );
  if ( ipv4_in_network( $src, $dst ) ) {
    block_ip_ruleset( $snmp, $src, $src_if, $src_if->{broadcast}, $dst_if );
  }
  block_udp_ruleset( $snmp, $src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $trap, $dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($snmp,$trap) = $self->prototypes( $target, $options );
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  if ( ipv4_in_network( $src, $dst ) ) {
    accept_ip_ruleset( $snmp, $src, $src_if, $src_if->{broadcast}, $dst_if,
		       $masq, $options->{portfw} );
  }
  accept_udp_ruleset( $snmp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  accept_ip_ruleset( $trap, $dst, $dst_if, $src, $src_if,
		     $masq, $options->{portfw} );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($snmp,$trap) = $self->prototypes( $target, $options );
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  if ( ipv4_in_network( $src, $dst ) ) {
    acct_ip_ruleset( $snmp, $src, $src_if, $src_if->{broadcast}, $dst_if,
		      $masq, $options->{portfw} );
  }
  acct_udp_ruleset( $snmp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
  acct_ip_ruleset( $trap, $dst, $dst_if, $src, $src_if,
		      $masq, $options->{portfw} );
}

sub valid_options {
  my  $self = shift;
  ( );
}

1;

=pod

=head1 NAME

Fwctl::Services::snmp - Fwctl module to handle the snmp protocol.

=head1 SYNOPSIS

    accept   snmp -src INTERNAL_NET -dst PERIM_NET
    deny    snmp -src INTERNAL_NET -nolog
    account snmp

=head1 DESCRIPTION

This module handles the SNMP protocol. Its handles SNMP broadcast
if dst is in the same network as src, SNMP traffic between source
and destination, as well as snmp-trap from destination to source.

Since I don't really know the internals of the SNMP protocol this
could be totally broken. Use only to reduce log file clutter.

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

