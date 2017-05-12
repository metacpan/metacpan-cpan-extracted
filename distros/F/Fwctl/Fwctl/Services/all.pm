#
#    all.pm: Fwctl service module that represents rules matching all IP traffic.
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
package Fwctl::Services::all;

use strict;

use Fwctl::RuleSet qw(:ip_rulesets :tcp_rulesets :udp_rulesets :masq);
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
		 Prot	    => 'tcp',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'udp',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'icmp',
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
    my $self = shift;
    my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

    # Build prototype rule
    my ($tcp, $udp, $icmp, $all) = $self->prototypes( $target, $options );

    block_tcp_ruleset( $tcp, $src, $src_if, $dst, $dst_if );
    block_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if );
    block_ip_ruleset( $icmp, $src, $src_if, $dst, $dst_if );
    block_ip_ruleset( $icmp, $dst, $dst_if, $src, $src_if );
    block_ip_ruleset( $all, $src, $src_if, $dst, $dst_if );
    block_ip_ruleset( $all, $dst, $dst_if, $src, $src_if );
}

sub accept_rules {
    my $self = shift;
    my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

    # Build prototype rule
    my ($tcp, $udp, $icmp, $all) = $self->prototypes( $target, $options );

    accept_tcp_ruleset( $tcp, $src, $src_if, $dst, $dst_if,
			$options->{masq} ? MASQ : NOMASQ );
    accept_udp_ruleset( $udp, $src, $src_if, $dst, $dst_if,
			$options->{masq} ? MASQ : NOMASQ
		      );
    accept_ip_ruleset( $icmp, $src, $src_if, $dst, $dst_if,
		       $options->{masq} ? MASQ : NOMASQ
		     );
    accept_ip_ruleset( $icmp, $dst, $dst_if, $src, $src_if,
		       $options->{masq} ? UNMASQ : NOMASQ
		     );
    accept_ip_ruleset( $all, $src, $src_if, $dst, $dst_if,
		       $options->{masq} ? MASQ : NOMASQ
		     );
    accept_ip_ruleset( $all, $dst, $dst_if, $src, $src_if,
		       $options->{masq} ? UNMASQ : NOMASQ
		     );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  # Build prototype rule
  my ($tcp, $udp, $icmp, $all) = $self->prototypes( $target, $options );

  acct_ip_ruleset( $all, $src, $src_if, $dst, $dst_if,
		   $options->{masq} ? MASQ : NOMASQ
		 );
  acct_ip_ruleset( $all, $dst, $dst_if, $src, $src_if, 
		   $options->{masq} ? UNMASQ : NOMASQ
		 );
}

sub valid_options {
  (); # No options
}

1;
=pod

=head1 NAME

Fwctl::Services::all - Fwctl module to handle any IP traffic.

=head1 SYNOPSIS

    accept   all -src INTERNAL_NET -dst INTERNET -masq
    deny    all -src BAD_GUYS_NET	--account
    account all -src PERIM_NET -dst INTERNET

=head1 DESCRIPTION

The all module is used to match any IP traffic. It can be used for
accounting all traffic between nets or to create bazooka sized hole
in our filters.

Needless to say that

    accept all

is not a really secure use of this module.


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

