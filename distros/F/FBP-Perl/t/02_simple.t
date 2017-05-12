#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::Test;
use FBP::Perl;

# Find the sample files
my $input  = catfile( 't', 'data', 'simple.fbp' );
my $output = catfile( 't', 'data', 'dialog.pl'  );
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
my $perl = FBP::Perl->new(
	project => $project,
	version => $FBP::Perl::VERSION,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $perl, 'FBP::Perl' );
is( $perl->i18n,      1, '->i18n'      );
is( $perl->i18n_trim, 0, '->i18n_trim' );

# Test Dialog string generators
my $dialog = $fbp->form('MyDialog1');
isa_ok( $dialog, 'FBP::Dialog' );

# Generate the entire dialog constructor
my $have = $perl->dialog_class($dialog);
my $want = slurp($output);
code( $have, $want, '->dialog_class ok' );
compiles( $have, 'MyDialog1', 'Dialog class compiled' );





######################################################################
# Unit Testing

# Regression test for ourisa
SCOPE: {
	is_deeply(
		$perl->ourisa('Foo'),
		[
			"our \@ISA     = 'Foo';",
		],
		'->ourisa(single) ok',
	);

	is_deeply(
		$perl->ourisa('Foo', 'Bar'),
		[
			"our \@ISA     = qw{",
			"\tFoo",
			"\tBar",
			"};",
		],
		'->ourisa(multiple) ok',
	);
}
