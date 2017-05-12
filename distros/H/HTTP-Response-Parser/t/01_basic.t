#!perl -w
use strict;
use Test::More;

use HTTP::Response;
use HTTP::Response::Parser qw(parse);

require HTTP::Response::Parser::PP;
# require HTTP::Response::Parser::XS;
my $XS = eval {
    require HTTP::Response::Parser::XS;
    1 
};

no warnings 'misc';

use Data::Dumper;

my $tests = <<'__HEADERS';
HTTP/1.0 200 OK

----------
{
 '_content' => '',
 '_protocol' => 'HTTP/1.0',
 '_headers' => {},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.0 200 OK
Content-Type: text/html

hogehoge
----------
{
 '_content' => "hogehoge\n",
 '_protocol' => 'HTTP/1.0',
 '_headers' => { "content-type" => "text/html"},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.0 200 OK
Content-Type: text/html
X-Test: 1
X-Test: 2

hogehoge
----------
{
 '_content' => "hogehoge\n",
 '_protocol' => 'HTTP/1.0',
 '_headers' => { "content-type" => "text/html", "x-test" => [1,2]},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.0 200 OK
Content-Type: text/html
X-Test: 1
 X-Test: 2

hogehoge
----------
{
 '_content' => "hogehoge\n",
 '_protocol' => 'HTTP/1.0',
 '_headers' => { "content-type" => "text/html", "x-test" => "1\n X-Test: 2"},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.0 200 OK
Content-Type: text/html
----------
{
 '_content' => "",
 '_protocol' => 'HTTP/1.0',
 '_headers' => { "content-type" => "text/html"},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.1 200 OK
Content-Type: text/html
----------
{
 '_content' => "",
 '_protocol' => 'HTTP/1.1',
 '_headers' => { "content-type" => "text/html"},
 '_rc' => 200,
 '_msg' => 'OK'
}
----------
HTTP/1.1 404 Not Found
Content-Type: text/html
----------
{
 '_content' => "",
 '_protocol' => 'HTTP/1.1',
 '_headers' => { "content-type" => "text/html"},
 '_rc' => 404,
 '_msg' => 'Not Found'
}
----------
HTTP/1.1 200 OK
Content-Type: text/html
FOO_BAR: 42
----------
{
 '_content' => "",
 '_protocol' => 'HTTP/1.1',
 '_headers' => { "content-type" => "text/html", "foo-bar" => 42},
 '_rc' => 200,
 '_msg' => 'OK'
}
__HEADERS

my $backend;

sub do_test {
    note $backend;
    my @tests = split '-'x10, $tests;
    my $i = 0;
    while (@tests) {
        $i++;
        my $header = shift @tests;
        my $expect = shift @tests;
        $header =~ s/^\n//;
        last unless $expect;
        my $res = parse($header);
        my $r   = eval($expect);
        is_deeply( $res, $r, $backend . " " . $i);
        isa_ok( $res,             'HTTP::Response' );
        isa_ok( $res->{_headers}, 'HTTP::Headers' );
    }
}

if ($XS) {
    $backend = "XS test";
    do_test();
    $backend = "PP test";
    *HTTP::Response::Parser::parse_http_response = *HTTP::Response::Parser::PP::parse_http_response;
    do_test();
} else {
    $backend = 'PP';
    do_test();
}

done_testing;
