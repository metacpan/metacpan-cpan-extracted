use strict;

use vars qw( @modules );
use Test::More tests => 9;

BEGIN {
  use_ok("List::Sliding::Changes");
};

is_deeply([List::Sliding::Changes::find_new_elements([],[])],[],"An empty list has no changes");
is_deeply([List::Sliding::Changes::find_new_elements([1,2,3],[])],[],"Empty list on the right has no changes");
is_deeply([List::Sliding::Changes::find_new_elements([],[1])],[1],"Empty list on the left returns element on the right");

is_deeply([List::Sliding::Changes::find_new_elements([],[1,2,3])],[1,2,3],"Empty list on the left returns elements on the right");
is_deeply([List::Sliding::Changes::find_new_elements([1],[1,2,3])],[2,3],"One element on the left returns two elements on the right");
is_deeply([List::Sliding::Changes::find_new_elements([1,2],[1,2,3])],[3],"Two elements on the left returns 1 element on the right");
is_deeply([List::Sliding::Changes::find_new_elements([1,2,3],[1,2,3])],[],"Same elements left and right returns no element");
is_deeply([List::Sliding::Changes::find_new_elements([1..100],[99..102])],[101,102],"Large list");