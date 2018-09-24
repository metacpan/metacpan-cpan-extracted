#!/usr/bin/perl
use strict;
use warnings;
use Mail::SPF::Iterator;
use Net::DNS;
#use Mail::SPF::Iterator DebugFunc => \&DEBUG;
use Getopt::Long qw(:config posix_default bundling);

#### Options
my ($resolver,$spfdfl,$pass_all);
GetOptions(
    'd|debug' => sub { Mail::SPF::Iterator->import( Debug => 1 ) },
    'h|help' => sub { usage() },
    'spfdfl=s' => \$spfdfl,
    'passall=s' => \$pass_all,
    'dns=s'  => sub {
	my ($ip,$port) = $_[1] =~m{^([^:]+)(?::(\d+))?\z} or die $_[1];
	$resolver = Net::DNS::Resolver->new( nameservers => [$ip]);
	$resolver->port($port) if $port;
    }
) or usage();

my ($ip,$sender,$helo,$local) = @ARGV;
($ip && $sender) or usage();

#### SPF lookup
my $spf = Mail::SPF::Iterator->new($ip, $sender, $helo || '', $local, {
    default_spf => $spfdfl,
    pass_all => $pass_all,
});
my $result = $spf->lookup_blocking(undef,$resolver);
print "Received-SPF: ".$spf->mailheader."\n";
print "Explanation: ".($spf->result)[3]."\n" if $result eq SPF_Fail;


#### USAGE
sub usage { die <<USAGE; }

Usage: $0 [options] Ip Sender [Helo] [Localname]
lookup SPF result, returns SPF-Received header

Example: $0 10.0.3.4 user\@example.com smtp.example.com smtp.example.local

Options:
 -d|--debug          enable debugging
 -h|--help           this help
 --spfdfl txt        use given SPF rule if none given for domain
 --pass_all policy   use given policy (like SoftFail) if rule matches all
 --dns IP[:port]     use given DNS server

USAGE

sub DEBUG {
    print STDERR "DEBUG: @_\n";
}

