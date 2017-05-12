#!perl

use Test::More tests => 4;

use HTTP::Headers::Fancy qw(build_field_list);

is build_field_list( 'a',  'b',  'c' )  => '"a", "b", "c"';
is build_field_list( \'a', \'b', \'c' ) => 'W/"a", W/"b", W/"c"';
is build_field_list( [ \'a', \'b', \'c' ] ) => 'W/"a", W/"b", W/"c"';
is build_field_list( [ 'a',  'b',  'c' ] )  => '"a", "b", "c"';

done_testing;
