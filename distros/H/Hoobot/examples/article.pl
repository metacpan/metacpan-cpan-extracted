#!/usr/bin/perl
#
# Usage: ./article.pl <h2g2id>
# either 123456 or A123456 is supported

use strict;
use warnings;
use Hoobot;

my $h2g2id = $ARGV[0];

unless (@ARGV == 1) {
  print STDERR "$0 <h2g2id>\n";
  die "All arguments are mandatory\n";
}

($h2g2id) = $h2g2id =~ /^\s* A? (\d+) \s*$/x
  or die "Wrong format for the h2g2id";

# outline:
# access test123456
# find article text from diagnostic
# dump text

print Hoobot
  -> page("test$h2g2id")
  -> skin('plain')
  -> update
  -> document
  -> getDocumentElement
  -> findvalue('//td[@class="centrecolumn"]//textarea');
