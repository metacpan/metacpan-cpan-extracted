use strict;

use Test::More;
use HTTP::Exception;

# GitHub PR#4 - eval fails silently for HTTP 418

my @teapots = (
    HTTP::Exception->new(418),
    HTTP::Exception::418->new(),
    HTTP::Exception::I_AM_A_TEAPOT->new(),
);

plan tests => scalar @teapots * 2;

for my $e (@teapots) {
    is  $e->status_message, q~I'm a teapot~, 'status_message accessor exists';
    is  $e->code,           418, 'code accessor exists';
}
