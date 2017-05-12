use Test::More 'tests' => 2;

use_ok( 'MIME::Structure' );

my $obj = MIME::Structure->new;

isa_ok( $obj, 'MIME::Structure' );

