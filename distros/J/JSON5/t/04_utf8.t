use strict;
use warnings;
use utf8;

use Encode;
use Test::More 0.98;

use JSON5;

my $json5 = JSON5->new->utf8->allow_nonref;
isa_ok $json5, 'JSON5';

is $json5->decode(Encode::encode_utf8('"寿司"')), '寿司', 'decode utf8 json5';

done_testing;

