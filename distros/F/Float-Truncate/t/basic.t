use strict;
use Test::More;
use Float::Truncate qw/truncate truncate_force/;

# replace with the actual test

my $float = 1.556;

cmp_ok( truncate( $float, 2 ), '==', 1.56, 'truncate works' );
cmp_ok( truncate_force( $float, 2 ), '==', 1.55, 'truncate_force works' );

cmp_ok( truncate( $float ), '==', $float, 'truncate without length works' );
cmp_ok( truncate_force( $float ), '==', $float, 'truncate_force without length  works' );

cmp_ok( truncate( $float, 0 ), '==', 2, 'truncate to integer' );
cmp_ok( truncate_force( $float, 0 ), '==', 1, 'truncate_force to integer' );

done_testing;
