#!perl

use Test::More tests => 7;

use HTTP::Headers::Fancy qw(build_field_hash);

is build_field_hash() => '';
is build_field_hash( xxx => undef ) => 'xxx';
is build_field_hash( xxx => undef, yyy => undef ) => 'xxx, yyy';
is build_field_hash( xxx => '',    yyy => undef ) => 'xxx=, yyy';
is build_field_hash( xxx => undef, yyy => '' )    => 'xxx, yyy=';
is build_field_hash( xxx => '=',   yyy => ',' )   => 'xxx="=", yyy=","';
is build_field_hash( { xxx => '=', yyy => ',' } ) => 'xxx="=", yyy=","';

done_testing;
