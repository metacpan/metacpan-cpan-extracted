#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN { 
	chdir 't' if -d 't' ;
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

my @poddirs = qw( ../lib );
all_pod_files_ok( all_pod_files( @poddirs ) );
