
use Test::More tests => 2;

use List::StackBy;

my @uniq = map { $_->[0] } stack_by { uc } qw/A B b A b B A/;
# A B A b A

is_deeply(\@uniq, [qw/A B A b A/]);

my @by_col1 = stack_by { /^\s*(\d+)/ ? $1 : undef } (
  "123,foo",
  "123,bar",
  "456,baz",
);


is_deeply(\@by_col1, [["123,foo", "123,bar"], ["456,baz"]]);
