use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => Config => force_build => 1, clean_after_build => 0;

use Inline 'info';
use Inline CPP => <<'EOCPP';
int add (int x, int y) {
  return x+y;
}
EOCPP

is add(1,1), 2, 'info not break compiling';

done_testing();
