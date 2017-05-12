use strict; use warnings FATAL => 'all';

BEGIN {
  unless (eval {; require Test::Without::Module; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests require Test::Without::Module');
  }
}

use Test::Without::Module 'List::UtilsBy::XS';

use Test::More;
use List::Objects::WithUtils;


ok !$List::Objects::WithUtils::Role::Array::UsingUtilsByXS,
  'List::UtilsBy::XS not loaded';

# sort_by
ok array->sort_by(sub { $_->foo })->is_empty, 'empty array sort_by ok';
my $arr = array(
  +{ id => 'c' },
  +{ id => 'a' },
  +{ id => 'b' },
);

my $sorted = $arr->sort_by(sub { $_->{id} });

is_deeply
  [ $sorted->all ],
  [ +{ id => 'a' }, +{ id => 'b' }, +{ id => 'c' } ],
  'sort_by ok';

# nsort_by
ok array->nsort_by(sub { $_->foo })->is_empty, 'empty array nsort_by ok';
$arr = array(
  +{ id => 2 },
  +{ id => 1 },
  +{ id => 3 },
);

$sorted = $arr->nsort_by(sub { $_->{id} });

is_deeply
  [ $sorted->all ],
  [ +{ id => 1 }, +{ id => 2 }, +{ id => 3 } ],
  'nsort_by ok';

# uniq_by
ok array->uniq_by(sub { $_->foo })->is_empty, 'empty array uniq_by ok';
$arr = array(
  +{ id => 1 },
  +{ id => 2 },
  +{ id => 1 },
  +{ id => 3 },
  +{ id => 3 },
);
my $uniq = $arr->uniq_by(sub { $_->{id} });
is_deeply
  [ $uniq->all ],
  [
    +{ id => 1 },
    +{ id => 2 },
    +{ id => 3 },
  ],
  'uniq_by ok';

done_testing;

