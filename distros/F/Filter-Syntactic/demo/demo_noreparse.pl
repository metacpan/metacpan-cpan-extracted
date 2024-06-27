#! /usr/bin/env perl

# Note that this code will NEVER work.
# It's not SUPPOSED to work; it's supposed to demonstrate the error detection
# facilities of the Filter::Syntactic module.
#
# It should throw a compile-time "..is not recursively self-consistent" error
# on the outer block, indicating that the replacement code for the nested blocks
# could not be parsed as a valid part of the outer block.
# 
# If the inner block is commented out, the "..not recursively self-consistent"
# error will not be generated, but you will still get the syntax errors(s)
# emanating from the invalid code that was inserted.

use 5.022;
use warnings;

use lib './demo/lib';
use NoReparse;
use Test::More;

>-{     ok 1, 'unnested block'   }-<

>-{
        ok 2, 'pre nested block';

    >-{ ok 3, 'in nested block' }-<

        ok 4, 'post nested block';

      { ok 5, '"old-style" block' }
}-<

done_testing();

