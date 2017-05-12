package IPTables::Rule;

use 5.000000;
use strict;
use warnings;

our $VERSION = '0.03';

###############################################################################
### PRECOMPILED REGEX
my $qr_fqdn	= qr/(([A-Z0-9]|[A-Z0-9][A-Z0-9\-]*[A-Z0-9])\.)*([A-Z]|[A-Z][A-Z0-9\-]*[A-Z0-9])/io;
my $qr_mac_addr	= qr/(([A-F0-9]{2}[:.-]?){6})/io;

my $qr_ip4_addr = qr/(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/o;
my $qr_ip6_addr;
{
	# This block courtesy of Regexp::IPv6 0.03 by Salvador Fandiño
	# http://search.cpan.org/~salva/Regexp-IPv6/
	# http://cpansearch.perl.org/src/SALVA/Regexp-IPv6-0.03/lib/Regexp/IPv6.pm
	my $IPv4 = "((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";
	my $G = "[0-9a-fA-F]{1,4}";
	my @tail = ( ":",
		"(:($G)?|$IPv4)",
		":($IPv4|$G(:$G)?|)",
		"(:$IPv4|:$G(:$IPv4|(:$G){0,2})|:)",
		"((:$G){0,2}(:$IPv4|(:$G){1,2})|:)",
		"((:$G){0,3}(:$IPv4|(:$G){1,2})|:)",
		"((:$G){0,4}(:$IPv4|(:$G){1,2})|:)" );
	my $IPv6_re = $G;
	$IPv6_re = "$G:($IPv6_re|$_)" for @tail;
	$IPv6_re = qq/:(:$G){0,5}((:$G){1,2}|:$IPv4)|$IPv6_re/;
	$IPv6_re =~ s/\(/(?:/g;
	$qr_ip6_addr = qr/$IPv6_re/;
}
# and the CIDR versions of the above
my $qr_ip4_cidr	= qr/$qr_ip4_addr\/[0-9]{1,2}/o;
my $qr_ip6_cidr	= qr/$qr_ip6_addr\/[0-9]{1,3}/io;

###############################################################################
### METHODS

sub new {
	my $self = {
		ip4binary	=> 'iptables',
		ip6binary	=> 'ip6tables',
		iptaction	=> '-A',
		ipver		=> '4',		# IPv4 by default
		table		=> undef,
		chain		=> undef,
		target		=> undef,
		in			=> undef,
		out			=> undef,
		src			=> undef,
		dst			=> undef,
		proto		=> undef,
		dpt			=> undef,
		spt			=> undef,
		mac			=> undef,
		state		=> undef,
		comment		=> undef,
		logprefix	=> undef,
		icmp_type	=> undef,
	};

	bless $self;
}

sub dump {
	my $self = shift;
	my %dump_hash;

	foreach my $key ( keys %$self ) {
		$dump_hash{$key} = $self->{$key} if ( defined($self->{$key}) );
	}

	return \%dump_hash;
}

sub errstr {
	my $self = shift;
	return $self->{errstr};
}

sub ip4binary {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( $arg =~ m|\A/.+\z| ) {
			__errstr($self, 'invalid path: '.$arg);
			return;
		}
		$self->{ip4binary} = $arg;
	}

	return $self->{ip4binary};
}

sub ip6binary {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( $arg =~ m|\A/.+\z| ) {
			__errstr($self, 'invalid path: '.$arg);
			return;
		}
		$self->{ip6binary} = $arg;
	}

	return $self->{ip6binary};
}

sub iptaction {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( $arg =~ m/\A-[ADIRLSFZNXPE]\z/ ) {
			__errstr($self, 'invalid action: '.$arg);
			return;
		}
		$self->{iptaction} = $arg;
	}

	return $self->{iptaction};
}

sub ipversion {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		# Valid arguments are 4 and 6
		unless ( $arg =~ m/\A[46]\z/ ) {
			__errstr($self, 'invalid ip version: '.$arg);
			return;
		}

		$self->{ipver} = $arg;
	}

	return $self->{ipver};
}

