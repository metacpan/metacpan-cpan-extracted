#
#    redirect.pm: Fwctl service module to handle ICMP redirect message
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
package Fwctl::Services::redirect;

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
		 ICMP	    => 'redirect',
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
  (); # No options
}

1;
=pod

=head1 NAME

Fwctl::Services::redirect - Fwctl module to handle ICMP redirect messages.

=head1 SYNOPSIS

    accept  redirect -src INT_IP -dst INT_NET
    account redirect -src INTERNET

=head1 DESCRIPTION

The redirect module can be use to configure policies for ICMP Router Redirect
messages. This module takes no options.

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

