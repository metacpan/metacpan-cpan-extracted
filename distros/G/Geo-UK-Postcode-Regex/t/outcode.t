use Test::More;

use strict;
use warnings;

use Geo::UK::Postcode::Regex;

my $pkg = 'Geo::UK::Postcode::Regex';

note "extract outcode";
is $pkg->outcode('AB10 1AA'), 'AB10', "full";
is $pkg->outcode('AB101AA'),  'AB10', "full - no space";
is $pkg->outcode('B1 1AA'),   'B1',   "full";
is $pkg->outcode('B1 1'),     'B1',   "sector";
is $pkg->outcode('B1'),       'B1',   "district";
is $pkg->outcode('WC1H 9EB'), 'WC1H', "with subdistrict";
is $pkg->outcode('WC1H9EB'),  'WC1H', "with subdistrict - no space";

note "case-insensitive";
is $pkg->outcode( 'ab10 1aa', { 'case-insensitive' => 1 } ), 'AB10', "full";

note "full only";
is $pkg->outcode( 'AB10 1AA', { partial => 0 } ), 'AB10', "full";
ok !$pkg->outcode( 'AB10', { partial => 0 } ), 'partial fails';

note "valid only";
is $pkg->outcode( 'AB10 1AA', { valid => 1 } ), 'AB10', "valid";
ok !$pkg->outcode( 'AB1', { valid => 1 } ), 'invalid fails';

note "strict";
is $pkg->outcode( 'AB10 1AA', { strict => 1 } ), 'AB10', "full";
is $pkg->outcode( 'AB10',     { strict => 1 } ), 'AB10', 'partial';
ok !$pkg->outcode( 'AB10A 1AA', { strict => 1 } ), 'invalid full fails';
ok !$pkg->outcode( 'AB10A',     { strict => 1 } ), 'invalid partial fails';

note "non-geo";
is $pkg->outcode('YO91 1AA'), 'YO91', 'full';
is $pkg->outcode('YO91'),     'YO91', 'partial';

done_testing();

