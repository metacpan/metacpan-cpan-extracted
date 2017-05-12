#
#    tcp_service.pm: Fwctl service module to handle client/server tcp connection.
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
package Fwctl::Services::tcp_service;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :masq);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless {
	 port => "1:1023",
	 local_port => "1024:65535",
	}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  my $src_port = $options->{local_port} || $self->{local_port};
  my $dst_port = $options->{port}	|| $self->{port};

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => $src_port,
		 DestPort   => $dst_port,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my ($fw) = $self->prototypes( $target, $options );
  block_tcp_ruleset( $fw, $src, $src_if, $dst, $dst_if );
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  accept_tcp_ruleset( $fw, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my ($fw) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  acct_tcp_ruleset( $fw, $src, $src_if, $dst, $dst_if, $masq );
}

sub valid_options {
  my  $self = shift;
  ( "local_port=s", "port=s" );
}

1;

=pod

=head1 NAME

Fwctl::Services::tcp_service - Fwctl module to handle simple TCP client/server communication.

=head1 SYNOPSIS

    accept   tcp_service -src INTERNAL_NET -dst DATABASE_SERVER -port postgres
    # Same as
    accept   postgres -src INTERNAL_NET -dst DATABASE_SERVER
    account tcp_service -src INTERNET -port telnet
    # Same as
    account telnet  -src INTERNET

=head1 DESCRIPTION

This Fwctl module is used to handle single connection TCP client/server. It
takes as options I<port> and I<local_port> which are used to set the
destination and source port of the connection.

This is the module used to auto generate TCP service.

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

