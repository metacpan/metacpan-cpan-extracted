#!/usr/bin/perl
#
# $ENV{HOOBOT_HOST} allows one to select the server
# eg. www.bbc.co.uk or user:pass@another.server
#
# Usage: ./cookie.pl <username> <password>

use strict;
use warnings;
use LWP::UserAgent;
use Hoobot::Login;

my $username = $ARGV[0];
my $password = $ARGV[1];

unless (@ARGV == 2) {
  print STDERR "$0 <username> <password>\n";
  die "All arguments are mandatory\n";
}

# outline:
# setup cookiejar
# send login request
# dump cookiejar

# create an ua with a cookiejar
my $ua = LWP::UserAgent->new( cookie_jar => {} );

# somehow magically do a login request, we don't save the object
# traditional style
#Hoobot::Login->new(
#  ua => $ua,
#  username => $username,
#  password => $password,
#)->update;

# SOAP::Lite style
Hoobot::Login
  -> ua($ua)
  -> username($username)
  -> password($password)
  -> update;

# dump cookiejar
print $ua->cookie_jar->as_string, "\n";
