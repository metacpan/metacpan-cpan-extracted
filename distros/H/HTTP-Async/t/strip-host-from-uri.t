use strict;
use warnings;

use Test::More;
use HTTP::Async;
use URI;

my %tests = (
'http://www.w3.org:8080/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2'
      => '/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2',

    'http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2' =>
      '/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2',

    'https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2' =>
      '/Protocols/rfc2616/rfc2616-sec5.html?foo=bar#sec5.1.2',

    'https://www.w3.org:80/Protocols' => '/Protocols',

    'http://localhost:8080?delay=3' => '/?delay=3'
);

plan tests => scalar keys %tests;

while ( my ( $in, $expected ) = each %tests ) {
    my $out = HTTP::Async::_strip_host_from_uri( URI->new($in) );
    is $out, $expected, "correctly stripped $in to $out";
}
