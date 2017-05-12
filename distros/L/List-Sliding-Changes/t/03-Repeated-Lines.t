use strict;

use vars qw( @tests );

BEGIN {
  @tests = (
    [[1,2],[2,3,4],[1,2],"One element overlap"],
    [[1,2,3],[2,3,4],[2],"Partial 2-element overlap"],
    [[1,2,3],[1,2,3,4],[3],"Bigger list"],
    [[1,2,3],[1,2,3,4,5,6],[3,4,5],"Multi-element bigger list"],
    [[3,3,3],[3,3,3,3],[3],"Simple repeating list"],
    [[3,3,3],[3,3,3,3,3],[3,4],"Multi-element repeating list"],
    [[1,2,3],[1,2,3,1,2,3],[3,4,5],"Repeated multi-element list"],
    [[1,2,3],[2,3,1,2,3],[2,3,4],"Partially repeated multi-element list"],
    [[3],[3,1,2,3],[1,2,3],"Partially repeated multi-element list"],
    [[3,1,2,3],[3,1,2,3],[],"Partially repeated multi-element list"],
    [[3,1,2,3],[3,1,2,3,1,2,3],[4,5,6],"Partially repeated multi-element list"],
    [[3,1,2,3],[3,1,2],[1,2],"Partially repeated multi-element list"],
  )
};

use Test::More tests => 1+scalar @tests *2;

BEGIN {
  use_ok("List::Sliding::Changes",'find_new_elements','find_new_indices');
};

my $test;
for $test (@tests) {
  my ($old,$new,$index,$name) = @$test;
  is_deeply([find_new_indices($old,$new)],$index,"Index: $name");
  is_deeply([find_new_elements($old,$new)],[@{$new}[@$index]],"Element: $name");
};