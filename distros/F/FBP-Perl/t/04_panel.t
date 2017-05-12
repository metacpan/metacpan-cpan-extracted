#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::Test;
use FBP::Perl;

# Find the sample files
my $input  = catfile( 't', 'data', 'simple.fbp' );
my $output = catfile( 't', 'data', 'panel.pl'  );
ok( -f $input,  "Found test file $input"  );
ok( -f $output, "Found test file $output" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($input), '->parse_file ok' );

# Create the generator object
my $project = $fbp->find_first(
	isa => 'FBP::Project',
);
my $code = FBP::Perl->new(
	project => $project,
	version => $FBP::Perl::VERSION,
	prefix  => 1,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );

# Test Dialog string generators
my $panel = $fbp->form('MyPanel1');
isa_ok( $panel, 'FBP::FormPanel' );

# Generate the entire dialog constructor
my $have = $code->panel_class($panel);
my $want = slurp($output);
code( $have, $want, '->panel_class ok' );
SKIP: {
	unless ( $^O eq 'MSWin32' ) {
		skip("Top level panels seem to segfault on Unix", 4);
	}
	compiles( $have, 'MyPanel1', 'Panel class compiled' );
}
