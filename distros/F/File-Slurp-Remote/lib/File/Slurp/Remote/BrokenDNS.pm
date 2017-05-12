
package File::Slurp::Remote::BrokenDNS;

use strict;
use warnings;
use Tie::Function::Examples;
use Socket;
use Sys::Hostname::FQDN qw(fqdn);
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($myfqdn %fqdnify);
our $VERSION = 0.2;

our %cache;
our $myfqdn;
our %fqdnify;

if ($ENV{BROKEN_DNS_WORKAROUND}) {
	$myfqdn = `hostname`;
	chomp($myfqdn);
	tie %fqdnify, 'Tie::Function::Examples', 
		sub {
			my ($host) = @_;
			return $cache{$host} if $cache{$host};
			my $hn = `ssh -o StrictHostKeyChecking=no $host -n hostname`;
			chomp($hn);
			return $cache{$host} = $hn;
		};
} else {
	$myfqdn = fqdn();

	tie %fqdnify, 'Tie::Function::Examples', 
		sub {
			my ($host) = @_;
			return $cache{$host} if $cache{$host};
			my $iaddr = gethostbyname($host);
			return $host unless defined $iaddr;
			my $name = gethostbyaddr($iaddr, AF_INET);
			return $host unless defined $name;
			return $cache{$host} = $name;
		};
}

1;

__END__

1;

=head1 NAME

File::Slurp::Remote::BrokenDNS - discover canonical hostnames, sometimes with `hostname`

=head1 SYNOPSIS

 BEGIN { $ENV{BROKEN_DNS_WORKAROUND} = 1 };

 use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);

 print "alias for me\n" if $myfqdn eq $fqdnify{$host2};

=head1 DESCRIPTION

This module finds canonical fully qualified domain names.   
It ties the hash C<%fqdnify> to map from hostnames to 
canonical fully qualified domain names.   
If the environment variable C<BROKEN_DNS_WORKAROUND> is set, then it
uses C<ssh> and C<hostname> to do the work.  Otherwise it does a forward
DNS lookup to get an address then a reverse DNS lookup to get the hostname
from the address.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.
