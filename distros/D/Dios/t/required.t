# Test the $arg! required syntax

use strict;
use warnings;

use Test::More;

{
    package Stuff;

    use Test::More;
    use Test::Exception;
    use Dios;

    method whatever($this!) {
        return $this;
    }

    is( Stuff->whatever(23),    23 );

#line 23
    throws_ok { Stuff->whatever() }
              qr{No argument found for positional parameter \$this in call to method whatever}
        =>  'simple required param error okay';

    method some_optional($that!, $this = 22) {
        return $that + $this
    }

    is( Stuff->some_optional(18), 18 + 22 );

#line 33
    throws_ok { Stuff->some_optional() }
              qr{No argument found for positional parameter \$that in call to method some_optional}
        =>  'some required/some not required param error okay';
}


done_testing();
