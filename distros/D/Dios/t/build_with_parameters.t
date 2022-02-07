use warnings;
use strict;

use Test::More;
use Dios;

class Test1 {
    has $.foo = 1;
    submethod BUILD {
        ::is($foo, 1, 'Test1 - $foo from attribute after default BUILD for $foo');
    }
}

class Test2 {
    has $.foo = 1;
    submethod BUILD {
        ::is($foo, 2, 'Test2 - $foo from parameter after default BUILD for $foo');
    }
}

class Test3 {
    has $.foo = 1;
    submethod BUILD (:$bar) {
        ::is($foo, 1, 'Test3 - $foo from attribute after default BUILD for $foo');
        ::is($bar, 9, 'Test3 - $bar from parameter after default BUILD for $foo');
    }
}

class Test4 {
    has $.foo = 1;
    submethod BUILD (:$bar) {
        ::is($foo, 2, 'Test4 - $foo from parameter after default BUILD for $foo');
        ::is($bar, 9, 'Test4 - $bar from parameter after default BUILD for $foo');
    }
}

# These shpould generate compile-time errors
# (so there's no way to test them at run-time)
#
#class Test5 {
#    has $.foo = 1;
#    has $.baz = 2;
#    submethod BUILD (:$foo, :$bar, :$baz) {
#        ::is($foo, 2, 'Test5 - $foo from parameter while BUILD for $foo');
#    }
#}
#
#class Test6 {
#    has $.foo = 1;
#
#    submethod BUILD (:foo($newfoo)) {
#        ::is($newfoo, 2, 'Test6 - $newfoo from parameter while BUILD for $foo');
#        ::is($foo, 1, 'Test6 - $foo from attribute while BUILD for $foo'); # $foo should not be set per default BUILD for $foo
#        $foo = $newfoo;
#    }
#}

::is 'Test1'->new(                  )->get_foo(), 1 => 'Test2 - $foo still from attribute';
::is 'Test2'->new(foo => 2          )->get_foo(), 2 => 'Test2 - $foo from parameter';
::is 'Test3'->new(          bar => 9)->get_foo(), 1 => 'Test3 - $foo still from attribute';
::is 'Test4'->new(foo => 2, bar => 9)->get_foo(), 2 => 'Test4 - $foo from parameter';

done_testing();


