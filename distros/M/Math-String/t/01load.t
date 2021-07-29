#!perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Math::String');
    use_ok('Math::String::Charset');
    use_ok('Math::String::Charset::Grouped');
    use_ok('Math::String::Charset::Nested');
    use_ok('Math::String::Sequence');
};
