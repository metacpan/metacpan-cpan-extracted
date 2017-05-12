#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::Test;
use FBP::Perl;

# Find the sample files
my $input  = catfile( 't', 'data', 'demo.fbp' );
ok( -f $input,  "Found test file $input"  );

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
	version  => '0.01',
	nocritic => 1,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );





######################################################################
# Frame Generation

SCOPE: {
	my $output= catfile( 't', 'data', 'FBP-Demo', 'lib', 'FBP', 'Demo', 'Main.pm' );
	ok( -f $output, "Found test file $output" );

	# Generate the frame code
	my $frame = $fbp->find_first( isa => 'FBP::Frame' );
	my $have  = $code->form_class($frame);
	my $want  = slurp($output);
	SKIP: {
		if ( $ENV{ADAMK_RELEASE} ) {
			skip("Ignoring known-broken for release", 1);
		}

		code( $have, $want, '->app_class ok' );
	}
	compiles( $have, 'FBP::Demo::Main', 'Project class compiled' );
	$INC{'FBP/Demo/Main.pm'} = 1;
}





######################################################################
# App Generation

SCOPE: {
	my $output = catfile( 't', 'data', 'FBP-Demo', 'lib', 'FBP', 'Demo.pm' );
	ok( -f $output, "Found test file $output" );

	# Generate the launch script
	my $have = $code->app_class;
	my $want = slurp($output);
	code( $have, $want, '->app_class ok' );
	compiles( $have, 'FBP::Demo', 'Project class compiled' );
	$INC{'FBP/Demo.pm'} = 1;
}





######################################################################
# Script Generation

SCOPE: {
	my $output = catfile( 't', 'data', 'FBP-Demo', 'script', 'fbpdemo' );
	ok( -f $output, "Found test file $output" );

	# Generate the launch script
	my $have = $code->script_app;
	my $want = slurp($output);
	code( $have, $want, '->app_class ok' );
	compiles( $have, undef, 'Launch script compiled' );
}
