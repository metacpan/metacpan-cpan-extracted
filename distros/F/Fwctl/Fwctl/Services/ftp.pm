#
#    ftp.pm: Fwctl service module to handle the ftp protocol.
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
package Fwctl::Services::ftp;

use strict;

use Fwctl::RuleSet qw(:tcp_rulesets :ip_rulesets :masq :ports);
use IPChains;
use Carp;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  bless { pasv_ports	=> UNPRIVILEGED_PORTS,
	  pasv		=> 1,
	  port		=> 1,
	  data_port	=> "ftp-data",
	  ctrl_port	=> "ftp",
	}, $class;
}

sub prototypes {
  my ($self,$target,$options) = @_;

  # Build prototypes
  my $pasv_ports = $options->{pasv_ports} || $self->{pasv_ports};
  my $ctrl_port  = $options->{ctrl_port}  || $self->{ctrl_port};
  my $data_port	 = $options->{data_port}  || $self->{data_port};
  (
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => UNPRIVILEGED_PORTS,
		 DestPort   => $ctrl_port,
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => UNPRIVILEGED_PORTS,
		 DestPort   => $pasv_ports,
		 %{$options->{ipchains}},
		),
   IPChains->new(
		 Rule	    => $target,
		 Prot	    => 'tcp',
		 SourcePort => $data_port,
		 DestPort   => UNPRIVILEGED_PORTS,
		 %{$options->{ipchains}},
		),
  );
}

sub block_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;


  my $do_pasv = $options->{pasv};
  $do_pasv = $self->{pasv} unless defined $do_pasv;
  my $do_port = $options->{port};
  $do_port = $self->{pasv} unless defined $do_port;

  my ($ftp,$pasv,$port) = $self->prototypes( $target, $options );
  block_tcp_ruleset( $ftp, $src, $src_if, $dst, $dst_if );
  if ( $do_pasv ) {
    block_tcp_ruleset( $pasv, $src, $src_if, $dst, $dst_if );
  }
  if ($do_port ) {
    block_tcp_ruleset( $port, $dst, $dst_if, $src, $src_if  );
  }
}

sub accept_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my $do_pasv = $options->{pasv};
  $do_pasv = $self->{pasv} unless defined $do_pasv;
  my $do_port = $options->{port};

  $do_port = $self->{pasv} unless defined $do_port;

  my ($ftp,$pasv,$port) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  accept_tcp_ruleset( $ftp, $src, $src_if, $dst, $dst_if,
		      $masq, $options->{portfw} );

  if ( $do_pasv ) {
      accept_tcp_ruleset( $pasv, $src, $src_if, $dst, $dst_if,
			  $masq, $options->{portfw} );
  }

  if ( $do_port ) {
      if ( $masq & PORTFW ) {
	  # We must portfw the ACK and not SYN. Thats why we must roll
	  # our own
	  accept_ip_ruleset( $port, $dst, $dst_if, $src, $src_if,
			     UNPORTFW, $options->{portfw} );
	  $port->attribute( 'SYN',  '!' );

	  my $src_port = $port->attribute( 'SourcePort' );
	  my $dst_port = $port->attribute( 'DestPort' );
	  $port->attribute( 'DestPort',	    $src_port );
	  $port->attribute( 'SourcePort',   $dst_port );

	  accept_ip_ruleset( $port, $src, $src_if, $dst, $dst_if,
			     PORTFW, $options->{portfw} );
      } elsif ( $masq & MASQ ) {
	  # The data ports destination were rewritten.
	  accept_ip_ruleset( $port, $dst, $dst_if, $src, $src_if, UNMASQ );

	  $port->attribute( 'SYN',  '!' );
	  my $src_port = $port->attribute( 'SourcePort' );
	  my $dst_port = $port->attribute( 'DestPort' );
	  $port->attribute( 'DestPort',	    $src_port );
	  $port->attribute( 'SourcePort',   $dst_port );

	  accept_ip_ruleset( $port, $src, $src_if, $dst, $dst_if, MASQ );

	  # Load the necessary kernel module.
	  system ( "/sbin/modprobe", "ip_masq_ftp" ) == 0
	    or carp __PACKAGE__, ": couldn't load ip_masq_ftp: $?\n";
      } else {
	  accept_tcp_ruleset( $port, $dst, $dst_if, $src, $src_if );
      }
  }
}

