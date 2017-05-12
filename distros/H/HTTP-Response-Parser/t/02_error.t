use Test::More;

use HTTP::Response;
use HTTP::Response::Parser qw(parse_http_response);

require HTTP::Response::Parser::PP;
# require HTTP::Response::Parser::XS;
my $XS = eval {
    require HTTP::Response::Parser::XS;
    1 
};

note "XS: ", $XS ? "enabled" : "disabled";

use Data::Dumper;

my $tests = <<'__HEADERS';
HOGE

----------
-1
----------
HTTP/1.0 200 OK
----------
-2
----------
HTTP/1.0 200 OK
Content-Type: text/html
X-Test: 1
X-Test: 2

hogehoge
----------
61
----------
HTTP/1.0 200 OK
Content-Type: text/html
X-Test: 1
 X-Test: 2

hogehoge
----------
62
----------
HTTP/1.0 200 OK
Content-Type: text/html
----------
-2
__HEADERS


my $backend;

sub do_test {
    my @tests = split '-'x10, $tests;
    my $i = 0;
    while (@tests) {
        $i++;
        my $header = shift @tests;
        my $expect = shift @tests;
        $header =~ s/^\n//;
        last unless $expect;
        my $res = {};
        my $parsed = HTTP::Response::Parser::parse_http_response($header, $res);
        my $r   = eval($expect);
        is( $parsed, $r, "$backend $i");
    }
}

if ($XS) {
    $backend = "XS test";
    do_test();
    $backend = "PP test";
    *HTTP::Response::Parser::parse_http_response = *HTTP::Response::Parser::PP::parse_http_response;
    do_test();
} else {
    $backend = "PP test";
    do_test();
}

done_testing;
