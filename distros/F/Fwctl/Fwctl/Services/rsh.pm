#
#    rsh.pm: Fwctl service module to handle the rsh protocol.
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
package Fwctl::Services::rsh;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :masq);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  # Build prototypes
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => "512:1023",
		 DestPort   => "shell",
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => "512:1023",
		 DestPort   => "512:1023",
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($rsh,$stderr) = $self->prototypes( $target, $options );
  block_tcp_ruleset( $rsh,	$src, $src_if, $dst, $dst_if );
  block_tcp_ruleset( $stderr,	$dst, $dst_if, $src, $src_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($rsh,$stderr) = $self->prototypes( $target, $options );
  accept_tcp_ruleset( $rsh,	$src, $src_if, $dst, $dst_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
  accept_tcp_ruleset( $stderr,	$dst, $dst_if, $src, $src_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($rsh,$stderr) = $self->prototypes( $target, $options );
  acct_tcp_ruleset( $rsh,	$src, $src_if, $dst, $dst_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
  acct_tcp_ruleset( $stderr,	$dst, $dst_if, $src, $src_if,
		     $options->{masq} ? MASQ : NOMASQ
		   );
}

sub valid_options {
  my  $self = shift;
  ();
}

1;
=pod

=head1 NAME

Fwctl::Services::rsh - Fwctl module to handle the rsh protocol.

=head1 SYNOPSIS

    accept   rsh -src INTERNAL_NET -dst FIREWALL

=head1 DESCRIPTION

The rsh module handles the remote shell protocol.

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

