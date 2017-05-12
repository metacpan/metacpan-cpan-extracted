package Mail::Karmasphere::Parser::Record;

use strict;
use warnings;

# acceptable identity types include RBLDNSd format identities:
# * IP: a CIDR netblock: 192.168.0.0/24
# * IP: a CIDR range: 192.168.0.1-192.168.0.255
# * IP: a single IP address: 192.168.0.1
# * domain: a domain name: foo.example.com
# * domain: a subdomain mask: .example.com
# 
# also,
# * URI: some sort of http://whatnot/ or ftp://whatnot/, etc
# 
# this can all be in UTF-8.

my %keys = (
	s	=> "stream",
	# t	=> "type",
	i	=> "identity",
	v	=> "value",
);

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	for (keys %keys) {
		die "No $keys{$_} ($_) in Record" unless defined $self->{$_};
	}
	$self->{t} = guess_identity_type($self->{i})
					unless exists $self->{t};
	return bless $self, $class;
}

my $ip4p = q{(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})};
my $ip4s = "[.]";
my $ip4 = qq{(?:$ip4p(?:$ip4s$ip4p){0,3})};

sub is_ip4 {
	return $_[0] =~ m!^$ip4(?:-$ip4|/[0-9]{1,2})?$!o;
}

sub guess_identity_type {
	my $identity = shift;

	if (is_ip4($identity)) {
		return 'ip4';
	}
	elsif ($identity =~ /^[0-9a-f:]{2,64}$/i) {
		return 'ip6';
	}
	elsif ($identity =~ /^(https?|ftp):\/\//) {
		return 'url';
	}
	elsif ($identity =~ /@/) {
		return 'email';
	}
	elsif ($identity =~ /\.[a-z]{2,4}\.?$/) {
		return 'domain';
	}

	return 'unknown';
}

sub stream {
	return $_[0]->{s};
}

sub type {
	return $_[0]->{t};
}

sub identity {
	return $_[0]->{i};
}

sub value {
	return $_[0]->{v};
}

sub data {
	return $_[0]->{d};
}

sub _quote {
	my $value = shift;
	return $value unless $value =~ m/["', ]/;
	$value =~ s/"/""/g;
	return '"' . $value . '"';
}

# poor man's CSV.
# produces one of
#   1.2.3.4
#   1.2.3.4,-1000 (or some other number)
#   1.2.3.4,1000,"because why"
#
# note that  1.2.3.4,1000  is NOT optimized away to just  1.2.3.4
# we cannot assume that the feed is a whitelist
# 
sub as_string {
	my $self = shift;
	my $out = _quote($self->{i});

	$out .= "," . $self->{v}         if (defined $self->{v} or
		 							     defined $self->{d});
	$out .= "," . _quote($self->{d}) if (defined $self->{d});

	# print STDERR "v = $self->{v} -> $out\n";

	return $out;
}

1;
