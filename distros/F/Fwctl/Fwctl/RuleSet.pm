#
#    RuleSet.pm - Module to add sets of rules to the linux firewall.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis@iNsu.COM>
#
#    Copyright (c) 1999, 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwctl::RuleSet;

use strict;

use Net::IPv4Addr qw( ipv4_in_network ipv4_broadcast ipv4_parse );
use IPChains;
use Carp;

use constant NOMASQ	=> 0;
use constant MASQ	=> 1;
use constant UNMASQ	=> 2;
use constant MASQNOHIGH => 4;
use constant PORTFW	=> 8;
use constant UNPORTFW	=> MASQ|MASQNOHIGH;

use constant RESERVED_PORTS	=> "1:1023";
use constant UNPRIVILEGED_PORTS => "1024:65535";
use constant MASQ_PORTS => "61000:65096";

use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);

BEGIN {
  require Exporter;

  @ISA		= ("Exporter");
  @EXPORT	= ();
  @EXPORT_OK	= ();

  %EXPORT_TAGS = (
		  masq	       => [ qw( NOMASQ MASQ UNMASQ PORTFW UNPORTFW MASQNOHIGH ) ],
		  ports	       => [ qw( RESERVED_PORTS UNPRIVILEGED_PORTS MASQ_PORTS ) ],
		  tcp_rulesets => [ qw( accept_tcp_ruleset block_tcp_ruleset
					acct_tcp_ruleset ) ],
		  udp_rulesets => [ qw( accept_udp_ruleset block_udp_ruleset
					acct_udp_ruleset) ],
		  ip_rulesets  => [ qw( accept_ip_ruleset block_ip_ruleset
					acct_ip_ruleset) ],
		 );

  Exporter::export_ok_tags( keys %EXPORT_TAGS );

  # Optional module
  eval { use IPChains::PortFW };
}


# Determine the address spec and interface case
sub determine_case {
  my ( $ip, $if ) = @_;

  my ($ip,$msklen) = ipv4_parse( $ip );

  return "ANY"		    if $if->{name} eq "ANY";
  return "LOCAL_IP"	    if $if->{ip} eq $ip;
  return "LOCAL_IMPLIED"    if $if->{broadcast} eq $ip;
  return "LOCAL_IMPLIED"    if $ip eq "255.255.255.255";
  return "REMOTE"	    if $ip eq "0.0.0.0" and $if->{name} eq 'EXT';
  return "LOCAL_IMPLIED"    if $ip eq "0.0.0.0";

  return "REMOTE"	    unless defined $msklen;

  return "LOCAL_IMPLIED"    if ipv4_in_network( $ip, $msklen, $if->{ip} );
  return "REMOTE";
}

sub determine_base {
  my ($ipchain) = shift;

  my $proto  = $ipchain->attribute( 'Prot' );
  return "all" if not defined $proto or $proto =~ /all/i;

  # Handle numeric protocol specification
  my $proto_name = getprotobynumber $proto if $proto =~ /\d+/;
  $proto = $proto_name if defined $proto_name;

  my $syn = 0;
  my $ack = 0;
  if ($proto =~ /tcp/i and defined $ipchain->attribute( 'SYN' ) ) {
    $syn = $ipchain->attribute( 'SYN' ) eq '1';
    $ack = $ipchain->attribute( 'SYN' ) eq '!';
  }

  return "icmp" if $proto =~ /icmp/i;
  return "udp"  if $proto =~ /udp/i;
  return "syn"  if $syn;
  return "ack"  if $ack;
  return "tcp"  if $proto =~ /tcp/i;
  return "oth";
}

sub accept_tcp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq, $portfw ) = @_;

  croak __PACKAGE__, ": protocol isn't TCP"
    unless $ipchain->attribute( 'Prot' ) =~ /tcp/i;

  $masq = NOMASQ unless defined $masq;

  croak __PACKAGE__, ": can't use invalid \$masq and \$portfw combination"
    if (   defined $portfw && ! $masq & PORTFW) ||
       ( ! defined $portfw &&   $masq & PORTFW );

  my $syn      = $ipchain->attribute( 'SYN' );
  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  $ipchain->attribute( SYN => undef );
  accept_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if, $masq, $portfw );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );
  $ipchain->attribute( SYN => '!' );

  # Switch from MASQ to UNMASQ
  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      # Packets that were port forwarded should be masqueraded back
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  accept_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if, $masq, $portfw );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
  $ipchain->attribute( SYN => $syn );
}

