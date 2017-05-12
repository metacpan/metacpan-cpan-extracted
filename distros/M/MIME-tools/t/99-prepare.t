#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 1;

# TBone used to do this, but thankfully, we've done away with that
my $output_dir = './testout';
if( ! -d $output_dir ) {
	mkdir $output_dir or warn "Could not make output directory: $!"
}

ok( -d $output_dir, "$output_dir exists" );

1;
