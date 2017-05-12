use strict;
use warnings;
use Test::More;

eval "use Test::Valgrind; 1" or do {
    plan skip_all => 'Test::Valgrind is not installed.';
};

leaky();