sub accept_udp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq, $portfw ) = @_;

  croak __PACKAGE__, ": protocol isn't UDP"
    unless $ipchain->attribute( 'Prot' ) =~ /UDP/i;

  $masq = NOMASQ unless defined $masq;

  croak __PACKAGE__, ": can't use invalid \$masq and \$portfw combination"
    if (   defined $portfw && ! $masq & PORTFW) ||
       ( ! defined $portfw &&   $masq & PORTFW );

  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  accept_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if, $masq, $portfw );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );
  # Switch from MASQ to UNMASQ
  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      # Packets that were port forwarded should be masqueraded back
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  accept_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if, $masq, $portfw );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
}

# Adds protocol necessary ruleset for a type of packet
# to pass through the interface of the firewall.
sub accept_ip_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq, $portfw ) = @_;

  croak __PACKAGE__, ": rule target must be ACCEPT: ", $ipchain->attribute( 'Rule' )
    unless $ipchain->attribute( 'Rule' ) =~ /ACCEPT/;

  my $src_kind = determine_case( $src, $src_if );
  my $dst_kind = determine_case( $dst, $dst_if );

  $ipchain->attribute( Source => $src );
  $ipchain->attribute( Dest   => $dst );

  my $base = determine_base( $ipchain );

  # Check masquerading parameter.
  $masq = NOMASQ unless defined $masq;

 SWITCH:
  for ("$src_kind-$dst_kind" ) {
    /ANY-ANY|ANY-REMOTE|REMOTE-ANY/ && do {
      ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
      if ( $masq & MASQ ) {
	ip_local_out_ruleset( @_[0..4], $base );
      } elsif ( $masq & UNMASQ ) {
	ip_local_in_ruleset( @_[0..4], $base );
      }
      last SWITCH;
    };
    /LOCAL_IMPLIED-LOCAL_IMPLIED/ && do {
	# name handle the INTERNET or 0.0.0.0/0 case 
	# and ipv4_in_network handle the case of two routers scenario
      if ( $src_if->{name} ne $dst_if->{name} || ! ipv4_in_network( $src, $dst ) ) {
	# Src and dst networks are different
	ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
	if ( $masq & MASQ ) {
	  ip_local_out_ruleset( @_[0..4], $base );
	} elsif ( $masq & UNMASQ ) {
	  ip_local_in_ruleset( @_[0..4], $base );
	}
      } else {
	# No forwarding will take place
	ip_local_in_ruleset( @_[0..4], $base );
      }
      last SWITCH;
    };
    /REMOTE-LOCAL_IMPLIED|LOCAL_IMPLIED-REMOTE/ && do {
	# name handle the INTERNET or 0.0.0.0/0 case 
	# and ipv4_in_network handle the case of two routers scenario
      if ( $src_if->{name} ne $dst_if->{name} || ! ipv4_in_network( $src, $dst ) ) {
	# Src and dst networks are different
	ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
      } else {
	# No forwarding will take place
	ip_local_in_ruleset( @_[0..4], $base );
      }
      last SWITCH;
    };
    /ANY-LOCAL_IMPLIED/ && do {
      ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
      ip_loopback_out_ruleset( @_[0..4], $base );
      if ( $masq & MASQ ) {
	ip_local_out_ruleset( @_[0..4], $base );
      } elsif ( $masq & UNMASQ ) {
	ip_local_in_ruleset( @_[0..4], $base );
      }
      last SWITCH;
    };
    /REMOTE-REMOTE/ && do {
      ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
      last SWITCH;
    };
    /LOCAL_IMPLIED-ANY/ && do {
      ip_forward_ruleset( @_[0..4], $base, $masq, $portfw );
      ip_loopback_in_ruleset( @_[0..4], $base );
      if ( $masq & MASQ ) {
	ip_local_out_ruleset( @_[0..4], $base );
      } elsif ( $masq & UNMASQ ) {
	ip_local_in_ruleset( @_[0..4], $base );
      }
      last SWITCH;
    };
    /LOCAL_IP-ANY/ && do {
      ip_local_out_ruleset( @_[0..4], $base );
      ip_loopback_in_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /LOCAL_IP-LOCAL_IMPLIED/ && do {
      ip_local_out_ruleset( @_[0..4], $base );
      ip_loopback_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /ANY-LOCAL_IP/ && do {
      ip_local_in_ruleset( @_[0..4], $base );
      ip_loopback_out_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /LOCAL_IMPLIED-LOCAL_IP/ && do {
      ip_local_in_ruleset( @_[0..4], $base );
      ip_loopback_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /LOCAL_IP-LOCAL_IP/ && do {
      ip_loopback_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /REMOTE-LOCAL_IP/ && do {
      ip_local_in_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    /LOCAL_IP-REMOTE/ && do {
      ip_local_out_ruleset( @_[0..4], $base );
      last SWITCH;
    };
    croak __PACKAGE__, ": unknown src/dst combination: $src/$dst\n";
  }
}


# Add rule to necessary chains to handle
# loopback connection. Local process to
# local process.
sub ip_loopback_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => "lo" );
  $ipchain->append( "$base-out" );
  $ipchain->append( "$base-in" );
}

sub ip_loopback_out_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => "lo" );
  $ipchain->append( "$base-out" );

}

sub ip_loopback_in_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => "lo" );
  $ipchain->append( "$base-in" );

}

