#!perl

use Test::More tests => 11;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Request::AsCGI;
use Encode;

$ENV{__PRESERVE_ENV_TEST} = 1;

my $r = HTTP::Request->new( GET => 'http://www.host.com/cgi-bin/script.cgi/my%20path%2F?a=1&b=2', [ 'X-Test' => 'Test' ] );
my %e = (
  SCRIPT_NAME => '/cgi-bin/script.cgi',
# test a utf-8 PATH_INFO, sort of (and safe decoding)
  PATH_INFO =>
  '/foo%2F%C3%90%C2%91%C3%90%C2%AF%C3%A9%C2%99%C2%B0%C3%A8%C2%8C%C2%8E',
);
my $c = HTTP::Request::AsCGI->new( $r, %e );
$c->stdout(undef);

$c->setup;

is( $ENV{GATEWAY_INTERFACE}, 'CGI/1.1', 'GATEWAY_INTERFACE' );
is( $ENV{HTTP_HOST}, 'www.host.com:80', 'HTTP_HOST' );
is( $ENV{HTTP_X_TEST}, 'Test', 'HTTP_X_TEST' );
is( decode('UTF-8', $ENV{PATH_INFO}), '/foo/БЯ陰茎', 'PATH_INFO');
is( $ENV{QUERY_STRING}, 'a=1&b=2', 'QUERY_STRING' );
is( $ENV{SCRIPT_NAME}, '/cgi-bin/script.cgi', 'SCRIPT_NAME' );
is( $ENV{REQUEST_METHOD}, 'GET', 'REQUEST_METHOD' );
is( $ENV{SERVER_NAME}, 'www.host.com', 'SERVER_NAME' );
is( $ENV{SERVER_PORT}, '80', 'SERVER_PORT' );

is( $ENV{__PRESERVE_ENV_TEST}, 1, 'PRESERVE_ENV' );

$c->restore;

is( $ENV{GATEWAY_INTERFACE}, undef, 'No CGI env after restore' );
