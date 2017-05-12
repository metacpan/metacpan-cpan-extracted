#!/usr/bin/env perl
# Mike Covington
# created: 2014-03-05
#
# Description:
#
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Reproducible;
use Getopt::Long;

# default values
my $a = 0;
my $b = 0;
my $c = 0;

my $options = GetOptions (
    "a=s" => \$a,
    "b=s" => \$b,
    "c=s" => \$c,
);

print "a: $a\n";
print "b: $b\n";
print "c: $c\n";
print "extra: @ARGV\n";