# Add rule to necessary chains to handle
# an incoming packet destined to a local
# process
sub ip_local_out_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-out" );
}

# Add rule to necessary chains to handle
# a outgoing local originating packet.
sub ip_local_in_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->append( "$base-in" );
}

# Add rule to necessary chains to handle
# a routed packet. Packet that aren't
# destined locally.
#
# src_if and dst_if should be different
# then lo.
sub ip_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq, $portfw ) = @_;

  if ( $masq & MASQ ) {
  SWITCH:
    for ($base) {
      /tcp|ack|syn/ && do {
	tcp_masq_forward_ruleset( @_ );
	last SWITCH;
      };
      /udp/ && do {
	udp_masq_forward_ruleset( @_ );
	last SWITCH;
      };
      /icmp|oth|all/ && do {
	ip_masq_forward_ruleset( @_ );
	last SWITCH;
      };
  }
  } elsif ($masq & UNMASQ ) {
  SWITCH:
    for ($base) {
      /tcp|ack|syn/ && do {
	tcp_unmasq_forward_ruleset( @_ );
	last SWITCH;
      };
      /udp/ && do {
	udp_unmasq_forward_ruleset( @_ );
	last SWITCH;
      };
      /icmp|oth|all/ && do {
	ip_unmasq_forward_ruleset( @_ );
	last SWITCH;
      };
  }
  } elsif ( $masq & PORTFW ) {
      if ($base =~ /tcp|ack|syn|udp/ ) {
	  tcpudp_portfw_forward_ruleset( @_ );
      } else {
	  ip_portfw_forward_ruleset( @_ );
      }
  } else {
    $ipchain->attribute( Interface => $src_if->{interface} );
    $ipchain->append( "$base-in" );
    $ipchain->attribute( Interface => $dst_if->{interface} );
    $ipchain->append( "$base-fwd" );
    $ipchain->append( "$base-out" );
  }
}

# Add rule to necessary chains to handle
# a route TCP masqueraded packet.
sub tcp_masq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq, $masqip ) = @_;

  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->append( "$base-in" );

  my $rule = $ipchain->attribute( 'Rule' );
  $ipchain->attribute( Rule => 'MASQ' );
  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-fwd" );
  $ipchain->attribute( Rule => $rule );

  my $saved_ports = $ipchain->attribute('SourcePort');
  my $ip =  $masqip ? $masqip : $dst_if->{ip};
  $ipchain->attribute( Source	    => $ip );
  $ipchain->attribute( SourcePort   => MASQ_PORTS ) unless $masq & MASQNOHIGH;
  $ipchain->append( "$base-out" );
  $ipchain->attribute( Source	    => $src );
  $ipchain->attribute( SourcePort   => $saved_ports );
}


sub udp_masq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq, $masqip ) = @_;

  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->append( "$base-in" );
  my $rule = $ipchain->attribute( 'Rule' );
  $ipchain->attribute( Rule => 'MASQ' );
  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-fwd" );
  $ipchain->attribute( Rule => $rule );

  my $saved_ports = $ipchain->attribute('SourcePort');
  my $ip = $masqip ? $masqip : $dst_if->{ip};
  $ipchain->attribute( Source	    => $ip );
  $ipchain->attribute( SourcePort   => MASQ_PORTS ) unless $masq & MASQNOHIGH;
  $ipchain->append( "$base-out" );
  $ipchain->attribute( Source	    => $src );
  $ipchain->attribute( SourcePort   => $saved_ports );
}

