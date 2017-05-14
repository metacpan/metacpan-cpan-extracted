#! /usr/bin/perl

use warnings;
use strict;

# A simple program to show home some things work
# (C) 2010 Dot TK Ltd

use Domain::Register::TK;
use Data::Dumper;

# Create a master object
my $api = Domain::Register::TK->new();

# Issue a ping command to check that the remote server is available
$api->ping;

# if something went wrong, tell the user about it, then exit
if (defined $api->errstr) {
    die 'Error: ' . $api->errstr . ' returned while trying to ping Dot TK server';
}

print "Ping was successful.\n";

# Tell the object about your identity with the Dot TK servers.
# Note:if you want this to actually run, you need to change these values.
$api->credentials('email@tk_reseller.com', 'reseller_passsword');

my @domains_to_check = qw{ DOT.TK TESTDOMAIN-0001.TK DONALD-DUCK.TK};

foreach my $domain (@domains_to_check) {
     # check if the domain is available, with prices for 3 years
    my $response = $api->availability_check($domain, 3);

    # if something wrong, report on that. 
    if (defined $api->errstr) {
	die "Error: checking $domain: " . $api->errstr;
    }

    # report on domain availability
    print "Domain $domain is $response->{status}\n";
    
    # if available, show details on domain
    if ($response->{status} eq 'AVAILABLE') {
	print "It is a $response->{domaintype} domain, and will cost $response->{partnerrate} $response->{currency} (RRP $response->{retailrate}) for the 3 years requested\n";
    }
}

$api->set_timeout(5); # set timeout to 5 seconds

# what follows is a deliberate attempt to cause an error, to demonstrate the error handling.
#
# this address space is reserved by RFC 3330, so it won't go anywhere
$api->proxy('https://169.254.1.1:443'); 
$api->ping;

if (defined $api->errstr) {
    die 'Error: ' . $api->errstr . ' returned while trying to ping Dot TK server';
}

exit;
