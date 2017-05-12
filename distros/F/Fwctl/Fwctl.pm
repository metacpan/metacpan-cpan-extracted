#
#    Fwctl.pm - Module to control the linux kernel firewall with high level rules.
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

package Fwctl;

use strict;
use vars qw( $VERSION $PORTFW $IPCHAINS );
use Carp;

BEGIN {
    $VERSION = '0.28';

    eval { use IPChains::PortFW; new IPChains::PortFW; };
    $PORTFW = 1 unless $@;

    # Look for ipchains
    ($IPCHAINS) = grep { -x "$_/ipchains" } split /:/, "/sbin:/bin:/usr/sbin:/usr/bin:$ENV{PATH}";
    die ( "Couldn't find ipchains in PATH ($ENV{PATH})\n" ) unless $IPCHAINS;
    $IPCHAINS .= "/ipchains";
}

# Preloaded methods go here.
use Net::IPv4Addr 0.10 qw(:all);
use Getopt::Long;
use Fcntl qw( :flock );
use IPChains;


# Constants
use constant INTERFACES_FILE => '/etc/fwctl/interfaces';
use constant ALIASES_FILE   => '/etc/fwctl/aliases';
use constant RULES_FILE     => '/etc/fwctl/rules';

use constant SERVICES_DIR   => [ "/etc/fwctl/services" ];
use constant ACCOUNTING_FILE => '/var/log/fwctl_acct';


my @REQUIRED_METHODS = qw( valid_options block_rules account_rules accept_rules );
my %ACTIONS = map { $_ => 1; } qw( ACCEPT DENY REJECT ACCOUNT );
my @STANDARD_OPTIONS = ( "masq!", "log!", "copy!", "src=s", "dst=s",
			 "name=s", "account", "mark=i", "portfw:s" );

sub new {
  my $proto = shift;
  my $class = ref( $proto) || $proto;

  my $self = bless {
		    interfaces_file => INTERFACES_FILE,
		    aliases_file    => ALIASES_FILE,
		    rules_file	    => RULES_FILE,
		    services_dir    => SERVICES_DIR,
		    accounting_file => ACCOUNTING_FILE,
		    interfaces	    => {},
		    aliases	    => {},
		    services	    => {},
		    rules	    => [],
		    account	    => 0,
		    copy	    => 1,
		    log		    => 1,
		    mark	    => 0,
		    default	    => 'DENY',
		    @_,		    # Overrides any default with arguments
	      }, $class;

  # Add services dir to @INC
  eval( join( " ", "use lib qw(", @{ $self->{services_dir} },");" ) );
  die __PACKAGE__, ": error while adding services dir to \@INC: $@" if $@;

  carp __PACKAGE__, "default must be one of ACCEPT, REJECT or DENY"
    unless $self->{default} =~ /^ACCEPT|REJECT|DENY$/;

  carp __PACKAGE__, "mark not an integer" unless $self->{mark} =~ /^\d+$/;

  warn __PACKAGE__, "default policy is not REJECT or DENY"
    if $self->{default} eq "ACCEPT";

  # Read all configuration files
  $self->read_interfaces();
  $self->read_aliases();
  $self->read_rules();

  # Return ourselve
  $self;
};

# Get or sets the interfaces.
sub interfaces {
    my $self = shift;

    if (@_) {
	# Must get an array of interface references
	$self->{interfaces} = { map { $_->{name} => $_ } @_ };
	$self->{routes} = undef;
    }

    # Returns an array of references
    values %{$self->{interfaces}};
}

sub routes {
    my $self = $_[0];

    unless ($self->{routes}) {
	my @routes = ();

	foreach my $if ( $self->interfaces ) {
	    # Don't include the ANY interface.
	    next if $if->{name} eq "ANY";

	    # Host route to the interface.
	    unless ( $if->{netmask} == 32 ) {
		push @routes, [ $if, { network => $if->{ip},
				       netmask => 32 } ];
	    }

	    # Directly connected net.
	    push @routes, [ $if, $if ];

	    # Other connected nets.
	    push @routes, map { [$if, $_ ] } @{$if->{other_nets}};
	}

	# Sort from the most specific to the least specific.
	$self->{routes} = [ sort { $b->[1]{netmask} <=> $a->[1]{netmask} } @routes ];
    }

    @{ $self->{routes} };
}

# Get or set an interface by name
sub interface {
  my ($self, $name) = @_;

  if ( @_ == 3  ) {
      $self->{interfaces}{$name} = $_[2];
      $self->{routes} = undef;
  }

  $self->{interfaces}{$name};
}

# Get or set an alias
sub alias {
  my $self = shift;
  my $name = shift;

  $self->{aliases}{$name} = shift if @_;

  $self->{aliases}{$name};
}