sub ip_masq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->append( "$base-in" );
  my $rule = $ipchain->attribute( 'Rule' );
  $ipchain->attribute( Rule => 'MASQ' );
  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-fwd" );
  $ipchain->attribute( Rule => $rule );

  $ipchain->attribute( Source	    => $dst_if->{ip} );
  $ipchain->append( "$base-out" );
  $ipchain->attribute( Source	    => $src );
}

# Add rule to necessary chains to handle
# a route TCP packet which was masqueraded.
sub tcp_unmasq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq ) = @_;

  my $saved_ports = $ipchain->attribute('DestPort');
  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->attribute( Dest	 => $src_if->{ip} );
  $ipchain->attribute( DestPort  => MASQ_PORTS ) unless $masq & MASQNOHIGH;
  $ipchain->append( "$base-in" );
  $ipchain->attribute( Dest	 => $dst );
  $ipchain->attribute( DestPort  => $saved_ports );

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-out" );
}

sub udp_unmasq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq ) = @_;

  my $saved_ports = $ipchain->attribute('DestPort');
  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->attribute( Dest	 => $src_if->{ip} );
  $ipchain->attribute( DestPort  => MASQ_PORTS ) unless $masq & MASQNOHIGH;
  $ipchain->append( "$base-in" );
  $ipchain->attribute( Dest	 => $dst );
  $ipchain->attribute( DestPort  => $saved_ports );

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-out" );
}

sub ip_unmasq_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base ) = @_;

  my $saved_ports = $ipchain->attribute('DestPort');
  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->attribute( Dest	 => $src_if->{ip} );
  $ipchain->append( "$base-in" );
  $ipchain->attribute( Dest	 => $dst );

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-out" );
}


sub tcpudp_portfw_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq, $portfw ) = @_;
  $portfw ||= $src_if->{ip};

  # Incoming address is in $portfw
  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->attribute( Dest => $portfw );
  $ipchain->append( "$base-in" );

  $ipchain->attribute( Dest => $dst );

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-fwd" );
  $ipchain->append( "$base-out" );

  # Add port forwarding rule
  my $proto = $ipchain->attribute( 'Prot' );
  my $port  = $ipchain->attribute( 'DestPort' );

  my $portfw_chain = new IPChains::PortFW( Proto     => $proto,
					   LocalAddr => $portfw,
					   LocalPort => $port,
					   RemAddr   => $dst,
					   RemPort   => $port
					 );
  $portfw_chain->append;

}

# We just set up the rules here. The user will have
# to set the ipfwd daemon manually
sub ip_portfw_forward_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $base, $masq, $portfw ) = @_;
  $portfw ||= $src_if->{ip};

  # Incoming address is in $portfw
  $ipchain->attribute( Interface => $src_if->{interface} );
  $ipchain->attribute( Dest => $portfw );
  $ipchain->append( "$base-in" );

  $ipchain->attribute( Dest => $dst );

  $ipchain->attribute( Interface => $dst_if->{interface} );
  $ipchain->append( "$base-fwd" );
  $ipchain->append( "$base-out" );
}

sub block_tcp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if ) = @_;

  croak __PACKAGE__, ": protocol isn't TCP"
    unless $ipchain->attribute( 'Prot' ) =~ /tcp/i;

  my $syn      = $ipchain->attribute( 'SYN' );
  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  $ipchain->attribute( SYN => undef );
  block_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );
  $ipchain->attribute( SYN => '!' );
  block_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
  $ipchain->attribute( SYN => $syn );

}

sub block_udp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq ) = @_;

  croak __PACKAGE__, ": protocol isn't UDP"
    unless $ipchain->attribute( 'Prot' ) =~ /UDP/i;

  $masq = NOMASQ unless defined $masq;

  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  block_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );
  block_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
}

