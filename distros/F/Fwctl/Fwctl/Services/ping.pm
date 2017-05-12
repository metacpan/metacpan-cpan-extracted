#
#    ping.pm: Fwctl service module to handle the ping service.
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
package Fwctl::Services::ping;

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
		 ICMP	    => 'echo-request',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'icmp',
		 ICMP	    => 'echo-reply',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($ping,$pong) = $self->prototypes( $target, $options );

  block_ip_ruleset( $ping, $src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $pong, $dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($ping,$pong) = $self->prototypes( $target, $options );

  accept_ip_ruleset( $ping, $src, $src_if, $dst, $dst_if,
		    $options->{masq} ? MASQ : NOMASQ
		  );
  accept_ip_ruleset( $pong, $dst, $dst_if, $src, $src_if,
		    $options->{masq} ? UNMASQ : NOMASQ
		  );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($ping,$pong) = $self->prototypes( $target, $options );

  acct_ip_ruleset( $ping, $src, $src_if, $dst, $dst_if,
		   $options->{masq} ? MASQ : NOMASQ
		  );
  acct_ip_ruleset( $pong, $dst, $dst_if, $src, $src_if,
		   $options->{masq} ? UNMASQ : NOMASQ
		 );
}

sub valid_options {
  (); # No options
}

1;
=pod

=head1 NAME

Fwctl::Services::ping - Fwctl module to handle the ping service.

=head1 SYNOPSIS

    accept  ping -src INTERNAL_NET -dst INTERNET -masq
    deny    ping -dst BAD_GUYS_NET	--account
    account ping -src INTERNET -dst FIREWALL

=head1 DESCRIPTION

The ping module manages rules for the ICMP echo-request and echo-reply
types used by the ping B<program>.

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