# Expand an alias recursively into interface and parsed IP.
sub expand {
  my ( $self, $string, $recurs_lvl ) = @_;
  $recurs_lvl ||= 0;
  $recurs_lvl++;
  die __PACKAGE__, ": too much alias recursion\n" if $recurs_lvl > 15;
  my @expansion = ();
  for my $s (split /\s+/, $string ) {
    if ( $self->alias($s) ) {
      push @expansion, $self->expand( $self->alias($s), $recurs_lvl );
    } else {
	if ( $s eq "INTERNET" ) {
	    push @expansion, [ "0.0.0.0/0", $self->interface( 'EXT' ) ];
	} elsif ( $s eq "ANY" ) {
	    push @expansion, [ "0.0.0.0/0", $self->interface( 'ANY' ) ];
	} else {
	    my ( $ipv4, $if ) = $s =~ m!([0-9./]+)(?:\((\w+)\))?!;
	    if ( defined $if ) {
		$if = $self->interface( $if );
		die "invalid interface spec in alias expansion: $if\n" unless $if;
	    }
	    eval {
		$ipv4 = ipv4_parse( $ipv4 );
	    };
	    die "invalid ip address : $ipv4\n" if $@;
	    $if = $self->find_interface( $ipv4 ) unless defined $if;
	    push @expansion, [$ipv4, $if];
	}
    }
  }
  return @expansion;
}

# Get a service handler. The service handler is loaded
# dynamically if it is not already defined.
sub service {
  my ($self,$name) = @_;

  unless ($self->{services}{$name} ) {
    # Load because it is not loaded

    $self->{services}{$name} =
      eval "use Fwctl::Services::$name; new Fwctl::Services::$name;";

    if ($@) {
      # No service defined as module.
      # Try to cook a generic TCP one.
      my $port = getservbyname $name, 'tcp';
      unless ($port) {
	my $new_serv = $name;
	$new_serv =~ s/_/-/g;
	$port = getservbyname $new_serv, 'tcp';
      }
      # If no port could be find, then warn
      unless ($port) {
	warn __PACKAGE__, ": error while loading service $name: $@\n";
	return undef;
      }
    $self->{services}{$name} =
      eval "package Fwctl::Services::$name;" . q{

use vars qw(@ISA);
use Fwctl::Services::tcp_service;

BEGIN { @ISA = qw(Fwctl::Services::tcp_service); }

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(@_);
  $self->{port} = $port;
  bless $self,$class;
}

} . "new Fwctl::Services::$name;";

	if ($@) {
	    warn __PACKAGE__, ": error while defining tcp_service $name: $@";
	    return undef;
	}
    }
  }

  $self->{services}{$name};
};

sub accounting_file {
  my $self = shift;
  if (@_) {
    $self->{accounting_file} = shift;
  }
  $self->{accounting_file};
}

# Get the accounting rules only
sub account_rules {
  my $self = shift;

  grep { $_->{action} eq "ACCOUNT" } @{$self->{rules}};
}

# Get a reference to the array containing all 
# the firewall rules
sub rules {
  my $self = shift;

  $self->{rules};
}

# Given an host, find the alias to which this one is
# related. We return the most specific one. Least specific is
# INTERNET.
sub find_host_alias {
    my ( $self, $ip ) = @_;

    # Try to find the alias as an IP
    $ip =~ s/\.0+(\d)/\.$1/g; # Normalize .001 -> .1 .000 .0
    while ( my ( $alias, $expansion ) = each %{$self->{aliases}} ) {
	my @aliases = split /\s+/, $expansion;
	# We don't need to recurse since recursive alias are necesserarly
	# less specific
	foreach my $a ( @aliases ) {
	    $a =~ s/\.0+(\d)/\.$1/g;	# Canonicalize
	    $a =~ s/\(\w+\)//g;		# Remove interface spec
	    return $alias if $a eq $ip;
	}
    }

    # Try to find as included in a subnet.
    while ( my ( $alias, $expansion ) = each %{$self->{aliases}} ) {
	# Skip ANY_ alias
	next if index ( $alias, "ANY") == 0;
	my @aliases = split /\s+/, $expansion;

	foreach my $a ( @aliases ) {
	    $a =~ s/\(\w+\)//g;		# Remove interface spec
	    # Try not to compare aliase
	    next unless $a =~ m!^[\d/.]+$!;
	    return $alias if ipv4_in_network( $a, $ip );
	}
    }

    # Default
    return 'INTERNET';
}

# Given an IP, network or whatever, find the target
# interface.
sub find_interface {
    my ($self,$ip) = @_;

    # Magic interfaces
    return $self->interface('ANY') if $ip =~ /ANY/i;
    return $self->interface('EXT') if $ip =~ /INTERNET/i;

    # Check each interface to see if the ip
    # is part of a network
    foreach my $route ( $self->routes ) {
	my ( $if, $net ) = @$route;

	# Check if they are on the same network
	return $if if ipv4_in_network( $net->{network},
				       $net->{netmask},
				       $ip
				     );

    }

    # Default is Internet
    return $self->interface('EXT');
}

# This breaks in regards to virtual interface
sub find_interface_by_dev {
    my ( $self, $dev ) = @_;

    foreach my $if ( $self->interfaces ) {
	return $if->{name} if $if->{interface} eq $dev;
    }

    # Not found
    return undef;
}