sub block_ip_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if ) = @_;

  my $src_kind = determine_case( $src, $src_if );
  my $dst_kind = determine_case( $dst, $dst_if );

  croak __PACKAGE__, ": rule target must be REJECT or DENY: ", $ipchain->attribute( 'Rule' )
    unless $ipchain->attribute( 'Rule' ) =~ /DENY|REJECT/;

  $ipchain->attribute( Source => $src );
  $ipchain->attribute( Dest   => $dst );

  my $base = determine_base( $ipchain );

 SWITCH:
  for ("$src_kind-$dst_kind" ) {
    /ANY-ANY|LOCAL_IMPLIED-ANY|ANY-REMOTE|LOCAL_IMPLIED-REMOTE/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "$base-in" );
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /ANY-LOCAL_IMPLIED|LOCAL_IMPLIED-LOCAL_IMPLIED/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "$base-in" );
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "$base-out" );
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /LOCAL_IP-ANY|LOCAL_IP-LOCAL_IMPLIED/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "$base-out" );
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /ANY-LOCAL_IP|LOCAL_IMPLIED-LOCAL_IP/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "$base-in" );
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /LOCAL_IP-LOCAL_IP/ && do {
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /LOCAL_IP-REMOTE/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "$base-out" );
      last SWITCH;
    };
    /REMOTE-.*/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "$base-in" );
      last SWITCH;
    };
    croak __PACKAGE__, ": unknown src/dst combination: $src/$dst\n";
  }
}

sub acct_tcp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq ) = @_;

  croak __PACKAGE__, ": protocol isn't TCP"
    unless $ipchain->attribute( 'Prot' ) =~ /tcp/i;

  $masq = NOMASQ unless defined $masq;

  my $syn      = $ipchain->attribute( 'SYN' );
  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  $ipchain->attribute( SYN => undef );
  acct_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if, $masq );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );
  $ipchain->attribute( SYN => '!' );
  # Switch from MASQ to UNMASQ
  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      # Packets that were port forwarded should be masqueraded back
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  acct_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if, $masq );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
  $ipchain->attribute( SYN => $syn );

}

sub acct_udp_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq ) = @_;

  croak __PACKAGE__, ": protocol isn't UDP"
    unless $ipchain->attribute( 'Prot' ) =~ /UDP/i;

  $masq = NOMASQ unless defined $masq;

  my $src_port = $ipchain->attribute( 'SourcePort' );
  my $dst_port = $ipchain->attribute( 'DestPort' );

  # Client side
  acct_ip_ruleset( $ipchain, $src, $src_if, $dst, $dst_if, $masq );

  # Server side
  $ipchain->attribute( SourcePort => $dst_port );
  $ipchain->attribute( DestPort   => $src_port );

  # Switch from MASQ to UNMASQ
  if ( $masq & MASQ ) {
      $masq &= $masq ^ MASQ;
      $masq |= UNMASQ;
  } elsif ( $masq & PORTFW ) {
      # Packets that were port forwarded should be masqueraded back
      $masq &= $masq ^ PORTFW;
      $masq |= UNPORTFW;
  }
  acct_ip_ruleset( $ipchain, $dst, $dst_if, $src, $src_if, $masq );

  # Restore params
  $ipchain->attribute( SourcePort => $src_port );
  $ipchain->attribute( DestPort   => $dst_port );
}

