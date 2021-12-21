use strict;
use warnings;
use Test::More;
BEGIN { require './t/common.pl'; }

use Inline;
eval { Inline->bind(C => <<'END', structs => 1, force_build => 1) };
struct Foo {
   int src;
   int dst;
};
END

is $@, '', 'compiled without error';

done_testing;
