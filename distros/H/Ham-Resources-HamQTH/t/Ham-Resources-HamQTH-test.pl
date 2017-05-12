#!/usr/bin/perl
#
# Ham::Resources::HamQTH test module
# Test and Use procedures
#
# (c) Carlos Juan Diaz <ea3hmb at gmail.com> on Jan. 2012
#

use strict;
use warnings;
use lib('../lib/Ham/Resources/');
use HamQTH;

my $username = ""; # put your username HamQTH account here
my $password = ""; # put your password HamQTH here
my $callsign = $ARGV[0]; # callsign to search how command line argument
my $strip_html = 1; # 1 = text plain, 0 = HTML code
my $bio;
my $qth = Ham::Resources::HamQTH->new(
	callsign => $callsign,
	username => $username,
	password => $password,
	strip_html_bio => $strip_html,
);

# get info from a callsign
print "BIO for: $callsign\n";
print "-"x40;
print "\n";

if (length($callsign) <= 3) {
	$bio = $qth->get_dxcc;
} else {
	$bio = $qth->get_bio;
}
foreach (sort keys %{$bio}){
	print $_.": ".$bio->{$_}."\n";
}

# print a specific info
print "\n\nCallsign found: ".$bio->{callsign}."\n" if (!$bio->{error} && $bio->{callsign});
print "\n";

# get a list of available elements
print "List of arguments for this callsign\n";
print "-"x36;
print "\n";
$bio = $qth->get_list;
foreach my $tag (@{$bio}) {
	print $tag."\n";
}