sub acct_ip_ruleset {
  my ( $ipchain, $src, $src_if, $dst, $dst_if, $masq ) = @_;

  croak __PACKAGE__, ": bad rule target: ", $ipchain->attribute( 'Rule' )
    unless $ipchain->attribute( 'Rule' ) =~ /acct\d{4}/;

  my $src_kind = determine_case( $src, $src_if );
  my $dst_kind = determine_case( $dst, $dst_if );

  $ipchain->attribute( Source => $src );
  $ipchain->attribute( Dest   => $dst );

  my $base = determine_base( $ipchain );

  # Check masquerading parameter.
  $masq = NOMASQ unless defined $masq;

 SWITCH:
  for ("$src_kind-$dst_kind" ) {
    /LOCAL_IP-ANY|LOCAL_IP-REMOTE/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "acct-out" );
      last SWITCH;
    };
    /ANY-LOCAL_IP|REMOTE-LOCAL_IP/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "acct-in" );
      last SWITCH;
    };
    /LOCAL_IMPLIED-LOCAL_IP/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "acct-in" );
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "acct-out" );
      last SWITCH;
    };
    /LOCAL_IP-LOCAL_IMPLIED/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "acct-out" );
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "acct-out" );
      last SWITCH;
    };
    /LOCAL_IP-LOCAL_IP/ && do {
      $ipchain->attribute( Interface => "lo" );
      $ipchain->append( "acct-out" );
      last SWITCH;
    };
    /ANY-REMOTE|LOCAL_IMPLIED-REMOTE/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      $ipchain->append( "acct-out" );
      if ($masq & MASQ ) {
	$ipchain->attribute( Source => $dst_if->{ip} );

	# UDP and TCP gets their ports rewritten
	if ( $base =~ /tcp|udp|syn|ack/ ) {
	  my $saved_ports = $ipchain->attribute( 'SourcePort' );
	  $ipchain->attribute( SourcePort => MASQ_PORTS )
	    unless $masq & MASQNOHIGH;
	  $ipchain->append( "acct-out" );
	  $ipchain->attribute( SourcePort => $saved_ports );
	} else {
	  $ipchain->append( "acct-out" );
	}
	$ipchain->attribute( Source => $src );
      }
      last SWITCH;
    };
    /REMOTE-REMOTE/ && do {
      $ipchain->attribute( Interface => $dst_if->{interface} );
      if ($masq & MASQ ) {
	$ipchain->attribute( Source => $dst_if->{ip} );
	# UDP and TCP gets their ports rewritten
	if ( $base =~ /tcp|udp|syn|ack/ ) {
	  my $saved_ports = $ipchain->attribute( 'SourcePort' );
	  $ipchain->attribute( SourcePort => MASQ_PORTS )
	    unless $masq & MASQNOHIGH;
	  $ipchain->append( "acct-out" );
	  $ipchain->attribute( SourcePort => $saved_ports );
	} else {
	  $ipchain->append( "acct-out" );
	}
	$ipchain->attribute( Source => $src );
      } else {
	$ipchain->append( "acct-out" );
      }
      last SWITCH;
    };
    /REMOTE-ANY|REMOTE-LOCAL_IMPLIED/ && do {
      $ipchain->attribute( Interface => $src_if->{interface} );
      $ipchain->append( "acct-in" );
      if ($masq & UNMASQ ) {
	$ipchain->attribute( Dest => $src_if->{ip} );
	# UDP and TCP gets their ports rewritten
	if ( $base =~ /tcp|udp|syn|ack/ ) {
	  my $saved_ports = $ipchain->attribute( 'DestPort' );
	  $ipchain->attribute( DestPort => MASQ_PORTS );
	  $ipchain->append( "acct-in" );
	  $ipchain->attribute( DestPort => $saved_ports );
	} else {
	  $ipchain->append( "acct-in" );
	}
	$ipchain->attribute( Dest => $dst );
      } else {
      }
      last SWITCH;
    };
    /ANY-ANY|ANY-LOCAL_IMPLIED|LOCAL_IMPLIED-ANY|LOCAL_IMPLIED-LOCAL_IMPLIED/ && do {
      # Out packet
      $ipchain->attribute( Interface => "lo" ); # Loopback
      $ipchain->append( "acct-out" );
      $ipchain->attribute( Interface => $dst_if->{interface} );
      if ($masq & MASQ ) {
	$ipchain->attribute ( Source => $dst_if->{ip} );
	if ($base =~ /tcp|syn|ack|udp/) {
	  my $saved_ports = $ipchain->attribute( 'SourcePort' );
	  $ipchain->attribute( SourcePort => MASQ_PORTS )
	    unless $masq & MASQ_PORTS;
	  $ipchain->append( "acct-out" );
	  $ipchain->attribute( SourcePort => $saved_ports );
	} else {
	  $ipchain->append( "acct-out" );
	}
	$ipchain->attribute( Source => $src );
      } else {
	$ipchain->append( "acct-out" );
      }
      last SWITCH;
    };
    croak __PACKAGE__, ": unknown src/dst combination: $src/$dst\n";
  }
}

1;

=pod

=head1 NAME

Fwctl::RuleSet - Module to add sets of rules to the linux firewall.

=head1 SYNOPSIS

  use IPChains;
  use Fwctl::RuleSet qw(:masq :tcp_rulesets :ports);

  my $chain = new IPChains( Prot       => 'tcp',
			    SourcePort => UNPRIVILEGED_PORTS,
			    DestPort   => 23,
			    )
  accept_tcp_ruleset( $chain, $src, $src_if, $dst, $dst_if, NOMASQ );

=head1 DESCRIPTION

This module contains primitives to add sets of rules to the Linux
packet filtering firewall implementing a particular policy. It is used
primarly by service modules. The module handle all the special cases
for when the src or dst interface is ANY, when masquerading is involved,
when a local ip is implied by the src or dst address. All this logic
has not to be implemented by the service modules, which only have to
specify the kind of packets and the direction of traffic (using the src and
dst paremeter).

There are 5 tags that can be imported from the modules.

