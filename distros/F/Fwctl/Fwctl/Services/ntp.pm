#
#    ntp.pm: Fwctl service module to handle the ntp protocol.
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
package Fwctl::Services::ntp;

use strict;

use Fwctl::RuleSet qw(:udp_rulesets :masq :ports);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  my $src_port = $options->{client} ? UNPRIVILEGED_PORTS : 'ntp';

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => $src_port,
		 DestPort   => 'ntp',
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
  acct_udp_ruleset( $fw, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
}

sub valid_options {
  my  $self = shift;
  ( "client" );
}

1;

=pod

=head1 NAME

Fwctl::Services::ntp - Fwctl module to handle the NTP protocol.

=head1 SYNOPSIS

    accept   ntp -src PROXY -dst NTP_SERVER
    accept   ntp -src PROXY -dst NTP_SERVER -client -masq #For ntpdate

=head1 DESCRIPTION

This module enable NTP traffic between two NTP servers. If you
use the I<client> option, it will use UNPRIVILEGED_PORTS for the 
SourcePort to enable ntp clients like B<ntpdate>.

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

