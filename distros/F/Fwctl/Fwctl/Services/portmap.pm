#
#    portmap.pm: Fwctl service module to handle the portmapper protocol.
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
package Fwctl::Services::portmap;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :udp_rulesets :masq :ports);
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
		 SourcePort => '512:1023',
		 DestPort   => 'sunrpc',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => UNPRIVILEGED_PORTS,
		 DestPort   => '111',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($udp,$tcp) = $self->prototypes( $target, $options );
  block_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if );
  block_tcp_ruleset( $tcp, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($udp,$tcp) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  accept_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  accept_tcp_ruleset( $tcp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($udp,$tcp) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  acct_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  acct_tcp_ruleset( $tcp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
}

sub valid_options {
  my  $self = shift;
  ( );
}

1;
=pod

=head1 NAME

Fwctl::Services::portmap - Fwctl module to handle the portmapper service.

=head1 SYNOPSIS

    deny    portmap -src INTERNET	--account

=head1 DESCRIPTION

The portmapper handles portmap traffic.

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

