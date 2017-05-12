use Test::More tests => 4;
use lib qw( ./lib ../lib );

BEGIN {
  use_ok 'Egg::Release::DBIC';
  use_ok 'Egg::Model::DBIC';
  use_ok 'Egg::Model::DBIC::Schema';
  use_ok 'Egg::Helper::Model::DBIC';
  };

