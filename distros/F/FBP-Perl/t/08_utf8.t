#!/usr/bin/perl

use utf8;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 20;
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
# String Generation

SCOPE: {
	my $trivial = $code->quote("Foo");
	is( $trivial, '"Foo"', 'Trivial string matches' );
	ok( ! utf8::is_utf8($trivial), 'Trivial string is not unicode' );

	my $escapes = $code->quote("\tFoo\n");
	is( $escapes, '"\\tFoo\\n"', 'String with escapes matches' );
	ok( ! utf8::is_utf8($escapes), 'String with escapes is not unicode' );

	my $slash = $code->quote("\\");
	is( $slash, '"\\\\"', "String with slash matches" );
	ok( ! utf8::is_utf8($slash), "String with slash is not unicode" );

	my $french = $code->quote("Féo");
	is( $french, '"F\x{e9}o"', 'String with sub-\x{100} french character matches' );
	ok( ! utf8::is_utf8($french), 'String with sub-\x{100} french character is not unicode' );

	my $latin = $code->quote("Fɷoɷo");
	is( $latin, '"Fɷoɷo"', 'String with latin characters matches' );
	ok( utf8::is_utf8($latin), 'String with latin characters is unicode' );

	SKIP: {
		if ( $ENV{ADAMK_RELEASE} ) {
			skip("Ignoring known-broken for release", 4);
		}

		my $mixed = $code->quote("\tF\\ɷo\n");
		is( $mixed, '"\\tF\\\\ɷo\\n"', "String with mixed latin and escapes matches" );
		ok( utf8::is_utf8($mixed), 'String with mixed latin and escapes is unicode' );

		my $tricksy = $code->quote("\\x{1234}\\é\\");
		is( $tricksy, '"\\\\x{1234}\\\\\x{e9}\\\\"', "Tricksy string ok" );
		ok( ! utf8::is_utf8($tricksy), 'Tricksy string not unicode' );
	}
}
