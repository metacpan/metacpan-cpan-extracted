use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::Test::KENTNL qw( test_config );
use Test::Fatal;

is( defined &test_config, 1, '&test_config exported' );

is(
  exception {
    test_config(
      {
        dist_root => 'corpus/dist/DZT',
        ini       => ['GatherDir']
      }
    );
  },
  undef,
  'test_config lives'
);

done_testing;

