#!perl

use 5.010;
use strict;
use warnings;

use Hash::DefHash::Normalize qw(normalize_defhash);
use Test::Exception;
use Test::More 0.98;

is_deeply(normalize_defhash({}), {});
is_deeply(normalize_defhash({v=>1, summary=>"foo", "summary(id)"=>"fu"}), {v=>1, summary=>"foo", "summary.alt.lang.id"=>"fu"});
dies_ok { normalize_defhash({"a "=>1}) };
dies_ok { normalize_defhash({"summary (id)"=>1}) };

# opt: remove_internal_properties
is_deeply(normalize_defhash({_a=>1, b=>2, 'c._d'=>3, 'c.e'=>4}),
          {_a=>1, b=>2, 'c._d'=>3, 'c.e'=>4});
is_deeply(normalize_defhash({_a=>1, b=>2, 'c._d'=>3, 'c.e'=>4}, {remove_internal_properties=>1}),
          {b=>2, 'c.e'=>4});

DONE_TESTING:
done_testing;
