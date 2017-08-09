use warnings;
use strict;

use Test::More;

plan tests => 6;

use Dios;

class Foo {
    subtype Bar of Int;

    has Bar $.bar is rw;

    method comp(Bar $x) {
        $bar == $x
    }
}

ok( my $obj = Foo->new(bar=>1) );
is $obj->get_bar, 1;
ok $obj->comp(1);
ok !$obj->comp(2);
ok eval { $obj->set_bar(-1); };
ok !eval { $obj->set_bar('a'); };



done_testing();

