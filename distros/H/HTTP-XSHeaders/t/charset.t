use strict;
use warnings;

use Test::More;
plan tests => 2;

use HTTP::XSHeaders;

my $h = HTTP::XSHeaders->new;
is($h->content_type_charset, undef);

$h->content_type('text/plain; charset="iso-8859-1"');
is($h->content_type_charset, "ISO-8859-1");
