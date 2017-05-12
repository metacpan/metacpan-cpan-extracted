#!/usr/local/bin/perl
use strict;
use warnings;
use Getopt::LL::Simple qw(
    --debug=d
    --verbose
    -in!=s
    -out!=s
);


if ($ARGV{'--debug'}) {
    print "Debugging level is: $ARGV{'--debug'}\n";
}

if ($ARGV{'--verbose'}) {
    print "Verbose output is on.\n";
}

print "Using input [$ARGV{'-in'}], output [$ARGV{'-out'}]\n";
