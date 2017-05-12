#
#    dhcp.pm: Fwctl service module to handle the dhcp protocol.
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
package Fwctl::Services::dhcp;

use strict;

use Fwctl::RuleSet qw(:ip_rulesets :ports);
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
   # Client
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => 'bootpc',
		 DestPort   => 'bootps',
		 %{$options->{ipchains}},
		),
   # Server
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => 'bootps',
		 DestPort   => 'bootpc',
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($client,$server) = $self->prototypes( $target, $options );
  block_ip_ruleset( $client, "0.0.0.0", $src_if, "255.255.255.255", $dst_if );
  block_ip_ruleset( $server, $dst, $dst_if, "255.255.255.255", $src_if );
  block_ip_ruleset( $client, $src, $src_if, $dst, $dst_if );
  block_ip_ruleset( $client, $src, $src_if, "255.255.255.255", $dst_if );
  block_ip_ruleset( $server, $dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($client,$server) = $self->prototypes( $target, $options );
  accept_ip_ruleset( $client, "0.0.0.0", $src_if, "255.255.255.255", $dst_if );
  accept_ip_ruleset( $server, $dst, $dst_if, "255.255.255.255", $src_if );
  accept_ip_ruleset( $client, $src, $src_if, $dst, $dst_if );
  accept_ip_ruleset( $client, $src, $src_if, "255.255.255.255", $dst_if );
  accept_ip_ruleset( $server, $dst, $dst_if, $src, $src_if );

}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($client,$server) = $self->prototypes( $target, $options );
  acct_ip_ruleset( $client, "0.0.0.0", $src_if, "255.255.255.255", $dst_if );
  acct_ip_ruleset( $server, $dst, $dst_if, "255.255.255.255", $src_if );
  acct_ip_ruleset( $client, $src, $src_if, $dst, $dst_if );
  acct_ip_ruleset( $client, $src, $src_if, "255.255.255.255", $dst_if );
  acct_ip_ruleset( $server, $dst, $dst_if, $src, $src_if );

}

sub valid_options {
  my  $self = shift;
  ( );
}

1;
=pod

=head1 NAME

Fwctl::Services::dhcp - Fwctl module to handle the dhcp protocol.

=head1 SYNOPSIS

    accept  dhcp -src INTERNAL_NET -dst DHCP_SERVER
    deny    dhcp -src INTERNAL_NET -nolog
    account dhcp -src INTERNAL_NET

=head1 DESCRIPTION

This module is used to handle the DHCP protocol. It adds rules to
handle the special addresses used by the DHCP protocol. Since DHCP
is a broadcast based protocol restricted to local segment, so which
by definition doesn't cross a firewall, who would want to use such
a module ?

Two use, first to prevent clutter of log files which denied dhcp
broadcast packets when you are using DHCP on the internal network.
Second, when your firewall is acting as a DHCP server to the
internal network. ??? Who would want to do that ??? Someone trying
to replace all WinGate installations with linux based solutions ;-).

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

