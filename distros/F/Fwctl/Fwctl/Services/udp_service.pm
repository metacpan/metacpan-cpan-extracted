#
#    udp_service.pm - Fwctl module to handle bidirectional UDP service.
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
package Fwctl::Services::udp_service;

use strict;

use Fwctl::RuleSet qw(:udp_rulesets :masq);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {
	 port => "1:1023",
	 local_port => "1024:65535",
	}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  my $src_port = $options->{local_port} || $self->{local_port};
  my $dst_port = $options->{port}	|| $self->{port};

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => $src_port,
		 DestPort   => $dst_port,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($fw) = $self->prototypes( $target, $options );
  block_udp_ruleset( $fw, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  accept_udp_ruleset( $fw, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  acct_udp_ruleset( $fw, $src, $src_if, $dst, $dst_if, $masq );
}

sub valid_options {
  my  $self = shift;
  ( "local_port=s", "port=s" );
}

1;
=pod

=head1 NAME

Fwctl::Services::udp_service - Fwctl module to handle bidirectional UDP traffic.

=head1 SYNOPSIS

    accept   udp_service -src INTERNAL_NET -dst FIREWALL -masq -port 2049

=head1 DESCRIPTION

This module is similar to the tcp_service one, in that it handles
simple bidirectional UDP communication between client and server.
Source and destination ports are given using the I<local_port> and
I<port> respectively. Those defaults to UNPRIVILEGED_PORTS. Enough to
shoot you in the foot, I know.

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

