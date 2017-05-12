use strict;
use warnings;

use Test::More;
plan skip_all => 'HTTP::Headers::Fast is necessary' unless eval "use HTTP::Headers::Fast; 1;";
plan tests => 5;

use HTTP::XSHeaders;

my $h = HTTP::Headers::Fast->new();
isa_ok $h, 'HTTP::Headers';
isa_ok $h, 'HTTP::Headers::Fast';
ok $h->isa('HTTP::Headers');
ok $h->isa('HTTP::Headers::Fast');
ok ! $h->isa('Acme::Acotie');

