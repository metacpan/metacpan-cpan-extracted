use strict;

use Test::More;
plan tests => 2;

use HTTP::Headers::Fast;

my $h = HTTP::Headers::Fast->new;
is($h->content_type_charset, undef);

$h->content_type('text/plain; charset="iso-8859-1"');
is($h->content_type_charset, "ISO-8859-1");
