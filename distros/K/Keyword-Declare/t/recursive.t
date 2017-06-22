use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keyword recurse                          {{{ recurse 0 0 0                  }}}
keyword recurse (Int $i)                 {{{ recurse «$i» 0 0               }}}
keyword recurse (Int $i, Int $j)         {{{ recurse «$i» «$j» 0            }}}
keyword recurse (Int $i, Int $j, Int $k) {{{ ok 1, 'recurse «$i» «$j» «$k»' }}}

recurse;
recurse 2;
recurse 3 3;
recurse 4 4 4;

done_testing();

