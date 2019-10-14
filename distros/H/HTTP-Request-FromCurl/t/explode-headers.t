#!perl
use strict;
use warnings;
use Test::More tests => 1;

use HTTP::Request::CurlParameters;

my $cp = HTTP::Request::CurlParameters->new(
    headers => {
        'X-Host' => ['host1', 'host2'],
    }
);

#my $r = $cp->as_request();
#is_deeply $r->headers->flatten, [], "Headers are as we expect";

is_deeply [$cp->_explode_headers], [
    'X-Host' => 'host1',
    'X-Host' => 'host2',
], "Headers explode as we expect";
