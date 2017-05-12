package MyLib;

use Test::More;

sub import {
    ok 0, "Shouldn't be imported because another path should take precedence";
}

1;
