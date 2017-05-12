use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $someref = +{};

my $hr = hash(
  scalar => 1,

  hash => +{
    a => 1,
    b => +{
      x => 10
    },
  },

  hashobj => hash(
    c => $someref,
    d => [],
    e => [
      1, { z => 9 },
    ],
  ),
);

cmp_ok $hr->get_path('scalar'), '==', 1,
  'shallow get_path ok';

cmp_ok $hr->get_path(qw/hash b x/), '==', 10,
  'deep get_path ok';

cmp_ok $hr->get_path(qw/hashobj c/), '==', $someref,
  'hash obj get_path ok';

ok !defined $hr->get_path(qw/hashobj c foo/),
  'nonexistant element at end of path returned undef';

ok !defined $hr->get_path(qw/foo bar baz/),
  'nonexistant element at start of path returned undef';

my @item = $hr->get_path(qw/foo bar baz/);
ok @item == 1 && !defined $item[0],
  'get_path returned explicit undef';

cmp_ok $hr->get_path( 'hashobj', 'e', [1], 'z' ), '==', 9,
  'get_path with array elements ok';

ok !$hr->exists('foo'), 'no autoviv ok';

eval {; $hr->get_path(qw/hashobj d foo /) };
ok $@, 'attempting to access array as hash dies';

eval {; $hr->get_path(hashobj => c => [1]) };
ok $@, 'attempting to access hash as array dies';

done_testing
