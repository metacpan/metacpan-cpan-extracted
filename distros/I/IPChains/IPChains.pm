package IPChains;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
package IPChainsc;
bootstrap IPChains;
var_IPChains_init();
@EXPORT = qw();
$VERSION = 0.6;

# ---------- BASE METHODS -------------

package IPChains;

sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package IPChains;

*ipfw_init = *IPChainsc::ipfw_init;
*ipfw_append = *IPChainsc::ipfw_append;
*ipfw_delete = *IPChainsc::ipfw_delete;
*ipfw_check = *IPChainsc::ipfw_check;
*ipfw_replace = *IPChainsc::ipfw_replace;
*ipfw_insert = *IPChainsc::ipfw_insert;
*ipfw_list = *IPChainsc::ipfw_list;
*ipfw_flush = *IPChainsc::ipfw_flush;
*ipfw_zero = *IPChainsc::ipfw_zero;
*ipfw_masq = *IPChainsc::ipfw_masq;
*ipfw_new_chain = *IPChainsc::ipfw_new_chain;
*ipfw_del_chain = *IPChainsc::ipfw_del_chain;
*ipfw_set_policy = *IPChainsc::ipfw_set_policy;

# -- End SWIG Generated Code -------------

package IPChains;

sub new {
	my $self = shift;
	my %args = @_;

	# need to verify TOS and add -S and ! support eventually.

	bless {
		"Source"	=>	$args{Source},		# accepts !
		"Dest"		=>	$args{Dest},		# accepts !
		"SourceMask"	=>	$args{SourceMask},
		"DestMask"	=>	$args{DestMask},
		"SourcePort"	=>	$args{SourcePort},	# accepts !
		"DestPort"	=>	$args{DestPort},	# accepts !
		"Prot"		=>	$args{Prot},		# required for port(s)
		"ICMP"		=>	$args{ICMP},		# no code with -d & no ports.
		"Rule"		=>	$args{Rule},		# -j in ipchains
		"Interface"	=>	$args{Interface},	# accepts !
		"Fragment"	=>	$args{Fragment},	# bool, accepts !
		"Bidir"		=>	$args{Bidir},		# bool
		"Verbose"	=>	$args{Verbose},		# bool
		"Numeric"	=>	$args{Numeric},		# bool - for L
		"Log"		=>	$args{Log},		# bool
		"Output"	=>	$args{Output}, 		# takes "maxsize" arg
		"Mark"		=>	$args{Mark},		# takes "mark value"
		"Exact"		=>	$args{Exact},		# bool - for L
		"SYN"		=>	$args{SYN},		# bool, accepts !
		"TOS"		=>	$args{TOS}
	        "RedirectPort"  =>      $args{RedirectPort}     # redirect port
		}, $self;
}

sub attribute {
	my ( $self, $attrib, $value ) = @_;
	if ( @_ == 3 ) {
		$self->{$attrib} = $value;
	} else {
		$value = $self->{$attrib};
	}
	return $value;
}

sub clopts {
	my ( $self ) = shift;
	%$self = ();
}

