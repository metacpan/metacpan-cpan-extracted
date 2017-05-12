#!perl -w

BEGIN { chdir 't' if -d 't' }

use strict;
use Test::More 'no_plan'; # tests => 19;

use_ok( 'Devel::Constants' );
can_ok( 'Devel::Constants', 'import' );

my @funcs = qw( flag_to_names to_name );

package no_import;

Devel::Constants->import();

for my $func ( @funcs )
{
	::ok( ! __PACKAGE__->can( $func ),
		"import() should not import $func() by default" );
}

package import;

Devel::Constants->import( @funcs );

for my $func ( @funcs )
{
	::ok( __PACKAGE__->can( $func ),
		"import() should import $func() if requested" );
}
