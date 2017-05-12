#!perl
use strict;
use warnings;
use JSON::XS::VersionOneAndTwo;
use Test::More tests => 4;

my $data = { 'three' => [ 1, 2, 3 ] };

my $json = encode_json($data);
is( $json, '{"three":[1,2,3]}' );
my $newdata = decode_json($json);
is_deeply( $data, $newdata );

$json = to_json($data);
is( $json, '{"three":[1,2,3]}' );
$newdata = from_json($json);
is_deeply( $data, $newdata );
