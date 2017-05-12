#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::Test;
use FBP::Perl;

# Find the sample files
my $input  = catfile( 't', 'data', 'simple.fbp' );
my $output = catfile( 't', 'data', 'script.pl'  );
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
	project  => $project,
	version  => $FBP::Perl::VERSION,
	nocritic => 1,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );

# Generate the entire dialog constructor
my $have = $code->script_app;
my $want = slurp($output);
code( $have, $want, '->app_class ok' );
compiles( $have, undef, 'Project class compiled' );