sub reset_fw {
  my $self = shift;

  # Dump old account
  $self->dump_acct;

  # Sets default policies
  my $fwctl = IPChains->new( Rule => $self->{default} );
  $fwctl->set_policy( "input" );
  $fwctl->set_policy( "forward" );
  $fwctl->set_policy( "output" );

  # Setting the default policy, prevents
  # a vulnerability window when we reset the
  # firewall.
  #
  # Some usually not blocked packets, will be
  # blocked. Some usually logged packets won't be.

  # Flush standard chains
  $fwctl->clopts;
  $fwctl->flush( "input" );
  $fwctl->flush( "output" );
  $fwctl->flush( "forward" );

  # Flush the user chains
  for ($fwctl->list_chains) {
    $fwctl->flush( $_ );
  }

  # ... and delete them
  for ($fwctl->list_chains) {
    $fwctl->del_chain( $_ );
  }

  # If portfw is available flush it
  if ( $PORTFW ) {
      IPChains::PortFW->new()->flush;
  }

  # Create accounting chains...
  for (qw(in fwd out )) {
    $fwctl->new_chain( "acct-$_" );
  }

  # ... and add them to the firewall
  $fwctl->attribute( Rule => "acct-in" );
  $fwctl->append( "input" );
  $fwctl->attribute( Rule => "acct-fwd" );
  $fwctl->append( "forward" );
  $fwctl->attribute( Rule => "acct-out" );
  $fwctl->append( "output" );

  # Create the protocol optimizing chains...
  $fwctl->clopts;
  for my $proto (qw( tcp udp icmp all syn ack oth )) {
    for my $dir ( qw( -in -fwd -out ) ) {
      $fwctl->new_chain( $proto . $dir );
    }
  }

  # ... add them to the firewall
  for my $proto (qw(icmp tcp udp)) {
    $fwctl->attribute( Prot => $proto );
    $fwctl->attribute( Rule  => "$proto-in" );
    $fwctl->append( "input" );
  }
  for my $proto (qw(icmp tcp udp)) {
    $fwctl->attribute( Prot => $proto );
    $fwctl->attribute( Rule  => "$proto-fwd" );
    $fwctl->append( "forward" );
  }
  for my $proto (qw(icmp tcp udp)) {
    $fwctl->attribute( Prot => $proto );
    $fwctl->attribute( Rule  => "$proto-out" );
    $fwctl->append( "output" );
  }

  # Add other and all
  $fwctl->attribute( Prot => undef );
  for my $proto ( qw(oth all) ) {
      $fwctl->attribute( Rule  => "$proto-in" );
      $fwctl->append( "input" );

      $fwctl->attribute( Rule  => "$proto-fwd" );
      $fwctl->append( "forward" );

      $fwctl->attribute( Rule  => "$proto-out" );
      $fwctl->append( "output" );
  }

  # The all optimisation may cause some
  # non intuitive behavior regarding the
  # final outcome of a packet from the
  # order of the rules. In clear, all
  # ALL rules with be evaluated after
  # other rules with more specific
  # protocol.

  # TCP with SYN or ACK
  $fwctl->attribute( Prot => 'tcp');
  for my $dir (qw(in out fwd)) {
    # SYN
    $fwctl->attribute( Rule => "syn-$dir");
    $fwctl->attribute( SYN => 1 );
    $fwctl->append( "tcp-$dir" );
    # ACK
    $fwctl->attribute( Rule => "ack-$dir");
    $fwctl->attribute( SYN => '!' );
    $fwctl->append( "tcp-$dir" );
  }

  $self->init_acct;
}

sub init_acct {
  my $self = shift;

  # Create rules accounting chains
  my $fwctl = IPChains->new;
  my $acct_chain = IPChains->new;
  for ($self->account_rules) {
    $fwctl->new_chain( $_->{account_chain} );
    $acct_chain->append( $_->{account_chain});
  }

  my $file = $self->{accounting_file};
  open ACCT_FILE, ">>$file"
    or die __PACKAGE__, ": can't open accounting file ", $file,
      ": $!\n";
  my $success = 0;
  for (0..10) {
    $success = flock ACCT_FILE,LOCK_EX;
    last if $success;
    sleep 3;
  }
  die __PACKAGE__, ": couldn't obtain lock on accounting file ", 
    $file, ": $!\n" unless $success;

  my $timestamp = time;
  for my $rule ($self->account_rules) {
    print ACCT_FILE join( " ", $timestamp, $rule->{account_chain}, 0, 0,
			  $rule->{options}{name} ), "\n";
  }
  flock ACCT_FILE, LOCK_UN;
  close ACCT_FILE;
}

sub dump_acct {
  my $self = shift;

  my $timestamp = time;

  my %chains = ();
  open IPCHAINS, "$IPCHAINS -Z -L -v -x -n|"
    or die __PACKAGE__, ": couldn't fork: $!\n";
  while (<IPCHAINS>) {
    my $chain = undef;
    if ( ($chain) = /^Chain (acct\d{4})/) {
      #Start of an accounting chain
      <IPCHAINS>;       # Discard header
      my $acct = <IPCHAINS>;
      my ($pkts,$bytes) = $acct =~ /^\s*(\d+)\s*(\d+)/;
      $chains{$chain} = [ $pkts, $bytes ];
    }
  }
  close IPCHAINS
    or die __PACKAGE__, ": error in ipchains: $?\n";

  my $file = $self->{accounting_file};
  open ACCT_FILE, ">>" . $file
    or die __PACKAGE__, ": can't open accounting file ", $file,
      ": $!\n";
  my $success = 0;
  for (0..10) {
    $success = flock ACCT_FILE,LOCK_EX;
    last if $success;
    sleep 3;
  }
  die __PACKAGE__, ": couldn't obtain lock on accounting file ", 
    $file, ": $!\n" unless $success;

  for my $rule ($self->account_rules) {
    if ( $chains{$rule->{account_chain} } ) {
      print ACCT_FILE join( " ", $timestamp, $rule->{account_chain},
			    @{$chains{$rule->{account_chain}}},
			    $rule->{options}{name}), "\n";
    }
  }
  flock ACCT_FILE, LOCK_UN;
  close ACCT_FILE;
}

