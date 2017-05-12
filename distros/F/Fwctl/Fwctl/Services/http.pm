#
#    http.pm: Fwctl service module to handle the http protocol.
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
package Fwctl::Services::http;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :masq :ports);
use IPChains;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless { port =>  "80" }, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  # Build prototype rule
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => UNPRIVILEGED_PORTS,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my $port = $options->{port} || $self->{port};

  my ($http) = $self->prototypes( $target, $options );
  for (split /,/, $port ) {
    $http->attribute( DestPort => $_ );
    block_tcp_ruleset( $http, $src, $src_if, $dst, $dst_if );
  }
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my $port = $options->{port} || $self->{port};

  my ($http) = $self->prototypes( $target, $options );
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;
  for (split /,/, $port ) {
    $http->attribute( DestPort => $_ );
    accept_tcp_ruleset( $http, $src, $src_if, $dst, $dst_if,
			$masq, $options->{portfw} );
  }
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my $port = $options->{port} || $self->{port};
  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  my ($http) = $self->prototypes( $target, $options );
  for (split /,/, $port ) {
    $http->attribute( DestPort => $_ );
    acct_tcp_ruleset( $http, $src, $src_if, $dst, $dst_if, $masq );
  }
}

sub valid_options {
  my  $self = shift;
  ( "port=s" );
}

1;

=pod

=head1 NAME

Fwctl::Services::http - Fwctl module to handle HTTP protocol.

=head1 SYNOPSIS

    accept   http -src INTERNAL_NET -dst PROXY
    deny    http -dst MICROSOFT	--nolog --account
    account http -src PROXY -dst INTERNET

=head1 DESCRIPTION

The http module is used to control traffic which should be part of
an HTTP connection. It use the option I<port> which should contains
a comma separated list of port which are open for TCP connections.
Defaults to 80.

THIS IS NOT A PROXY. It only open a bunch of TCP port to which
connection can be attempted. You have been warned.

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

