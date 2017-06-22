use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keytype ComLab is Comment|Label;

keyword try (Block|Expr $n) {{{ ok 1, 'Block|Expr' }}}
keyword comlab (ComLab $n) {{{ ok 1, 'Comment|Label' }}}
keyword intstrtypeglob (Int|Str|Typeglob $n) {{{ ok 1, 'Int|Str|Typeglob' }}}

ok 1, 'Compiled';

done_testing();

