#!perl -Tw

use strict;
use warnings;
use Test::More tests => 4;
use URI::file;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY PATH IFS CDPATH ENV BASH_ENV) }; }
use_ok( 'LWP::Curl' );

my $lwpcurl = LWP::Curl->new( );
isa_ok( $lwpcurl, 'LWP::Curl' );

my $get_uri = "http://localhost:3000/";
my $post_uri = "http://localhost:3000/foo";

my $post_data = {
	'foo' => 'bar',
	'lorn' => 'mizifadf',
	'xasa' => '12345',
	'fgughugh' => 'zcxjnxzjnczjxn',
	'zazazaz' => '1232412412',
	'hvbhvbvhb' => '555555',
	'okokokokokk' => "ifjidjifdj",
};

ok($lwpcurl->get( $get_uri ));
#ok( $lwpcurl->success, $get_uri );

ok($lwpcurl->post( $post_uri, $post_data, $get_uri));
