#
#    syslog.pm - Fwctl module to handle syslog message.
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
package Fwctl::Services::syslog;

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

  my $local_port;
  if ( $options->{client} ) {
      $local_port = "1024:65535";
  }  else {
      $local_port = "514";
  }

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 SourcePort => $local_port,
		 DestPort   => 514,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($fw) = $self->prototypes( $target, $options );
  block_ip_ruleset( $fw, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  accept_ip_ruleset( $fw, $src, $src_if, $dst, $dst_if,
		     $masq, $options->{portfw} );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  acct_ip_ruleset( $fw, $src, $src_if, $dst, $dst_if, $masq );
}

sub valid_options {
  my  $self = shift;
  ( "client" );
}

1;

=pod

=head1 NAME

Fwctl::Services::syslog - Fwctl module to handle syslog UDP traffic.

=head1 SYNOPSIS

    accept   syslog -src ROUTER -dst LOGGER

=head1 DESCRIPTION

This modules handles syslog traffic. Syslog traffic is unidirectional
UDP message from client to server.

=head1 OPTIONS

In addition to the standard options, it accepts the following ones.

=over

=item --client

This will accepts message coming from a syslog client not bound
to port 514. The default is to accept messages only coming from
port 514.

=back

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