# Configure the firewall
sub configure {
  my $self = shift;

  $self->reset_fw;

  # Add user rules
 RULE:
  foreach my $rule ( @{$self->{rules} } ) {
    my $action  = $rule->{action};
    my $service = $self->service( $rule->{service} );
    my $options = $rule->{options};
  SRC:
    foreach my $src_spec ( @{$rule->{src}} ) {
    DST:
      foreach my $dst_spec ( @{$rule->{dst}} ) {
	  my ( $src, $src_if ) = @$src_spec;
	  my ( $dst, $dst_if ) = @$dst_spec;

      SWITCH:
	for ($action) {
	  /DENY|REJECT/ && do {
	    $service->block_rules( $action, $src, $src_if,
				   $dst, $dst_if, $options );
	    last SWITCH;
	  };
	  /ACCEPT/ && do {
	    $service->accept_rules( $action, $src, $src_if,
				   $dst, $dst_if, $options );
	    last SWITCH;
	  };
	  /ACCOUNT/ && do {
	    $service->account_rules( $rule->{account_chain},
				     $src, $src_if,
				     $dst, $dst_if, $options );
	    last SWITCH;
	  };
	  die __PACKAGE__,  ": unknown action $action\n" ;
        } #SWITCH
      } #DST
    } #SRC
  } #RULE

  # Then add the logging rules
  my $fwctl = IPChains->new();
  $fwctl->attribute( Rule => $self->{default} );
  if ( $self->{log} ) {
      $fwctl->attribute( Log =>  1 );
  }
  if ( $self->{copy} ) {
      $fwctl->attribute( Output => 1 );
  }
  if ( $self->{mark}) {
      $fwctl->attribute( Mark => $self->{mark} );
  }
  $fwctl->append( "input" );
  $fwctl->append( "forward" );
  $fwctl->append( "output" );
}

sub stop {
  my $self = shift;

  $self->reset_fw;

  # Enable looback
  my $loopback = IPChains->new( Rule => 'ACCEPT', Interface => "lo" );
  $loopback->insert( "input" );
  $loopback->insert( "output" );
}

sub really_flush_chains {

    # Sets default policies
    my $fwctl = IPChains->new( Rule => 'ACCEPT' );
    $fwctl->set_policy( "input" );
    $fwctl->set_policy( "forward" );
    $fwctl->set_policy( "output" );

    # Flush standard chains
    $fwctl->clopts;
    $fwctl->flush( "input" );
    $fwctl->flush( "output" );
    $fwctl->flush( "forward" );

    # Flush the user chains
    for ($fwctl->list_chains) {
	$fwctl->flush( $_ );
    }

    # ... and delete them
    for ($fwctl->list_chains) {
	$fwctl->del_chain( $_ );
    }
}

sub flush_chains {
  my $self = shift;

  # Dump old account
  $self->dump_acct;
  $self->really_flush_chains;

}