sub account_rules {
  my $self = shift;
  my ( $target, $src, $src_if, $dst, $dst_if, $options ) = @_;

  my $do_pasv = $options->{pasv};
  $do_pasv = $self->{pasv} unless defined $do_pasv;
  my $do_port = $options->{port};
  $do_port = $self->{pasv} unless defined $do_port;

  my ($ftp,$pasv,$port) = $self->prototypes( $target, $options );

  my $masq = defined $options->{portfw} ? PORTFW :
    $options->{masq} ? MASQ : NOMASQ;

  acct_tcp_ruleset( $ftp, $src, $src_if, $dst, $dst_if, $masq );
  if ( $do_pasv ) {
      acct_tcp_ruleset( $pasv,	$src, $src_if, $dst, $dst_if, $masq );
  }
  if ( $do_port ) {
      if ( $masq & PORTFW ) {
	  # We must portfw the ACK and not SYN. Thats why we must roll
	  # our own
	  acct_ip_ruleset( $port, $dst, $dst_if, $src, $src_if,
			     UNPORTFW, $options->{portfw} );
	  $port->{SYN} = '!';
	  my $src_port = $port->attribute( 'SourcePort' );
	  my $dst_port = $port->attribute( 'DestPort' );
	  $port->attribute( 'DestPort',	    $src_port );
	  $port->attribute( 'SourcePort',   $dst_port );

	  acct_ip_ruleset( $port, $src, $src_if, $dst, $dst_if,
			     PORTFW, $options->{portfw} );
      } elsif ( $masq & MASQ ) {
	  # The data ports destination were rewritten. 
	  acct_ip_ruleset( $port, $dst, $dst_if, $src, $src_if, UNMASQ );

	  $port->attribute( 'SYN',  '!' );
	  my $src_port = $port->attribute( 'SourcePort' );
	  my $dst_port = $port->attribute( 'DestPort' );
	  $port->attribute( 'DestPort',	    $src_port );
	  $port->attribute( 'SourcePort',   $dst_port );

	  acct_ip_ruleset( $port, $src, $src_if, $dst, $dst_if, MASQ );
      } else {
	  acct_tcp_ruleset( $port, $dst, $dst_if, $src, $src_if,
			    $masq );
      }
  }
}

sub valid_options {
  my  $self = shift;
  ( "ctrl_port=s", "data_port=s", "pasv_ports=s", "pasv!", "port!" );
}

1;
=pod

=head1 NAME

Fwctl::Services::ftp - Fwctl module to handle the FTP service.

=head1 SYNOPSIS

    accept   ftp -src INTERNAL_NET -dst INTERNET -noport -masq
    accept   ftp -src PROXY_SERVER -dst INTERNET -noport --account
    accept   ftp -src INTERNET -d FTP_SERVER -noport
    accept   ftp -src INTERNAL_NET -dst INT_IP --ctrl_port hylafax

=head1 DESCRIPTION

The ftp module is used to handle the FTP protocol. By default it
handles both PORT and PASV based protocol. If maquerading is asked for,
it also loads the proper kernel module.

=head1 OPTIONS

In additions to the standard options it takes the following ones :

=over

=item --port or --noport

Sets whether rules for the PORT part of the FTP protocol will be added.

=item --pasv or --nopasv

Sets whether rules for the PASV part of the FTP protocol will be added.

=item --pasv_ports

Sets the port accepted for PASV connections. Defaults to UNPRIVILEGED_PORTS.

=item --ctrl_port

Sets the port used for the control connection. This is the port on which
the ftp server listens. Defaults to ftp.

=item --data_port

Sets the port for the data connection. This is the port from which PORT
connections of the server originates.

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

