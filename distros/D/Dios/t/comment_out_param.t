use warnings;
use strict;

use Test::More;
use Carp;
$SIG{__DIE__} = sub { Carp::confess @_ };

plan tests => 2;

use Test::More;

use Dios;

class Test1 {
    has $.foo;
    submethod BUILD (
#        :$foo
    )
    { 42 }
}

class Test2 {
    has $.foo;
    submethod BUILD (
        :bar($new_bar)
    )
    { 42 }
}

ok eval { Test1->new({foo => 1}) }, 'ignore comment';
ok eval { Test2->new({foo => 1}) }, 'labeled argument';

done_testing();

