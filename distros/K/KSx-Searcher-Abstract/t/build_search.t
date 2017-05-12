#!perl

use strict;
use warnings;
use Test::More tests => 8;

use KSx::Searcher::Abstract;
my $s = "KSx::Searcher::Abstract";

# XXX need more tests than this, but I am too lazy to make a real invindex and
# schema.  -- hdp, 2007-07-01

for my $valid_query (
  { foo => 1 },
  { foo => { '=' => 1 } },
  { foo => { '!=' => 1 } },
) {
  my %data = eval { $s->build_abstract($valid_query) };
  is $@, "", "did not die on valid query";
}

for my $invalid_query (
  {},
  { foo => \17 },
  [],
) {
  eval { $s->build_abstract($invalid_query) };
  isnt $@, "", "did die on invalid query";
}

my %data = $s->build_abstract({ foo => 1 }, { sort => [ { field => 'foo' } ] });
is_deeply $data{sort_spec},
  {
    criteria => [
      { field => 'foo', reverse => 0 },
    ],
  },
  "build sort spec";

%data = $s->build_abstract(
  { foo => 1 },
  { sort => [ { field => 'foo' }, { field => 'bar', reverse => 1 } ] }
);

is_deeply $data{sort_spec},
  {
    criteria => [
      { field => 'foo', reverse => 0 },
      { field => 'bar', reverse => 1 },
    ],
  },
  "build sort spec (multiple)";
