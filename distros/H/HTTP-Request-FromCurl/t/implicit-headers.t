#!perl
use strict;
use HTTP::Request::FromCurl;
use URI;
use Test::More;
use Data::Dumper;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

plan tests => 2;

my $h = HTTP::Request::FromCurl->new(
    command => q{curl -s -u $USER:$PWD --data '@mft.json' -H 'Content-Type: application/json' -X POST $EVENT_URL},
);

my $r = $h->as_snippet(
    implicit_headers => ['Content-Length'],
);

unlike $r, qr/Content-Length/, "We can exclude calculated headers"
    or diag $r;

$r = $h->as_snippet(
    implicit_headers => ['X-Content-Length'],
);

unlike $r, qr/X-Content-Length/, "We don't crash for unknown headers"
    or diag $r;

done_testing();
