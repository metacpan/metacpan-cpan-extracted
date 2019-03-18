use warnings;
use strict;

use Test::More;

plan tests => 1;


use Keyword::Declare;

keyword _under_ {{{ ok 'Keyword accepted' }}}

_under_;


done_testing();

