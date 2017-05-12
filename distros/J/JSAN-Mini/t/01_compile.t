#!/usr/bin/perl

# Compile testing for minijsan

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';

# Does the module load
require_ok('JSAN::Mini'   );

# Does the csync script compile
my $script = $ENV{HARNESS_ACTIVE}
	? catfile( 'script', 'minijsan' )
	: catfile( updir(), 'script', 'minijsan' );
ok( -f $script, "Found script minijsan where expected at $script" );
SKIP: {
	skip "Can't find minijsan to compile test it", 1 unless -f $script;
	my $include = '';
	unless ( $ENV{HARNESS_ACTIVE} ) {
		$include = '-I' . catdir( updir(), 'lib');
	}
	my $cmd = "perl $include -c $script 1>/dev/null 2>/dev/null";
	# diag( $cmd );
	my $rv = system( $cmd );
	is( $rv, 0, "Script $script compiles cleanly" );
}
