#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long; 
use File::Basename;

my $prog = basename($0);
my $verbose;
#my $dryrun;

# Usage() : returns usage information
sub Usage {
    "$prog [--verbose]\n";
    #"$prog [--verbose] [--dryrun]\n";
}

# call main()
main();

# main()
sub main {
    GetOptions(
        "verbose!" => \$verbose,
        #"dryrun!" => \$dryrun,
    ) or die Usage();
    
    # assumes presence of correct ~/.coinbasepro file

    my @cmds = (
        "./bin/coinbasepro.pl", 

        "./bin/coinbasepro.pl ticker",

        "./bin/coinbasepro.pl ticker --product ETH-USD",

        "./bin/coinbasepro.pl accounts",

        "./bin/coinbasepro.pl products",

        "echo 'No' '\n' | ./bin/coinbasepro.pl sell -price 6401.66 -size 0.01",

        "echo 'No' '\n' | ./bin/coinbasepro.pl buy -price 6401.66 -size 0.01",

    );

    for my $cmd (@cmds) {
        print "\% $cmd\n";
        system( $cmd );
        print "\n";
    }
}