sub set_opts {
	my $self = shift;
	my @opts = ();

	# Program name needs to be @opts[0] to work.
	push(@opts, "IPChains");

	# Protocol
	if (defined($self->{Prot})) {
		push(@opts, "-p", "$self->{Prot}");
	}
	# Source address, mask, and port
	if (defined($self->{Source}) && ! defined($self->{SourceMask})) {
		push(@opts, "-s", "$self->{Source}");
	} elsif (defined($self->{Source}) && defined ($self->{SourceMask})) {
		push(@opts, "-s", "$self->{Source}/$self->{SourceMask}");
	}
	if (defined($self->{SourcePort}) && defined($self->{ICMP})) {
		die "Cannot Specify Port and ICMP type\n";
	}
	if (defined($self->{SourcePort}) && ! defined($self->{Source})) {
	  push(@opts, "-s", "0/0", "$self->{SourcePort}");
	}
	if (defined($self->{SourcePort}) && defined($self->{Source})) {
		push(@opts, "$self->{SourcePort}");
	}
	# Dest address, mask, and port
	if (defined($self->{Dest}) && ! defined($self->{DestMask})) {
		push(@opts, "-d", "$self->{Dest}");
	} elsif (defined($self->{Dest}) && defined ($self->{DestMask})) {
		push(@opts, "-d", "$self->{Dest}/$self->{DestMask}");
	}
	if (defined($self->{DestPort}) && defined($self->{ICMP})) {
		die "Cannot Specify Port and ICMP type\n";
	}
	if (defined($self->{DestPort}) && ! defined($self->{Dest})) {
	  push(@opts, "-d", "0/0", "$self->{DestPort}");
	}
	if (defined($self->{DestPort}) && defined($self->{Dest})) {
		push(@opts, "$self->{DestPort}");
	}
	if ( defined($self->{ICMP} )) {
		push @opts, "--icmp-type", $self->{ICMP};
	}
	    
	# "Jump" rule
	if (defined($self->{Rule})) {
		if (($self->{Rule} eq "REDIRECT" ) and (defined($self->{RedirectPort}))) {
			push(@opts, "-j", "$self->{Rule}", "$self->{RedirectPort}");
		} else {	 
			push(@opts, "-j", "$self->{Rule}");
		}	
	}
	if (defined($self->{Interface})) {
		push(@opts, "-i", "$self->{Interface}");
	}
	if ($self->{Fragment}) { push(@opts, "-f"); }
	if ($self->{Bidir}) { push(@opts, "-b"); }
	if ($self->{Verbose}) {	push(@opts, "-v"); }
	if ($self->{Numeric}) {	push(@opts, "-n"); }
	if ($self->{Log}) { push(@opts, "-l"); }
	if (defined($self->{Output})) {
		if ($self->{Output} == 1) {
			push(@opts, "-o");	
		} else {
			push(@opts, "-o", "$self->{Output}");
		}
	}
	if (defined($self->{Mark})) { 
		push(@opts, "-m", "$self->{Mark}"); 
	}
	if ($self->{Exact}) { push(@opts, "-x"); }
	if (defined($self->{SYN})) {
		if ("$self->{SYN}" =~ /\!/) {
			push(@opts, "!", "-y");
		} else {
			push(@opts, "-y");

		}
	}
	# UNTESTED. MAY SPONTAINIOUSLY COMBUST.
	if (defined($self->{TOS})) {
		push(@opts, "-t", "$self->{TOS}->[0]", "$self->{TOS}->[1]");
	}


	return \@opts;
}


sub append {
	my ($self, $chain) = @_;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_append($argc, $opts, $chain);
}	
	
sub insert {
	my ($self, $chain, $rulenum) = @_;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_insert($argc, $opts, $chain, $rulenum);
}

sub replace {
	my ($self, $chain, $rulenum) = @_;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_replace($argc, $opts, $chain, $rulenum);
}

sub delete {
	my ($self, $chain, $rulenum) = @_;
	$opts = set_opts($self);
        $argc = @$opts;
	ipfw_delete($argc, $opts, $chain, $rulenum);
}

sub check {
	my ($self, $chain) = @_;
        $opts = set_opts($self);
        $argc = @$opts;
        ipfw_check($argc, $opts, $chain);
}

sub flush {
	my ($self, $chain) = @_;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_flush($argc, $opts, $chain);
}

sub list {
	my ($self, $chain) = @_;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_list($argc, $opts, $chain);
}

# list_chains() contributed by Sven Koch <haegar@comunit.net>
sub list_chains {
	#my ($self) = @_;
	if (open(LIST, "</proc/net/ip_fwnames"))
	{
		my @result = grep { chomp; s/^([\w-]+).*/$1/; !/^(input|output|forward)$/ } <LIST>;
		close(LIST);
		return @result;
	} else {
		return undef;
	}
}

sub zero {
	my ($self, $chain) = @_;
	@opts = qw(IPChains $chain);
	$argc = @opts;
	ipfw_zero($argc, \@opts);
}

sub new_chain { 
	my ($self, $chain) = @_;
	@opts = qw(IPChains);
	$argc = @opts;
	ipfw_new_chain($argc, \@opts, $chain);
}

