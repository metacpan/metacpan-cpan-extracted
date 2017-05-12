use Test::More tests => 2;

BEGIN {
  use lib qw( ../lib ./lib );
  use_ok('Egg::Release');
  use_ok('Egg::Helper');
  };
