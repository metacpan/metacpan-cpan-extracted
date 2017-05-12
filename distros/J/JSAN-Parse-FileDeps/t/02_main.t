#!/usr/bin/perl -w

# Main testing for JSAN::Parse::FileDeps

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use JSAN::Parse::FileDeps ();

my $input  = catfile( 't', 'lib', 'foo.js'      );
my $output = catfile( 't', 'lib', 'foo_deps.js' );

# What should be in the header
my $expected = <<__EXP__;
JSAN.use( "Foo" );
JSAN.use('Foo.Bar', 'symbol' );

__EXP__





#####################################################################
# Begin tests

# Does the input file exist
ok( -e $input, 'Found test file' );

# Clean the output file before and after
unlink $output if -e $output;
END {
	unlink $output if -e $output;
}

# Test find_deps_js
my @lines = JSAN::Parse::FileDeps->find_deps_js( $input );
is( join('', @lines), $expected, '->find_deps_js returns as expected' );

# Test library_deps
my @libraries = JSAN::Parse::FileDeps->library_deps( $input );
is_deeply( \@libraries, [ 'Foo', 'Foo.Bar' ],
	'->library_deps returns as expected' );

# Test file_deps
my @files = JSAN::Parse::FileDeps->file_deps( $input );
is_deeply( \@files, [ 'Foo.js', catfile( 'Foo', 'Bar.js' ) ],
	'->file_deps returns as expected' );

# Test make_deps_js
my $rv = JSAN::Parse::FileDeps->make_deps_js( $input );
ok( $rv, '->make_deps_js returns true' );
ok( -e $output, "$output created ok" );

open TESTER, '<', $output;
my $content = join '', <TESTER>;
close TESTER;

is( $content, $expected, "And it contains the expected content");