# Read the interface specifications
sub read_interfaces {
  my $self = shift;
  my $file = $self->{interfaces_file};

  # The loopback device
  $self->interface( 'LOCAL', { name	 => 'LOCAL',
			       interface => 'lo',
			       ip	 => '127.0.0.1',
			       network   => '127.0.0.0',
			       broadcast => '127.255.255.255',
			       netmask	 => '8',
			     });

  # The ANY device
  $self->interface( 'ANY', {
			    name      => 'ANY',
			    interface => "",
			    ip	      => "0.0.0.0/0",
			    network   => "0.0.0.0",
			    broadcast => "255.255.255.255",
			    netmask   => "0",
			   });

  open ( INTERFACES, $file )
    or die "fwctl: can't open file $file\n";

  while (<INTERFACES>) {
    next if /^\s*#/;    # Skip comments 
    next if /^\s*$/;	# Skip blank lines
    chomp;

    my ($name,$if,$rest) =
      m@(\w+)\s+([\w+]+)\s*([^#]+)?@;
    die <<ERROR unless $name and $if and $rest;
fwctl: invalid interface specification at line $. of file $file
ERROR
    # Canonicalize interface -> remove aliases.
    $if =~ s/:.+//g;

    my @networks = ();
    foreach (split /\s+/, $rest) {
      eval {
	my ($ip,$msklen) = ipv4_parse( $_ );
	my ($network) = (ipv4_network($ip,$msklen))[0];
	push @networks, {
			 ip	    => $ip,
			 network    => $network,
			 netmask    => $msklen,
			 broadcast  => ipv4_broadcast($network, $msklen),
			};
      };
      warn __PACKAGE__, ": bad interface specification at line $. of file $file: $@\n"
	if $@;
    }

    my $spec = shift @networks;
    $self->interface($name, {
			     name	=> $name,
			     interface	=> $if,
			     %$spec,
			     other_nets  => \@networks,
			    });
  }
  close INTERFACES;
  die "fwctl: no EXT interface defined."
    unless defined $self->interface('EXT');
}

# Read in the aliases
sub read_aliases {
  my $self = shift;
  # Defined common aliases for each of the interface
  foreach my $if ( $self->interfaces ) {
    my $name	    = uc $if->{name};
    my $ip_alias    = $name . "_IP";
    my $net_alias   = $name . "_NET";
    my $rem_alias   = $name . "_REM_NETS";
    my $nets_alias  = $name . "_NETS";
    my $bcast_alias = $name . "_BCAST";
    my $net = $if->{network} . "/" . $if->{netmask} . "(" . $name . ")";
    my $nets = [ $net  ];
    foreach my $n ( @{$if->{other_nets} }) {
      push @$nets, $n->{network} . "/" . $n->{netmask} . "(" . $name . ")";
    }
    $self->alias($net_alias, $net  );
    $self->alias($ip_alias,  $if->{ip} . "(" . $name . ")" );
    $self->alias($nets_alias, join( " ", @$nets ) );
    $self->alias($rem_alias, join( " ", @{$nets}[ 1 .. $#$nets ] ) );
    $self->alias( $bcast_alias, $if->{broadcast}, "(" . $name . ")" );
  }

  # Read in the additional aliases
  my $file = $self->{aliases_file};
  open ( ALIASES, $file )
    or die "fwctl: can't open file $file: $!\n";
  while (<ALIASES>) {
    next if /^\s*#/;    # Skip comments 
    next if /^\s*$/;	# Skip blank lines
    chomp;

    my ( $alias, $exp ) = /^\s*(\w+)\s*[=:]+\s*([^#]+)/;
    die "fwctl: invalid alias at line $. of file $file\n"
      unless $alias and $exp;
    $self->alias( $alias, $exp);
  }
  close ALIASES;
}

# Read in the firewall rules
sub read_rules {
  my $self = shift;
  my $file = $self->{rules_file};
  my $error = 0;
  open ( RULES, $file ) or die "fwctl: can't open file $file: $!\n";
 RULE:
  while (<RULES>) {
    next if /^\s*#/;    # Skip comments
    next if /^\s*$/;	# Skip blank lines
    chomp;

    # When loop is sucessful it is decrement. Must be 0 when the loop quit.
    $error++;
    my ($action,$service,@opts) = split;

    # Validate rule
    unless ( $action and $service ) {
      warn __PACKAGE__, ": incomplete rule at line $. of file $file\n";
      next RULE;
    }

    $action = uc $action;
    unless ( $ACTIONS{ $action } ) {
      warn __PACKAGE__, ": unknown action $action at line $. of file $file\n";
      next RULE;
    }

    unless ( $self->service( $service ) ) {
      warn __PACKAGE__, ": unknown service $service at line $. of file $file\n";
      next RULE;
    }

    # Parse options
    my %options	      = ( masq	    => 0,
			  mark	    => 0,
			  copy	    => 0,
			  account   => 0,
			);
    $options{log}     = $action =~ /REJECT|DENY/ ? 1 : 0;
    {
      local @ARGV = @opts;
      local $SIG{__WARN__} = 'IGNORE';

      GetOptions( \%options, @STANDARD_OPTIONS,
		  $self->service($service)->valid_options )
	or do {
	  warn __PACKAGE__, ": error while parsing options in service $service\n";
	  next RULE;
	};

      if (@ARGV ) {
	warn __PACKAGE__, ": unknown options", join( ",", @ARGV ), "\n";
	next RULE;
      }
      if ( $options{portfw} && ! $PORTFW ) {
	  warn __PACKAGE__, ": can't use portfw because IPChains::PortFW ",
	    "isn't available at line $.\n";
	  next RULE;
      }
      if ( ($options{masq} || exists $options{portfw} ) && 
	   $action =~ /reject|deny/i ) 
      {
	warn __PACKAGE__, ": useless use of masq/portfw option at line $.\n";
	next RULE;
      }
      if ($options{masq} && exists $options{portfw} ) {
	warn __PACKAGE__, ": conflicting use of masq and portfw at line $.\n";
	next RULE;
      }
      if ($options{account} && $action eq "ACCOUNT" ) {
	warn __PACKAGE__, ": can't use account option with ACCOUNT action at line $.\n";
	next RULE;
      }
    };

    # Parse portfw
    my ($portfw,$portfw_if) = ( $options{portfw} );
    if ( $portfw ) {
	eval {
	    ($portfw, $portfw_if ) = @{($self->expand( $portfw ))[0]};
	    $options{portfw} = $portfw;
	};
	if ( $@ ) {
	    warn __PACKAGE__, ": invalid aliase expansion in portfw at line $.: $@\n";
	    next RULE;
	}

	if ( $portfw_if->{name} eq 'ANY' ) {
	    warn __PACKAGE__, ": can't use ANY interface for portfw at line $.\n";
	    next RULE;
	}
	if ( $portfw_if->{ip} ne $portfw ) {
	    warn __PACKAGE__, ": not a local interface in portfw at line $.\n";
	    next RULE;
	}
    }

    # Parse src
    my @src = ();
    if ( $options{src} ) {
	eval {
	    @src = $self->expand( $options{src} );
	};
	if ( $@ ) {
	    warn __PACKAGE__, ": error in src specification at line $.: $@\n";
	    next RULE;
	}
	# Check that all the sources are valid for portforwarding
	if ( defined $portfw  ) {
	    foreach my $s ( @src ) {
		if ( $s->[1]{name} eq 'ANY' ) {
		    warn __PACKAGE__, ": can't use portfw with ANY src at line $.\n";
		    next RULE;
		} elsif ( $portfw && $s->[1]{interface} ne $portfw_if->{interface} ) {
		    warn __PACKAGE__, ": src of portfw doesn't match interface at line $.\n";
		    next RULE;
		}
	    }
	}
	delete $options{src};
    } else {
	if ( defined $portfw ) {
 	    warn __PACKAGE__, ": can't use portfw with ANY src at line $.\n";
	    next RULE;
	} else {
	    push @src, $self->expand( 'ANY' ) ;
	}
    }

    # Parse dst
    my @dst = ();
    if ( $options{dst} ) {
	eval {
	    @dst =$self->expand( $options{dst} );
	};
	if ( $@ ) {
	    warn __PACKAGE__, ": error in dst specification at line $.: $@\n";
	    next RULE;
	}
	# Make sure that all destination are compatible with portfw
	if ( defined $portfw ) {
	    foreach my $d ( @dst ) {
		# With portfw only host can be used as dst.
		eval {
		    my ($ip,$cidr) = ipv4_parse( $d->[0] );
		    unless ( ! defined $cidr || $cidr == 32 ) {
			warn __PACKAGE__, ": can only use host in dst with portfw $.\n";
			next RULE;
		    }
		};
		if ($@) {
		    warn __PACKAGE__, ": error in dst specification at line $.: $@\n";
		    next RULE;
		}
	    }
	}
	delete $options{dst};
    } else {
	if ( defined $portfw ) {
 	    warn __PACKAGE__, ": can't use portfw with ANY dst at line $.\n";
	    next RULE;
	} else {
	    push @dst, $self->expand( 'ANY' );
	}
    }

    # Create standard IPChains options
    my %ipchains_opts	= ();
    $ipchains_opts{Mark}   = $options{mark} if $options{mark};
    $ipchains_opts{Log}    = 1		    if $options{log};
    $ipchains_opts{Output} = $options{copy} if $options{copy};
    $options{ipchains} = \%ipchains_opts;

    # Name of accounting chain
    my $chain = sprintf 'acct%04d', $self->{account}++
      if $action eq "ACCOUNT" or $options{account};

    # OK this seems ok.
    push @{$self->{rules}}, {
			     action  => $action,
			     service => $service,
			     options => \%options,
			     src     => \@src,
			     dst     => \@dst,
			     ($action eq "ACCOUNT" ? 
			      (account_chain => $chain ) : () ),
			    };

    # Add automatic accounting rule
    if ($options{account}) {
	my $new_options = { %options };
	# No need to log, copy or output packets twice.
	delete $new_options->{ipchains};
      push @{$self->{rules}}, {
			       action	     => "ACCOUNT",
			       service	     => $service,
			       options	     => $new_options,
			       src	     => \@src,
			       dst	     => \@dst,
			       account_chain => $chain,
			      };

    }
    $error--;
  }
  close RULES;
  die __PACKAGE__, ": error while reading rules. Aborting\n" if $error;
}

1;
__END__
=pod

=head1 NAME

Fwctl - Perl module to configure the Linux kernel packet filtering firewall.

=head1 SYNOPSIS

  use Fwctl;

  my $fwctl = new Fwctl( %opts );
  $fwctl->dump_acct;
  $fwctl->reset_fw;
  $fwctl->configure;

=head1 DESCRIPTION

Fwctl is a module to configure the Linux kernel packet filtering firewall
using higher level abstraction than rules on input, output and forward
chains. It supports masquerading and accounting as well.

Why Fwctl ? Well, say you are the kind of paranoid firewall
administrator which likes his firewall's rules tight. Very tight. Say
the kind, that likes to distinguish between a SYN and ACK packet when
accepting a TCP connection (anybody configuring packet filters should
care about that last point), or like to specify the interface name on
each rules. (Whether this is really need, or such a stance is
relevant, is not the point.) How would such an administrator proceed ?
First of all you deny everything on all interfaces and on all chains
(input, forward and output) and turn on logging. Now starting from
this configuration (in which Fwctl puts the firewall on
initialization), say you want to enable ping from the internal network
to the internal ip. What rules do you need ? You need a rule on the
input chain to accept the echo-request packet and a rule on the output
chain to accept the echo-reply request. Right ? Well, what about the
loopback. For sure, when we say from local net to local ip, this imply
local ip to local ip ? Then you add a rule to the output chain with
the loopback interface, and a rule on the input rule to the loopback
chain. And we didn't even start forwarding yet ! Add masquerading to
the lot and multi connections protocols like FTP and you got something
unmanageable. So you start accepting things you shouldn't to get your
job done and in the end your filters look like emmenthal.

Fwctl handles all the complexity of this, so that when you say 

accept ftp -src FTP_PROXY -dst INTERNET -noport

you don't accept too much of what you didn't intend. (Well you just opened
arbitrary TCP connections to unprivileged ports on the Internet from your
proxy server, but that's because of the FTP protocol, not because your 
cheating on the firewall rules.)

Fwctl works with entity known as service. A service can be ftp, netbios,
ping or anything else. The service abstraction handles all the communication
necessary for that application. (The UDP and TCP communication in DNS, or
the control, data and passive connections for FTP.)

Additionally, to handle all the special case with ANY specification,
when the src of dst imply a local IP, or masquerading, in short for
Fwctl to be able to deduce the interface implicated by the src and dst
portion of a rules you need to provide it with your network topology.
Fwctl must guess from your topology the routing decision that will be
made in the kernel. In the best of worlds, Fwctl should contains the
same routing algorithm as the one in the kernel. Well, it doesn't so
if you are using fancy routing feature, Fwctl won't work. In fact, it
can only handle something equivalent to simple static routing. You
have been warned.

So in short, to configure your packet filters with Fwctl you need to

=over

=item 1

Define your network topology using the F<interfaces> file.

=item 2 

(Optional) Define meaningful aliases for hosts and networks which are
part of your configuration.

=item 3

Implement your security policy using high level abstract rules in the
F<rules> file.

=back

Finally, Fwctl is extensible. You can easily add services modules
using the Fwctl::RuleSet module which contains all the primitive
you need to handle all the special cases involved in the input, 
forward and output chain selection.

=head1 CONFIGURATION

Fwctl configures the Linux kernel packet filtering firewall using three
files: the F<interfaces> file that describes your network topology, the
F<aliases> file that can contains meaningful aliases and the F<rules>
files that contains the services policy for the firewall.

=head2 TOPOLOGY

The F<interfaces> file (default to F</etc/fwctl/interfaces>)
describes your firewall topology. This is a text file in which comments
(starting by a # and continuing until the end of line) and blank lines are
ignored.

Each non blank, non comment lines is an interface specification. The
format of the interfaction specification is

    NAME    INTERFACE	IP/MASK	    [NETWORK]*

=over

=item NAME

This is the name of the interface. It can be anyting. (Well please keep to
alphanumeric characters plus underscore). There are two reserved names and
a magical one. LOCAL refers to the loopback interface and shouldn't be 
redefined. ANY refers to a interface matching all the defined interfaces.
You should defined at least an interface named EXT which corresponds to the
interface connected to the default route. This is the interface on which 
Internet traffic usually come and go.

=item INTERFACE

This should be set to the kernel interface name. (eth0, ppp0, tunl0, etc.)
You may specifiy here alias interface (eth0:0) but the Fwctl will
canonicalize the name to the master interface (eth0) to match the way the
kernel 2.2 use them.

=item IP/MASK

This is the IP address and Netmask of the interface. The netmask can be
specified in either netmask notation (255.255.255.0) or CIDR notation (24).

=item NETWORKS

This is an optional space separated list of IP/MASK networks connected
to this interface. This is to handle internal network connected to WAN link.

=back

The F<interfaces> file should correspond to your firewall network
configuration. It should adequatly represent its runtime interface and
routing configuration or this module is useless.

=head2 ALIASES

The F<aliases> file contains meaningful aliases for use in the F<rules>
file.

Comments (starts with # and continues untill the end of line) and blank
lines are ignored.

Alias line are of the form :

    ALIAS [:=]+ EXPANSION

=over

=item ALIAS

This is the mnemonic alias. For example, you could use
MAIL_SERVER, CORPORATE_OFFICE, aNotSoUsefulAlias, etc. Please restrict
yourself to alphanumeric character plus underscore. And be sure to
read the predefined aliases section.

=item EXPANSION

This is what the alias expands to. This can be a space separated list
of host or network specification or other alias.

The host or network expansion can also be tagged with an interface
name which specifies which interface is associated with that alias and
that will be use for routing logic. If you don't specify an interface
Fwctl will figure out which interface is associated to the host or
network using conventional routing logic. Be warned though that if you
have interfaces that shares the same IP or have the same network
attached if won't do probably what you intended. If all interfaces
have distinctive IP and networks it will be probably fine tough.

Example :

    VPN_CLIENT1 = 192.168.2.10(VPN1)


=back

Aliases are recursively expanded. Please avoid infinite recursion or you
will get a complaint at parse time.

Here is a list of predefined aliases. (All those aliases are associated
with their interface for routing pupose).

=over

=item INTERNET

This alias represents any host or network connected through the EXT 
interface.

=item ANY

This alias represents any host or network connected through any interface.

=item <IF>_IP

The is an alias name IF_IP for each defined interface which corresponds to
the IP address of this interface.

For example, if you have defined the EXT interface and a INTERNAL interface, 
the aliases LOCAL_IP, EXT_IP and INTERNAL_IP. (Remenber the automatic LOCAL
interface).

=item <IF>_NET

The is an alias name IF_NET for each defined interface which corresponds to
the network attached to this interface.

=item <IF>_BCAST

The is an alias name IF_IP for each defined interface which corresponds to
the broadcast address of this interface.

=item <IF>_REM_NETS

The is an alias name IF_IP for each defined interface which corresponds to
all the networks that are routed through this interface excepted the one
directly connected.

=item <IF>_NETS

The is an alias name IF_IP for each defined interface which corresponds to
all the networks attached to this interface, not only the direct one.

=back

=head2 RULES

The F<rules> file contains your firewall policy implementation. It is a
text file that describes the policy for each services.

As usual, (do I even need to mention it?) comments (starts with # and 
continues until the end of line) and blanks line are ignored.

Rules format is :

    ACTION  SERVICE OPTIONS

=over

=item ACTION

What to do with this service can be one of accept, reject, deny or
account. See POLICY section for explanation.

=item SERVICE

This is the name of the service which is the target of the action. The
service is handled by a module called Fwctl::Services::<service>.pm but
see AUTOMATIC SERVICES.

=item OPTIONS

This is a space separated list of options which further specify what
is the actual policy. Option name starts with - or -- and can be
abbreviated to uniquesess. Some options takes a paremeters some are
flags. Read the doc. These options are module specific but see
STANDARD OPTIONS section.

=back

=head1 POLICY

There are four possible actions for a service. These are ACCEPT, DENY,
REJECT or ACCOUNT. (These are actually case insensitive).

=over

=item ACCEPT

This will accept the service.

=item DENY

This traffic part of this service will be drop without anyone knowing.
(Except probably your logs.)

=item REJECT

Traffic part of this service will be dropped with a proper message being
sent to the originating party.

=item ACCOUNT

Packets part of this service will be counted. This won't accept or deny
the service. Use one of the other three actions to define the actual
fate of this service.

=back

=head1 SERVICE

A service are module that encapsulates the collection of IP traffic
that are part of an application. For example, to accept or account the
FTP service, you must accept two or three TCP connections, the rsh service
uses two. DNS service need 1 TCP connection and an UDP circuit.

The SERVICE abstraction is needed to insulates the administrator from the
idiosyncrasies of the service. Needless to say that the adminstrator should
be familiar with the idiosyncrasies of the service to be able to make an
appropriate security judgement about the service. It's just that it is easier
once the judgement has been made to accept or deny the specific service.

Each service is a perl module named Fwctl::Services::name which knows
the particular IP traffic that is part of this service.

=head2 AUTOMATIC SERVICES

As a convenience to the administrator (and programmer) simple one way
TCP service are automatically created at runtime. For example, this
distribution doesn't contains a telnet service. But since the telnet 
service is only a tcp connection from client to the server's telnet port. 
If you use ACCEPT telnet in your rules, a telnet service is automatically
generated as a subclass of tcp_service with a destination port of telnet.
You could use in this way pop-3, imap or any protocol which has only a 
client/server TCP connection.

=head1 OPTIONS

Each service can defined a number of options but here are the
standard one that each service should implement.

=over

=item --src

Specify the client part of the service. This can be a list of IP or
network addresses, or aliases. Once the aliases are expanded only IP
addresses must remains. When you configure your firewall DNS shouldn't be
available. If you need name, that's what the F<aliases> is for.

If there are more than one IP address, it is equivalent as if you had
specified a different rule with each address. (i.e.: If you have 4
IPs, this is transformed in four rules).

If this option is not present. It is the same as --src ANY.

=item --dst

Specify the server part of the service. The syntax of this option is
identical to the src one.

=item --masq or --nomasq

If this option is set, the firewall will masquerade this service on
behalf of the client. This option is only meaningful with the ACCEPT or
ACCOUNT action.

With the ACCOUNT action it properly account for masqueraded traffic.
That is to say that if you want to accept masqueraded telnet and want to
turn on accounting for this service, you should also use the masq option
to the ACCOUNT action. (Or simply use the account option).

=item --log  or --nolog

This option turn on or off packet header logging for this service.
Default to log for DENY or REJECT action and nolog for ACCEPT and ACCOUNT.

=item --copy or --nocopy

This option turn on or off packet copying to the F</dev/fwmonitor> device
for reading by a user space program.

=item --account

This adds an ACCOUNT rule for this service with the exact same options.

=item --mark

Marks the packet with the specified integer.

=item --name

Sets the accounting name for this rule. This is easier to read than
the unique name generated internally.

=item --portfw [local_ip]

The service will be interpreted as being redirected from a local
address to another host on a network attached to one of the firewall
interface. The optional argument is one of the IP of a defined
interface. If the local_ip from which the service will redirected is
unspecified, the one attached to the incoming interface will be used.

When using portfw, the dst parameter can only contains hosts and all
src must be compatible with the local_ip.

=back

=head1 ACCOUNTING

Accounting data is dump to the file F</var/log/fwctl_acct>. You
should run periodically the B<fwctl> program to dump the accumulated
accounted data.

The format of the file is:

    timestamp chain packets bytes name

=over

=item timestamp

=item chain

The unique internal name identifying this chain. (If you want to
know, it is acct plus four digit number starting from 0 and incremented
for each ACCOUNT chain added.) 

If you need to translate this anything meaningful, please use the
I<name> option.

=item packets

The number of packets related to that service.

=item bytes

The number of bytes relating to that service.

=item name

The value of the I<name> option.

=back

=head1 BUGS AND LIMITATIONS

Please report bugs, suggestions, patches and thanks to
<francis.lacoste@iNsu.COM>.

This package is probably useless if you have something a
topology that cannot be described adequatly in a simple static
routing scheme.

Documentation on writing services is lacking. But see the
standard services for details.

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, you can get one at
http://www.gnu.org/copyleft/gpl.html

=head1 SEE ALSO

fwctl(8) Fwctl::RuleSet(3) IPChains(3) Net::IPv4Addr(3)
Fwctl::Services::all(3) Fwctl::Services::dhcp(3) Fwctl::Services::ftp(3)
Fwctl::Services::http(3) Fwctl::Services::hylafax(3) 
Fwctl::Services::netbios(3)  Fwctl::Services::ntp(3)
Fwctl::Services::ping(3) Fwctl::Services::portmap(3)  Fwctl::Services::rsh(3)
Fwctl::Services::snmp(3) Fwctl::Services::tcp_service(3)
Fwctl::Services::syslog(3)
Fwctl::Services::tftp(3) Fwctl::Services::timed(3)
Fwctl::Services::traceroute(3) Fwctl::Services::traffic_control(3)
Fwctl::Services::udp_service(3)

=cut
