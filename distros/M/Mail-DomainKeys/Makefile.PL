#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;
use IO::Socket;

# Check if we have internet connection
# (I lifted this code from Net::DNS... )
#

my $inet;

my $s = IO::Socket::INET->new(
	PeerAddr => "www.google.com:80",
	Timeout  => 10,
);

if ($s) {
	close($s);

	print <<EOT;

You appear to be directly connected to the Internet.  I have some tests
that try to query live nameservers.
	
EOT
	
	$inet = prompt("Do you want to enable these tests?", "y") =~ /^y/i ? 1 : 0;
}

if ($inet) {
	open(ENABLED, ">t/connected") || die "Can't touch ./t/online.enabled $!";
	close(ENABLED)                     || die "Can't touch ./t/online.enabled $!";
} else {
	unlink "t/connected";
}

WriteMakefile(
	NAME          => "Mail::DomainKeys",
	VERSION_FROM  => "lib/Mail/DomainKeys.pm",
	PREREQ_PM     => {
		"Crypt::OpenSSL::RSA"	=> 0,
		"Mail::Address"		=> 0,
		"MIME::Base64"		=> 0,
		"Net::DNS"		=> 0.34,
		"Test::More"		=> 0
	},
	clean         => { FILES => "t/connected" }
);