sub del_chain {
	my ($self, $chain) = @_;
	@opts = qw(IPChains);
	$argc = @opts;
	ipfw_del_chain($argc, \@opts, $chain);
}

sub set_policy {
	my ($self, $chain) = @_;
	my @opts;
	if (!defined($self->{Rule})) {	
		print "set_policy requires policy.\n";
	} else {
		push(@opts, "IPChains","$self->{Rule}");
	}
	$argc = @opts;
	ipfw_set_policy($argc, \@opts, $chain);

}

sub masq {
	my ($self) = shift;
	$opts = set_opts($self);
	$argc = @$opts;
	ipfw_masq($argc, $opts);
}


1;

__END__

=head1 NAME

IPChains - Create and Manipulate ipchains via Perl

=head1 SYNOPSIS

use IPChains;

$fw = IPChains->new(-option => value, ... );
$fw->append('chain');

=head1 DESCRIPTION

This module acts as an interface to the ipchains(8) userspace utility by
Paul "Rusty" Russell (http://www.rustcorp.com/linux/ipchains/). It attempts 
to include all the functionality of the original code with a simplified 
user interface via Perl. In addition, plans for log parsing facilities, an
integrated interface to ipmasqadm, and possibly traffic shaping are slated
for up and coming versions. 

The new() and attribute() methods support the following options:

=over 4

=item B<Source>

Specifies origination address of packet. Appending hostmask to this address using a / is 
OK, as well as specifying it separately (see SourceMask).

=item B<SourceMask>

Hostmask for origination address. Can either be in 24 or 255.255.255.0 style. 

=item B<SourcePort>

Specific port or port range (use xxx:xxx to denote range), requires specific 
protocol specification.

=item B<Dest>

Specifies destination address of packet. Appending hostmask to this address using a / is
OK, as well as specifying it separately (see DestMask)

=item B<DestMask>

Destination address, (see SourceMask).

=item B<DestPort>

Destination Port, (see SourcePort).

=item B<Prot>

Protocol. Can be tcp, udp, icmp, or all. Required for specifying specific port(s).

=item B<ICMP>

ICMP Name/Code (in place of port when ICMP is specified as protocol).

Here is a small table of some of the most common ICMP packets:

       Number  Name                     Required by

       0       echo-reply               ping
       3       destination-unreachable  Any TCP/UDP traffic.
       5       redirect                 routing if not running 
                                        routing daemon
       8       echo-request             ping
       11      time-exceeded            traceroute


=item B<Rule>

Target. Can be ACCEPT, DENY, REJECT, MASQ, REDIRECT, RETURN, or a user-defined chain.
Note: This is case sensitive.

=item B<Interface>

Specify a specify interface as part of the criteria (ie, eth0, ppp0, etc.).

=item B<Fragment>

Rule only refers to second and further fragments of fragmented packets (1 or 0).

=item B<Bidir>

Makes criteria effective in both directions (1 or 0).

=item B<Verbose>

Set verbose option for setting rules or list() (1 or 0).

=item B<Numeric>

Show output from list() in numeric format. No DNS lookups, etc.. (1 or 0).

=item B<Log>


Enable kernel logging (via syslog, kern.info) of matched packets (1 or 0).

=item B<Output>

Copy matching packets to the userspace device (advanced).

=item B<Mark>

Mark matching packets with specified number (advanced).

=item B<TOS>


Used for modifying the TOS field in the IP header. Takes 2 args, AND and XOR masks,
(ie, (TOS => ["0x01", "0x10"])). This feature is highly untested.

The first mask is ANDed with the packet's current TOS, and the
second mask is XORed with it. Use the following table for reference:

       TOS Name                Value           Typical Uses

       Minimum Delay           0x01 0x10       ftp, telnet
       Maximum Throughput      0x01 0x08       ftp-data
       Maximum Reliability     0x01 0x04       snmp
       Minimum Cost            0x01 0x02       nntp
 

=item B<Exact>

Display exact numbers in byte counters instead of
numbers rounded in K's, M's, or G's (1 or 0).

=item B<SYN>

Only match TCP packets with the SYN bit set and the 
ACK and FIN bits cleared (1 or 0).

=back

=head1 METHODS

The following methods are available to you:

=over 4

=item B<new()>

$fw = IPChains->new(option => value, ...) create new fw object with 
options

=item B<attribute()>

$fw->attribute(option, value) to set option to value, OR
$value = $obj->attribute(option) to get current value of option.

=item B<clopts()>

$fw->clopts() clears all option settings (do this before
calling methods like list(), flush(), delete(), etc. that
take only a few specific options).

=item B<append()>

$fw->append(chain) appends current rule to end of chain

=item B<insert()>

$fw->insert(chain, rulenum) inserts rule at position rulenum
in chain. If rulenum is omitted 1 is assumed.

=item B<replace()>

$fw->replace(chain, rulenum) replace rule at rulenum in chain with 
current rule.

=item B<delete()>

$fw->delete(chain, rulenum) deletes rule rulenum from chain.

=item B<check()>

$fw->check(chain) check given packet against chain for testing.

=item B<flush()>

$fw->flush(chain) deletes all rules from chain.

=item B<list()>

$fw->list(chain) lists all rules defined for chain.

=item B<list_chains()>

$fw->list_chains() returns array with the names of all user-defined chains
or undef if none exist.

=item B<zero()>

$fw->zero(chain) zero's all packet counters for chain. Cannot zero 
counters for chain policy.

=item B<masq()>

$fw->masq() lists current masqueraded connections.

=item B<new_chain()>

$fw->new_chain(chain) creates new user defined chain.

=item B<del_chain()>

$fw->del_chain(chain) delete user defined chain.

=item B<set_policy()>

$fw->set_policy(chain) set default policy for chain. Takes
Rule option only.

=back

=head1 EXAMPLES

To set the default policy for the "forward" chain to DENY:

 use IPChains;

 $fw = IPChains->new(Rule => "DENY");
 $fw->set_policy("forward");

To list current rules in "input" chain to stdout (without parsing through /proc/net/ip_fw*):

 use IPChains;

 $fw = IPChains->new(Verbose => 1);
 $fw->list("input");

To create a rule that would allow all traffic on an internal lan, and deny
all tcp traffic from external hosts on relevant ports, and log it,you could 
use something like:

 use IPChains;

 $internal = IPChains->new(Source    => "192.168.100.0/24",
                           Rule      => "ACCEPT",
                           Interface => "eth0");
 $external = IPChains->new(Interface => "ppp0",
                           Prot      => "tcp",
                           DestPort  => "0:1024",
                           Log       => 1);
 $internal->append("input");
 $external->append("input");

You could also create one object, set up the attributes, append() it, then
use clopts() to clear it's options, then use attribute() to individually
specify it's next set of options, then append() it again with the new rule.
See the examples/ subdirectory in the IPChains.pm source for more examples.

To forward all tcp traffic destined to port 80 to port 3000 instead (this is
useful for transparently forwarding traffic to a cache):

  use IPChains;

  $fw = IPChains->new(Source       => "0.0.0.0/0",
                      Destination  => "0.0.0.0/0",
                      DestPort     => "80",
                      Interface    => "eth0",
                      Rule         => "REDIRECT",
                      RedirectPort => "3000"
                      );
  $fw->append("input");

=head1 BUGS

Much of this is highly untested. Masquerading timeout setting and negative
attributes (!) aren't yet implemented.
Much of what's planned to be done hasn't been yet. This is
to be considered nothing more than an early beta to work out bugs in the
basic code, and get feedback on usefulness and improvements that could
be made.

=head1 AUTHOR

Jessica Hutchison (j@splatlabs.com). Please feel free to email me with
feedback, questions, or comments (or indeed patches/additions).

=head1 COPYRIGHT

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, with the exception
of the libipfwc.c, ipchains.c, and the files in include/ which 
have separate terms derived from those of the original ipchains 
sources. See COPYING for details of this license. Please see
README.ipchains for the README that was included with the
original source code for ipchains and contains copyrights and
credits for such. 
