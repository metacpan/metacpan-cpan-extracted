#
#    pptp.pm: Fwctl service module to handle the IPSec service over ESP.
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
package Fwctl::Services::ipsec;

use strict;

use Fwctl::RuleSet qw(:udp_rulesets :ip_rulesets :masq );
use IPChains;
use Carp;

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
		 SourcePort => 500,
		 DestPort   => 500, # ISAKMP
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 50, # ESP
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($control,$esp) = $self->prototypes( $target, $options );

  block_udp_ruleset( $control, $src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $esp, $src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $esp, $dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($control, $esp ) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  accept_udp_ruleset( $control, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
  accept_ip_ruleset( $esp, $src, $src_if, $dst, $dst_if,
		     $masq, $options->{portfw} );

  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  accept_ip_ruleset( $esp, $dst, $dst_if, $src, $src_if,
		     $masq, $options->{portfw} );

  if ($options->{masq} || $options->{portfw} ) {
      system ( "/sbin/modprobe", "ip_masq_ipsec" ) == 0
	or carp __PACKAGE__, ": couldn't load ip_masq_ipsec: $?\n";
  }
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ( $control, $esp ) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  acct_udp_ruleset( $control, $src, $src_if, $dst, $dst_if,
		    $masq, $options->{portfw} );
  acct_ip_ruleset( $esp, $src, $src_if, $dst, $dst_if,
		   $masq, $options->{portfw} );

  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  acct_ip_ruleset( $esp, $dst, $dst_if, $src, $src_if,
		   $masq, $options->{portfw} );

}

sub valid_options {
  my  $self = shift;
  ( );
}

1;
=pod

=head1 NAME

Fwctl::Services::ipsec - Fwctl module to handle the IPSec protocol.

=head1 SYNOPSIS

    accept ipsec -src INT_NET -dst REMOTE_IPSEC

=head1 DESCRIPTION

This module will implements the rules to accept/block/account the IPSec
tunnelling protocol. In order to be able to masquerade that protocol, you
will need a kernel with the IPSec masquerade patch applied.

See ftp://ftp.rubyriver.com/pub/jhardin/masquerade/ for informations.

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

