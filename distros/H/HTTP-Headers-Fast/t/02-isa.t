use strict;
use warnings;
use Test::More;
use HTTP::Headers::Fast;
plan tests => 5;

my $h = HTTP::Headers::Fast->new();
isa_ok $h, 'HTTP::Headers';
isa_ok $h, 'HTTP::Headers::Fast';
ok $h->isa('HTTP::Headers');
ok $h->isa('HTTP::Headers::Fast');
ok ! $h->isa('Acme::Acotie');

