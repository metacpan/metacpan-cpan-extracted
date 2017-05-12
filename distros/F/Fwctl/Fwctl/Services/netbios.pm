#
#    netbios.pm: Fwctl service module to handle the NetBios protocols.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis@iNsu.COM>
#
#    Copyright (c) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwctl::Services::netbios;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :udp_rulesets :ip_rulesets :masq :ports);
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
		 SourcePort => 'netbios-ns',
		 DestPort   => 'netbios-ns',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => 'netbios-dgm',
		 DestPort   => 'netbios-dgm',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => UNPRIVILEGED_PORTS,
		 DestPort   => 'netbios-ssn',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($name,$dgm,$ssn) = $self->prototypes( $target, $options );
  if ( ipv4_in_network( $src, $dst ) ) {
    block_ip_ruleset( $name, $src, $src_if, $src_if->{broadcast}, $dst_if );
  }
  block_udp_ruleset( $name, $src, $src_if, $dst, $dst_if );
  block_udp_ruleset( $dgm, $src, $src_if, $dst, $dst_if );
  block_tcp_ruleset( $ssn, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($name,$dgm,$ssn) = $self->prototypes( $target, $options );
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  if ( ipv4_in_network( $src, $dst ) ) {
    accept_ip_ruleset( $name, $src, $src_if, $src_if->{broadcast}, $dst_if,
		      $masq, $options->{portfw} );
  }


  accept_udp_ruleset( $name, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  accept_udp_ruleset( $dgm, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  accept_tcp_ruleset( $ssn, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($name,$dgm,$ssn) = $self->prototypes( $target, $options );
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  if ( ipv4_in_network( $src, $dst ) ) {
    accept_ip_ruleset( $name, $src, $src_if, $src_if->{broadcast}, $dst_if,
		       $masq );
  }
  acct_udp_ruleset( $name, $src, $src_if, $dst, $dst_if, $masq );
  acct_udp_ruleset( $dgm, $src, $src_if, $dst, $dst_if, $masq );
  acct_tcp_ruleset( $ssn, $src, $src_if, $dst, $dst_if, $masq );

}

sub valid_options {
  my  $self = shift;
  ( );
}

1;

=pod

=head1 NAME

Fwctl::Services::netbios - Fwctl module to handle NetBIOS traffic.

=head1 SYNOPSIS

    deny    netbios -nolog --account

=head1 DESCRIPTION

This module handle the NetBios-NS, NetBios-DGM and NetBios-SSN part of
the NetBIOS protocols. Its primary use is to reduce log clutter when
servicing a Windows Internal Network.

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