sub table {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		my $need_to_barf;
		$need_to_barf = 1 if ( $self->{ipver} eq '4' and $arg !~ m/\A(filter|nat|mangle|raw)\z/i );
		$need_to_barf = 1 if ( $self->{ipver} eq '6' and $arg !~ m/\A(filter|mangle|raw)\z/i );
		if ( $need_to_barf ) {
			__errstr($self, sprintf('invalid table "%s" for ip version: %s', $arg, $self->{ipver}));
			return;
		}

		$self->{table} = $arg;
	}

	return $self->{table};
}

sub chain {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		$self->{chain} = $arg;
	}

	return $self->{chain};
}

sub target {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		$self->{target} = $arg;
	}

	return $self->{target};
}

*protocol = \&proto;
sub proto {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( $arg =~ m/\A[a-z0-9]+\z/ ) {
			__errstr($self, 'invalid protocol: '.$arg);
			return;
		}
		if ( $self->{ipver} eq '6' and $arg eq 'icmp' ) {
			__errstr($self, 'icmp not valid protocol for IPv6. Perhaps you meant "icmpv6"?');
			return;
		}
		if ( $self->{ipver} eq '4' and $arg eq 'icmpv6' ) {
			__errstr($self, 'icmpv6 not valid protocol for IPv4. Perhaps you meant "icmp"?');
			return;
		}

		$self->{proto} = $arg;
	}

	return $self->{proto};
}

sub in {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		$self->{in} = $arg;
	}

	return $self->{in};
}

sub out {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		$self->{out} = $arg;
	}

	return $self->{out};
}

*source = \&src;
sub src {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless (
			__is_valid_inet_host($arg) or
			__is_valid_inet_cidr($arg) or
			__is_valid_inet_range($arg)
		) {
			__errstr($self, 'invalid source address: '.$arg);
			return;
		}

		$self->{src} = $arg;
	}

	return $self->{src};
}

*dest = \&dst;
*destination = \&dst;
sub dst {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless (
			__is_valid_inet_host($arg) or
			__is_valid_inet_cidr($arg) or
			__is_valid_inet_range($arg)
		) {
			__errstr($self, 'invalid destination address: '.$arg);
			return;
		}

		$self->{dst} = $arg;
	}

	return $self->{dst};
}

*port = \&dpt;
*dport = \&dpt;
sub dpt {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( __is_valid_inet_port($arg) ) {
			__errstr($self, 'invalid destination port: '.$arg);
			return;
		}

		$self->{dpt} = $arg;
	}

	return $self->{dpt};
}

*sport = \&spt;
sub spt {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( __is_valid_inet_port($arg) ) {
			__errstr($self, 'invalid source port: '.$arg);
			return;
		}

		$self->{spt} = $arg;
	}

	return $self->{spt};
}

sub mac {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( __is_valid_mac_address($arg) ) {
			__errstr($self, 'invalid mac address: '.$arg);
			return;
		}

		$self->{mac} = $arg;
	}

	return $self->{mac};
}

sub state {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		my @states = split(",",$arg);
		for (@states) {
			unless ( $_ =~ m/\A(NEW|ESTABLISHED|RELATED|INVALID|UNTRACKED)\z/i ) {
				__errstr($self, 'invalid connection tracking state: '.$_);
				return;
			}
		}
		$self->{state} = $arg;
	}

	return $self->{state};
}

*rate_limit = \&limit;
sub limit {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		# --limit rate[/second|/minute|/hour|/day]
		unless ( $arg =~ m/\A\d+\/(s(ec(ond)?)?|m(in(ute)?)?|h(our)?|d(ay)?)\z/i ) {
			__errstr($self, 'invalid rate limit: '.$arg);
			return;
		}
		$self->{limit} = $arg;
	}

	return $self->{limit};
}

sub icmp_type {
	my $self = shift;
	my ($arg) = @_;

	if ( $arg ) {
		unless ( $arg =~ m|\A[a-z0-9\-]+(/[a-z0-9\-]+)?\z|i ) {
			__errstr($self, 'invalid icmp type: '.$arg);
			return;
		}

		$self->{icmp_type} = $arg;
	}

	return $self->{icmp_type};
}

