#!/usr/bin/perl -w

# Compile-testing for Lingua::EN::VarCon

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib'),
			);
	}
}

use Test::More tests => 20;
use Lingua::EN::VarCon;

my @datasets = qw{ abbc also infl wroot voc };

foreach my $dataset ( @datasets ) {
	my $method = "${dataset}_file";
	my $file   = eval { Lingua::EN::VarCon->$method() };
	ok( $file, "->${method} returns a value" );
	is( $@, '', "->${method} does not throw an exception" );
	ok( -f $file, "->${method} returns a file that exists" );
	ok( -f $file, "->${method} returns a file that is readable" );
}

exit(0);
