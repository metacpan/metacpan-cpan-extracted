# (also see utilsby_no_xs.t)
use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

if ($List::Objects::WithUtils::Role::Array::UsingUtilsByXS) {
  diag "\nUsing List::UtilsBy::XS\n"
} else {
  diag "\nUsing List::UtilsBy (XS not found)\n"
}

my $arr = [
  +{ id => 'c' },
  +{ id => 'a' },
  +{ id => 'b' },
];

my $sorted = $arr->sort_by(sub { $_->{id} });

is_deeply
  [ $sorted->all ],
  [ +{ id => 'a' }, +{ id => 'b' }, +{ id => 'c' } ],
  'boxed sort_by ok';

ok []->sort_by(sub { $_->foo })->is_empty,
  'boxed empty array sort_by ok';

done_testing;
