#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HPC::Runner::Slurm' ) || print "Bail out!\n";
}

diag( "Testing HPC::Runner::Slurm $HPC::Runner::Slurm::VERSION, Perl $], $^X" );
