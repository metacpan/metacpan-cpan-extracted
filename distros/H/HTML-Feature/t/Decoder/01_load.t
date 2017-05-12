use strict;
use warnings;
use HTML::Feature::Decoder;
use Test::More tests => 4;

my $decoder = HTML::Feature::Decoder->new;

isa_ok($decoder, 'HTML::Feature::Decoder');
isa_ok($decoder->decoder, 'Data::Decode');

can_ok($decoder, "new");
can_ok($decoder, "decode");
