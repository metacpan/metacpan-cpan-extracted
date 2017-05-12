#!/usr/bin/perl
use strict;
use warnings;

# find the modules, even if they are not installed. You don't need that
# if the module is installed

use lib '../lib/';
use lib 'lib';

use Math::Expression::Evaluator;
my $m = Math::Expression::Evaluator->new();

# obtain an expression to evaluate, either from the command line 
# or from STDIN:
my $expr = shift @ARGV;
unless ($expr){
    print "Please enter a mathematical expression:\n";
    $expr = <STDIN>;
}
my $result = eval { $m->parse($expr)->val(); };
if ($@) {
    print "There was an error\n";
} else {
    print "Result: $result\n";
}


