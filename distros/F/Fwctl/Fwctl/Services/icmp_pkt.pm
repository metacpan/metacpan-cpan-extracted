#
#    icmp.pm: Fwctl service module to handle arbitrery ICMP packets.
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
package Fwctl::Services::icmp_pkt;

use strict;

use Fwctl::RuleSet qw(:ip_rulesets :masq);
use IPChains;

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
		 ICMP	    => $options->{code},
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($msg) = $self->prototypes( $target, $options );

  block_ip_ruleset( $msg, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($msg) = $self->prototypes( $target, $options );

  accept_ip_ruleset( $msg, $src, $src_if, $dst, $dst_if,
		    $options->{masq} ? MASQ : NOMASQ
		  );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($msg) = $self->prototypes( $target, $options );

  acct_ip_ruleset( $msg, $src, $src_if, $dst, $dst_if,
		   $options->{masq} ? MASQ : NOMASQ
		  );
}

sub valid_options {
  ( "code=s" );
}

1;

=pod

=head1 NAME

Fwctl::Services::icmp_pkt - Fwctl module to handle arbitrary ICMP packet.

=head1 SYNOPSIS

    accept icmp_pkt -src INT_IP -dst INT_NET --code redirect

=head1 DESCRIPTION

This module can be use to add rules for arbitrary ICMP packets. Use the 
--code option to specify the ICMP code of the packet to build the rules
for.

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

