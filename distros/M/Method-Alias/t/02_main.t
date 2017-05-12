#!/usr/bin/perl -w

# Load testing for Method::Alias

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
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 10;




# Test the test package
is( Foo->foo,  1, '->foo returns as expected'           );
is( Foo->bar,  1, 'A single alias works as expected'    );
is( Foo->baz,  1, 'A duplicate alias works as expected' );
is( Foo->blah, 1, 'Double alias works as expected'     );







#####################################################################
# Testing Package

package Foo;

use Test::More;
use Method::Alias 'bar'  => 'foo',
                  'baz'  => 'foo',
                  'blah' => 'bar';

sub foo { 1 }

ok( Method::Alias->import( 'this', 'foo' ),
	'Direct call to import returns true' );
is( Foo->this, 1, 'Resulting alias is created' );





#####################################################################
# Testing Subclass

package Foo::Bar;

use Test::More;

use strict;
use base 'Foo';

sub foo { 2 }

# When we call bar from THIS class, we should now get 2
is( Foo->foo, 1, '->foo from original returns as expected' );
is( Foo::Bar->foo, 2, '->from from subclass returns as expected' );
is( Foo::Bar->bar, 2, '->bar from subclass returns as expected' );
is( Foo::Bar->blah, 2, 'Double from subclass returns as expected' );

1;
