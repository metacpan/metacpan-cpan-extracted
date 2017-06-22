use warnings;
use strict;

use Test::More;
use lib './tlib', '../tlib';

use Keyword::Export::Test;

test1;
test 2;
test3 3;
test4 { note 'test3' }

# Implementation here


done_testing();

