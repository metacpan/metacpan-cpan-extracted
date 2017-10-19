#!perl
use utf8;
use warnings;
use strict;

use Test::More;

BEGIN { use_ok('Lingua::FuzzyTrans::PT2GL'); }

my @array = Lingua::FuzzyTrans::PT2GL::translate('coração');

ok (scalar(@array) > 0);
is_deeply( [sort("corazón", "coración")], [sort @array]);

done_testing();