=over

=item :masq

Constant used to specify how to handle masquerade.

=item :ports

Constants that refers to range of ports.

=item :tcp_rulesets

Functions that implements policy rulesets for TCP connection.

=item :udp_rulesets

Functions that implements policy rulesets for bidirectional UDP traffic.

=item :ip_rulesets

Funtions that implements policy rulesets for IP traffic. This are the 
primitives on which the tcp and udp rulesets are built.

=back

=head1 :masq

=over

=item NOMASQ

Constant used to represent that the traffic shouldn't be masqueraded.

=item MASQ

Constant use to denote that this traffic will be masqueraded when
going throught the forward chain.

=item UNMASQ

Constant use to denote that traffic should be unmasqueraded when passing
the input chain.

=back

To better understand the way the MASQ and UNMASQ constants works together
lets look at how they would be use to handle a TCP connection.

    accept_ip_rulesets( $chain, $src, $src_if, $dst, $dst_if, MASQ );
    $chain->attribute( SYN => '!' );
    accept_ip_rulesets( $chain, $dst, $dst_if, $src, $src_if, UNMASQ);

=head1 :ports

=over

=item RESERVED_PORTS

Constant that represents the ports 1 through 1023.

=item UNPRIVILEGED_PORTS

Constant that represents the ports 1024 through 65535.

=item MASQ_PORTS

Constant that represents the ports used when masquerading a
connection : 61000 through 65096.

=back

=head1 :ip_rulesets

This tags imports three functions that are the primitives on which
the  others are built. All src or dst can be classified in one of
four category.
=over

=item ANY

Source or destination is any address on any interface.

=item LOCAL_IP

Source or destination is a local interface

=item LOCAL_IMPLIED

Source or destination implied a local interface. Example of those
includes a broadcast address of a local interface or network address
of a local interface.

=item REMOTE

Source or destination doesn't imply a local IP.

=back

So this means a total of 16 combination of source and destination address.
Add the parameter MASQ,UNMASQ and NOMASQ and you got 48 possibilities. Those
usually can be reduced to between 7 and 16 cases depending on the policy
you want to handle. (REJECT, DENY, ACCEPT or ACCOUNT). The following
functions handle all those possibilities for you, and adds the appropriate
rules with address and interface specification to the appropriate chains.

=over 

=item accept_ip_ruleset($chain,$src,$src_if,$dst,$dst_if,$masq)

Adds the necessary rules to accept the kind of traffic specified by
the $chain parameter.

=over

=item $chain

IPChains objects that contains the prototypes of the rules to add to the
firewall. Source, Dest and Interface parameter are overwritten by the
function.

=item $src

The source address of the packet.

=item $src_if

The interface associated to the $src address.

=item $dst

The destination address of the packet.

=item $dst_if

The interface associated to the $dst address.

=item $masq

How the packet should be masqueraded.

=back

Usually the $src, $src_if, $dst and $dst_if packets are not modified
by the service modules and are those passed by the Fwctl module. Or
the module will switch them (dst becomes src), or change them because
the protocol uses broadcast or other stuff.

=item block_ip_ruleset( $chain, $src, $src_if, $dst, $dst_if )

This primitive handles both REJECT and DENY policies. The parameter
have the same meaning as in the accept_ip_ruleset() function.

=item account_ip_ruleset( $chain, $src, $src_if, $dst, $dst_if )

This primitive handles the ACCOUNT policy. The parameter
have the same meaning as in the accept_ip_ruleset() function.

=back

=head1 :tcp_rulesets

This tags imports three functions: accept_tcp_ruleset(),
block_tcp_ruleset() and account_tcp_ruleset() which have the same
parameters and semantics as their *_ip_ruleset() counterpart.
They are indeed implemented in terms of these.

The difference is that the $chain parameter can only be used to
represent a TCP connection. The functions will add rules for the
client and server side of the connection with the SYN and ACK flags
handled properly.

=head1 :udp_rulesets

This tags imports three functions: accept_udp_ruleset(),
block_udp_ruleset() and account_udp_ruleset() which have the same
parameters and semantics as their *_ip_ruleset() counterpart.
They are indeed implemented in terms of these.

These functions will add rules to handle client / server UDP connection.
It like calling the *_ip_ruleset() functions two times with the
src and dst inversed (the SourcePort and DestPort are naturally also
inversed).


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

fwctl(8) Fwctl(3) IPChains(3)

=cut

