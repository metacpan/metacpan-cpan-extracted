#
#    timed.pm: Fwctl service module to handle timed protocol.
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
package Fwctl::Services::timed;

use strict;

use Fwctl::RuleSet qw(:ip_rulesets :udp_rulesets :masq :ports);
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
		 SourcePort => 'timed',
		 DestPort   => 'timed',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'icmp',
		 ICMP	    => 'timestamp-request',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'icmp',
		 ICMP	    => 'timestamp-reply',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($udp,$request,$reply) = $self->prototypes( $target, $options );
  if ( ipv4_in_network( $src, $dst ) ) {
    block_udp_ruleset( $udp, $src, $src_if, $src_if->{broadcast}, $dst_if );
  }
  block_udp_ruleset( $udp,	$src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $request,	$src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $reply,	$dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($udp,$request,$reply) = $self->prototypes( $target, $options );
  if ( ipv4_in_network( $src, $dst ) ) {
    accept_ip_ruleset( $udp, $src, $src_if, $src_if->{broadcast}, $dst_if,
		       $options->{masq} ? MASQ : NOMASQ
		     );
  }
  accept_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
  accept_ip_ruleset( $request, $src, $src_if, $dst, $dst_if,
		    $options->{masq} ? MASQ : NOMASQ
		   );
  accept_ip_ruleset( $reply, $dst, $dst_if, $src, $src_if,
		    $options->{masq} ? MASQ : NOMASQ
		  );

}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($udp,$request,$reply) = $self->prototypes( $target, $options );
  if ( ipv4_in_network( $src, $dst ) ) {
    accept_udp_ruleset( $udp, $src, $src_if, $src_if->{broadcast}, $dst_if,
		       $options->{masq} ? MASQ : NOMASQ
		     );
  }
  acct_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if,
		    $options->{masq} ? MASQ : NOMASQ
		  );
  acct_ip_ruleset( $request, $src, $src_if, $dst, $dst_if,
		   $options->{masq} ? MASQ : NOMASQ
		 );
  acct_ip_ruleset( $reply,   $src, $src_if, $dst, $dst_if,
		   $options->{masq} ? MASQ : NOMASQ
		 );
}

sub valid_options {
  my  $self = shift;
  ( );
}

1;
=pod

=head1 NAME

Fwctl::Services::timed - Fwctl module to handle any IP traffic.

=head1 SYNOPSIS

    accept   timed -src INTERNAL_NET -dst FIREWALL
    deny    timed -src INTERNET

=head1 DESCRIPTION

The timed module is used to handle the timed time synchronization
protocol. This modules takes care of the broadcast part of the
protocol and the ICMP part.

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

