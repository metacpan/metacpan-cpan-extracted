# this test was generated with Dist::Zilla::Plugin::Test::Kwalitee 2.11
use strict;
use warnings;
use Test::More 0.88;
use Test::Kwalitee 1.21 'kwalitee_ok';

kwalitee_ok( qw( -has_meta_yml -metayml_is_parsable ) );

done_testing;
