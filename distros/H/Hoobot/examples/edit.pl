#!/usr/bin/perl
#
# Usage: ./edit.pl <h2g2id>
# either 123456 or A123456 is supported
#
# this script is incomplete

use strict;
use warnings;
use LWP::UserAgent;
use Hoobot;
use Hoobot::Login;

warn "This program doesn't work";

my $h2g2id = $ARGV[0];

unless (@ARGV == 1) {
  print STDERR "$0 <h2g2id>\n";
  die "All arguments are mandatory\n";
}

($h2g2id) = $h2g2id =~ /^\s* A? (\d+) \s*$/x
  or die "Wrong format for h2g2id";

# outline:
# access A123456
# find owner
# login as owner
# download body
# upload body

my $hoobot = Hoobot
  -> ua( LWP::UserAgent->new( cookie_jar => {} ) );

my ($editor) = $hoobot
  -> page("A$h2g2id")
  -> skin('plain')
  -> update
  -> document
  -> getDocumentElement
  -> findnodes('span[@class="?"');
 
printf "Article edited by U%d (%s)\n",
  $editor->findvalue('USERID'),
  $editor->findvalue('USERNAME');

exit;

print "Username: ";
chomp(my $username = <STDIN>);
print "Password: ";
chomp(my $password = <STDIN>);

Hoobot::Login
  -> hoobot($hoobot)
  -> username($username)
  -> password($password)
  -> update;

my $contents = $hoobot
  -> page("useredit$h2g2id")
  -> skin('plain')
  -> update
  -> document
  -> getDocumentElement
  -> findnodes('span[@class="?"');

print "\n$contents\n";