sub logprefix {
	my $self = shift;
	my ($arg) = @_;

	my $max_length = 29;

	if ( $arg ) {
		if ( length($arg) > $max_length ) {
			__errstr($self, 'log prefix too long (>'.$max_length.'): '.$arg);
			return;
		}
		if ( $arg =~ m/[\"\']/ ) {
			__errstr($self, 'quotes not permitted: '.$arg);
			return;
		}

		$self->{logprefix} = $arg;
	}

	return $self->{logprefix};
}

sub comment {
	my $self = shift;
	my ($arg) = @_;

	my $max_length = 256;

	if ( $arg ) {
		if ( length($arg) > $max_length ) {
			__errstr($self, 'comment too long (>'.$max_length.'): '.$arg);
			return;
		}
		if ( $arg =~ m/[\"\']/ ) {
			__errstr($self, 'quotes not permitted: '.$arg);
			return;
		}

		$self->{comment} = $arg;
	}

	return $self->{comment};
}

*compile = \&generate;
sub generate {
	my $self = shift;

	# what is required?
	unless ( $self->{chain} ) {
		__errstr($self, 'Chain must be specified');
		return;
	}
	# ports are only valid with protocol tcp and udp
	if ( defined($self->{spt}) and $self->{proto} !~ m/\A(tcp|udp)\z/i ) {
		__errstr($self, 'Protocol must be TCP or UDP when specifying source port');
		return;
	}
	if ( defined($self->{dpt}) and $self->{proto} !~ m/\A(tcp|udp)\z/i ) {
		__errstr($self, 'Protocol must be TCP or UDP when specifying destinatipn port');
		return;
	}
	# cant use 'logprefix' unless the target is 'log'
	if ( defined($self->{logprefix}) and $self->{target} !~ m/\Alog\z/i ) {
		__errstr($self, 'Target must be LOG when specifying log prefix');
		return;
	}
	# ipversion matches the source/dest addresses?
	if ( $self->{ipver} eq '4' ) {
		if ( $self->{src} ) {
			# make sure it's ipv4
			unless ( __is_valid_inet4($self->{src}) ) {
				__errstr($self, 'IP Version is 4 but source is not valid IPv4');
				return;
			}
		}
		if ( $self->{dst} ) {
			# make sure it's ipv4
			unless ( __is_valid_inet4($self->{dst}) ) {
				__errstr($self, 'IP Version is 4 but destination is not valid IPv4');
				return;
			}
		}
	} elsif ( $self->{ipver} eq '6' ) {
		if ( $self->{src} ) {
			# make sure it's ipv6
			unless ( __is_valid_inet6($self->{src}) ) {
				__errstr($self, 'IP Version is 6 but source is not valid IPv6');
				return;
			}
		}
		if ( $self->{dst} ) {
			# make sure it's ipv6
			unless ( __is_valid_inet6($self->{dst}) ) {
				__errstr($self, 'IP Version is 6 but destination is not valid IPv6');
				return;
			}
		}
	} else {
		# should never happen; the ipversion sub validates user input
		__errstr($self, 'Code bug 0x01; Please report to developer.');
		return;
	}
	# if icmp_type is set, protocol must be icmp or icmpv6
	if ( defined($self->{icmp_type}) and $self->{proto} !~ m/\Aicmp(v6)?\z/i ) {
		__errstr($self, 'icmp_type is set, but protocol is: '.$self->{proto});
		return;
	}

	my $rule_prefix;
	my $rule_criteria;

	$rule_prefix = $self->{ip4binary} if $self->{ipver} eq '4';
	$rule_prefix = $self->{ip6binary} if $self->{ipver} eq '6';
	$rule_prefix .= ' -t '.$self->{table} if ( defined($self->{'table'}) );
	$rule_prefix .= ' '.$self->{iptaction};
	$rule_prefix .= ' '.$self->{chain};
	
	# Source and Destination Addresses
	if ( defined($self->{src}) ) {
		if ( __is_valid_inet_host($self->{src}) or __is_valid_inet_cidr($self->{src}) ) {
			$rule_criteria .= sprintf(' -s %s', $self->{src});
		}
		if ( __is_valid_inet_range($self->{src}) ) {
			$rule_criteria .= sprintf(' -m iprange --src-range %s',	$self->{'src'});
		}
	}
	if ( defined($self->{dst}) ) {
		if ( __is_valid_inet_host($self->{dst}) or __is_valid_inet_cidr($self->{dst}) ) {
			$rule_criteria .= sprintf(' -d %s', $self->{dst});
		}
		if ( __is_valid_inet_range($self->{dst}) ) {
			$rule_criteria .= sprintf(' -m iprange --dst-range %s',	$self->{'dst'});
		}
	}

  # this needs to be written out before we output the src/dst port (if they are present)
  # otherwise iptables/ip6tables complains at the command.
	$rule_criteria .= sprintf(' -p %s', $self->{proto}) if ( defined($self->{proto}) );
	
	# Source and Destination Ports
	if ( defined($self->{spt}) ) {
		if ( $self->{spt} =~ m/\A\w+\z/ ) {
			# just a single port
			$rule_criteria .= sprintf(' --sport %s', $self->{'spt'});
		}
		if ( $self->{spt} =~ m/\A\w+(:\w+)+\z/ ) {
			# port range
			$rule_criteria .= sprintf(' --sport %s', $self->{'spt'});
		}
		if ( $self->{spt} =~ m/\A\w+(:\w+)+\z/ ) {
			# multiport
			$rule_criteria .= sprintf(' -m multiport --sports %s', $self->{'spt'});
		}
	}
	if ( defined($self->{dpt}) ) {
		if ( $self->{dpt} =~ m/\A\w+\z/ ) {
			# just a single port
			$rule_criteria .= sprintf(' --dport %s', $self->{'dpt'});
		}
		if ( $self->{dpt} =~ m/\A\w+(:\w+)+\z/ ) {
			# port range
			$rule_criteria .= sprintf(' --dport %s', $self->{'dpt'});
		}
		if ( $self->{dpt} =~ m/\A\w+(:\w+)+\z/ ) {
			# multiport
			$rule_criteria .= sprintf(' -m multiport --dports %s', $self->{'dpt'});
		}
	}

	$rule_criteria .= sprintf(' -i %s',						$self->{in})		if ( defined($self->{in}) );
	$rule_criteria .= sprintf(' -o %s',						$self->{out})		if ( defined($self->{out}) );
	$rule_criteria .= sprintf(' -m mac --mac-source %s',	$self->{mac})		if ( defined($self->{mac}) );
	$rule_criteria .= sprintf(' -m conntrack --ctstate %s', $self->{state})		if ( defined($self->{state}) );
	$rule_criteria .= sprintf(' --icmp-type %s',			$self->{icmp_type})	if ( defined($self->{icmp_type}) );
	$rule_criteria .= sprintf(' -m comment --comment "%s"', $self->{comment})	if ( defined($self->{comment}) );
	$rule_criteria .= sprintf(' -m limit --limit %s',		$self->{limit})		if ( defined($self->{limit}) );
	$rule_criteria .= sprintf(' -j %s',						$self->{'target'})	if ( defined($self->{'target'}) );
	$rule_criteria .= sprintf(' --log-prefix "[%s] "',		$self->{logprefix})	if ( defined($self->{logprefix}) );

#	$ipt_rule .= sprintf(' -m statistic %s',			$criteria{'statistic'})	if (defined($criteria{'statistic'}));
#	$ipt_rule .= sprintf(' -m time %s',					$criteria{'time'})		if (defined($criteria{'time'}));

	my $full_cmd = $rule_prefix.$rule_criteria;
	return $full_cmd;
}

###############################################################################
### INTERNAL HELPERS
# These are subs that are NOT expected to be used outside this module itself.
# They are for internal code reuse only.
# All sub named should be prefixed with double underslash (__) to indicate they
# are internal use only.

sub __is_valid_mac_address {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	if ( $arg =~ m/\A$qr_mac_addr\z/ ) {
		return 1;
	}

	# fail by default
	return;
}

sub __is_valid_inet4 {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 address?
	return 1 if ( __is_inet4_host($arg) );

	# ipv4 cidr?
	return 1 if ( __is_inet4_cidr($arg) );

	# ipv4 range?
	return 1 if ( __is_inet4_range($arg) );

	# fqdn?
	return 1 if ( $arg =~ m/\A$qr_fqdn\z/ );

	# fail by default
	return;
}

sub __is_valid_inet6 {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv6 address?
	return 1 if ( __is_inet6_host($arg) );

	# ipv4 cidr?
	return 1 if ( __is_inet6_cidr($arg) );

	# ipv4 range?
	return 1 if ( __is_inet6_range($arg) );

	# fqdn?
	return 1 if ( $arg =~ m/\A$qr_fqdn\z/ );

	# fail by default
	return;
}

sub __is_valid_inet_host {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 address?
	return 1 if ( __is_inet4_host($arg) );

	# ipv6 address?
	return 1 if ( __is_inet6_host($arg) );

	# fqdn?
	return 1 if ( $arg =~ m/\A$qr_fqdn\z/ );

	# fail by default
	return;
}

sub __is_inet4_host {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 address?
	return 1 if ( $arg =~ m/\A$qr_ip4_addr\z/ );

	# fail by default
	return;
}

sub __is_inet6_host {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv6 address?
	return 1 if ( $arg =~ m/\A$qr_ip6_addr\z/ );

	# fail by default
	return;
}

sub __is_valid_inet_cidr {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 cidr?
	return 1 if ( __is_inet4_cidr($arg) );

	# ipv6 cidr?
	return 1 if ( __is_inet6_cidr($arg) );

	# fail by default
	return;
}

sub __is_inet4_cidr {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 cidr?
	if ( $arg =~ m/\A$qr_ip4_cidr\z/ ) {
		# validate the cidr
		my ($host, $cidr) = split(/\//, $arg);
		return if ( $cidr < 0 );
		return if ( $cidr > 32 );

		return 1;
	}

	# fail by default
	return;
}

sub __is_inet6_cidr {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv6 cidr?
	if ( $arg =~ m/\A$qr_ip6_cidr\z/ ) {
		# validate the cidr
		my ($host, $cidr) = split(/\//, $arg);
		return if ( $cidr < 0 );
		return if ( $cidr > 128 );

		return 1;
	}

	# fail by default
	return;
}

sub __is_valid_inet_range {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 address range?
	return 1 if ( __is_inet4_range($arg) );

	# ipv6 address range?
	return 1 if ( __is_inet6_range($arg) );

	# fail by default
	return;
}

sub __is_inet4_range {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv4 address range?
	return 1 if (
		$arg =~ m/\A$qr_ip4_addr\-$qr_ip4_addr\z/
	);

	# fail by default
	return;
}

sub __is_inet6_range {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# ipv6 address range?
	return 1 if (
		$arg =~ m/\A$qr_ip6_addr\-$qr_ip6_addr\z/
	);

	# fail by default
	return;
}

sub __is_valid_inet_port {
	my ( $arg ) = @_;
	chomp($arg);

	return unless ( $arg );

	# just a numeric port?
	if ( __is_a_number($arg) ) {
		return if ( $arg < 0 );
		return if ( $arg > 65535 );

		return 1;
	}

	# just a named port?
	if ( $arg =~ m/\A[a-z]+\z/i ) {
		return 1;
	}

	# numeric port range?
	if ( $arg =~ /\A\d+:\d+\z/ ) {
		my ( $lower, $upper) = split(/:/, $arg, 2);

		# recursive call to this sub to validate individal ports in multiport
		return unless ( __is_valid_inet_port($lower) );
		return unless ( __is_valid_inet_port($upper) );

		# lower is higher than upper?
		return if ( $upper < $lower );

		return 1;
	}

	# named port range?
	if ( $arg =~ /\A[a-z]+:[a-z]+\z/i ) {
		my ( $lower, $upper) = split(/:/, $arg, 2);

		# recursive call to this sub to validate individal ports in multiport
		return unless ( __is_valid_inet_port($lower) );
		return unless ( __is_valid_inet_port($upper) );

		return 1;
	}

	# numeric multiport?
	if ( $arg =~ /\A\d+(,\d+)+\z/ ) {
		my @ports = split(/,/, $arg);

		foreach my $port ( @ports ) {
			# recursive call to this sub to validate individal ports in multiport
			return unless ( __is_valid_inet_port($port) );
		}

		return 1;
	}

	# named multiport?
	if ( $arg =~ /\A[a-z]+(,[a-z]+)+\z/i ) {
		my @ports = split(/,/, $arg);

		foreach my $port ( @ports ) {
			# recursive call to this sub to validate individal ports in multiport
			return unless ( __is_valid_inet_port($port) );
		}

		return 1;
	}

	# fail by default
	return;
}

sub __is_a_number {
	my ( $arg) = @_;
	return 1 if ( $arg =~ /\A-?\d+\z/);
	return;
}

sub __errstr {
	my $self = shift;
	my $errstr = shift;
	$self->{errstr} = $errstr;
	return 1;
}

1;
__END__

=head1 NAME

IPTables::Rule - Perl extension for holding iptables rule information in objects.

=head1 SYNOPSIS

  use IPTables::Rule;

  my $ipt_rule = new IPTables::Rule ;
  $ipt_rule->chain('INPUT');
  $ipt_rule->source('192.168.0.0/24');
  $ipt_rule->protocol('tcp');
  $ipt_rule->dport('22');
  $ipt_rule->target('ACCEPT');
  $ipt_rule->comment('accept ssh from lan');
  print $ipt_rule->generate;

=head1 DESCRIPTION

This package provides a way to build/store iptables rules in objects. It deals
with ONLY individual rules; no attention it given to the overall structure of
the ruleset (see L<IPTables::IPv4> or L<IPTables::IPv6> for that).

Once all your criteria has been set, you can call the C<generate> method to
convert the set criteria into an iptables command line string.

=head2 METHODS

Methods return a value for success, or undef for failure. Errors are availabe
using the C<errstr> method:

  $ipt_rule->chain('INPUT') or print $ipt_rule->errstr;

=head3 new

Create a new object to hold a rule.

=head3 ip4binary

When you call L</generate>, the returned output will prefix with the generic
string 'iptables'. Use C<ip4binary> method to change this to something more
appropriate. For example, to use an absolute path:

  $ipt_rule->ip4binary('/usr/bin/iptables');

=head3 ip6binary

When you call L</generate>, the returned output will prefix with the generic
string 'ip6tables'. Use C<ip4binary> method to change this to something more
appropriate. For example, to use an absolute path:

  $ipt_rule->ip6binary('/usr/bin/ip6tables');

=head3 iptaction

The default action for a new rule is append (-A). Use this method to change
this to any other valid iptables action. See L<iptables(8)/Options/Commands>
for valid actions.

Syntax is to supply the capitalized short flag:

  $ipt_rule->iptaction('-I');	# Change iptables action to 'Insert'
  $ipt_rule->iptaction('-Z');	# Change iptables action to 'Zero Counters'

=head3 dump

Returns a hash-ref of the current rule details.

  my $hashref = $ipt_rule->dump();

=head3 ipversion

Defaults to IPv4 (ie, iptables). Valid options are '4' for IPv4/iptables, or
'6' for IPv6/ip6tables.

  $ipt_rule->ipversion('6');

=head3 table

Set the table this rule applies to. By default, this is the 'filter' table.
Valid options depend on the ipversion:

IPv4: filter, nat, mangle or raw

IPv6: filter, mangle or raw

=head3 chain

Set which chain (within L</Table>) this rule applies to. Can be either an
inbuilt (eg, I<INPUT>, I<FORWARD>, I<OUTPUT> etc) for a user-created chain.

Remember that IPTables::Rule B<ONLY> deals with individual rules so it is
unable to validate what you provide here (ie, that the chain already exists)

=head3 target

The chain or action this rule should 'Jump' (-j) to if it is matched.

  $ipt_rule->target('ACCEPT');

=head3 proto

Protocol to match against.

  $ipt_rule->proto('tcp');

=head3 in

The input interface to match. Opposite of L</out>.

  $ipt_rule->in('eth0');

=head3 out

The output interface to match. Opposite of L</in>.

  $ipt_rule->out('eth1');

=head3 source

Source address this rule is to match. Opposite of "destination". See
L</VALID INET ADDRESSES> for valid values.


  $ipt_rule->source('www.example.com');
  $ipt_rule->source('192.168.1.0/24');
  $ipt_rule->source('fe80::4dc1:e674:f5e4:a74f');

=head3 destination

Destination address this rule is to match. Opposite of "source". See
L</VALID INET ADDRESSES> for valid values.

  $ipt_rule->destination('www.example.com');
  $ipt_rule->destination('192.168.1.0/24');
  $ipt_rule->destination('fe80::4dc1:e674:f5e4:a74f');

=head3 dpt

Destination Port to match. Opposite of L</spt>. See L</VALID INET PORTS> for
valid values.

Protocol must be set to either 'tcp' or 'udp' for this to be valid at
L</Generate> time.

  $ipt_rule->dpt('http');
  $ipt_rule->dpt('http,https');
  $ipt_rule->dpt('20:21');

=head3 spt

Source Port to match. Opposite of L</dpt>. See L</VALID INET PORTS> for valid
values.

Protocol must be set to either 'tcp' or 'udp' for this to be valid at
L</Generate> time.

  $ipt_rule->spt('http');
  $ipt_rule->spt('http,https');
  $ipt_rule->spt('20:21');

=head3 mac

Source MAC Address to match against.

  $ipt_rule->mac('6c:f0:49:e8:64:2a');

=head3 state

Match the incoming packet against the state of the connection as tracked by the
kernel connection tracking. Valid options are:

=over 8

=item * NEW

=item * ESTABLISHED

=item * RELATED

=item * INVALID

=item * UNTRACKED

=back

  $ipt_rule->state('new');

=head3 limit

Set a rate-limit for how often this rule will match. Syntax is S<number/period>
where C<number> is an integer for how often, and C<period> is the time period
to count against. Valid options for C<period> are C<second>, C<minute>,
C<hour> and C<day>.

  $ipt_rule->limit('3/second');
  $ipt_rule->limit('30/minute');	# average 1 every 2 seconds
  $ipt_rule->limit('24/day');		# average 1 per hour

=head3 icmp_type

Specify the ICMP type (and optionally sub-type) to match against. Protocol must
be set to 'icmp' (or 'icmpv6' for IPv6) to use this method. For valid types,
run C<iptables -m icmp --help>

Type and sub-type can be passed either numerically or named. If specifying a
sub-type, it must be separated with a forward slash ('/').

  $ipt_rule->icmp_type('echo-request');
  $ipt_rule->icmp_type('redirect/host-redirect');
  $ipt_rule->icmp_type('3');
  $ipt_rule->icmp_type('3/1');

=head3 logprefix

When you set L</target> to the inbuilt L<LOG|iptables(8)/"TARGET EXTENSIONS">
target, use this method to define what the log entries will be prefixed with.

  $ipt_rule->logprefix('[SSH PACKET] ');

=head3 comment

Add a comment to the rule to accompany it when viewing rules in iptables output

  $ipt_rule->comment('This rule allows SSH traffic');

=head3 generate

Returns the "compiled" rule in iptables command line syntax after performing
some validation on the rule criteria.

  print $ipt_rule->generate();

=head2 VALID INET ADDRESSES

When passing addresses, valid input can be one of the following:

=over 8

=item * A Fully Qualified Domain Name (FQDN) (eg, C<www.example.com>)

=item * An IPv4 Address (eg, C<192.168.1.1>)

=item * An IPv4 Address and CIDR (eg, C<192.168.1.0/24>)

=item * An IPv4 Address Range (eg, C<192.168.1.1-192.168.1.9>)

=item * An IPv6 Address (eg, C<fe80::4dc1:e674:f5e4:a74f>)

=item * An IPv6 Address and CIDR (eg, C<fe80::4dc1:e674:f5e4:a74f/10>)

=item * An IPv6 Address Range (eg, C<fe80::4dc1:e674:f5e4:0000-fe80::4dc1:e674:f5e4:ffff>)

=back

=head2 VALID INET PORTS

When specifying destination or source ports, valid input can be one of the following:

=over 8

=item * A numeric port (eg, 80)

=item * A named port (eg, http)

=item * A numeric port range, colon separated (eg, 20:21)

=item * A named port range, colon separated (eg, ftp-data:ftp)

=item * A list of comma separated numeric ports (eg, 25,110,143)

=item * A list of comma separated named ports (eg, smtp,pop3,imap)

=back

B<NOTE>: When using named ports, iptables/ip6tables will attempt to resolve
them using the file F</etc/services> so valid named ports must exist within
this file.

=head1 HISTORY

=over 8

=item 0.03

Add 'ip6binary' method, and fix bug in output with src/dst ports.

=item 0.02

Allow multiple states to be used (comma-delimed). Typo fixed in function call.

=item 0.01

Original version; created by h2xs 1.23

=back

=head1 SEE ALSO

L<iptables>

=head1 AUTHOR

Phillip Smith, E<lt>fukawi2@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Phillip Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
