use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Devel::OverloadInfo;

{
    package Foo;
    # *MUST* be a deref overload standalone, any additional will not do
    use overload (
        "&{}" => sub { sub { 42 } },
        fallback => 1,
    );
}

{
    package SubFoo;
    # Must have subclass inheriting the overload
    use parent -norequire => 'Foo';
}

Devel::OverloadInfo::overload_info('SubFoo');

my $x = bless {}, 'SubFoo';

is exception {
    ok !!$x, "un-overloaded negation works after inspection before first bless";
}, undef, "un-overloaded negation lives after inspection before first bless";

is exception {
    is $x->(), 42, "overloaded dereference works after inspection before first bless";
}, undef, "overloaded dereference lives after inspection before first bless";

done_testing;
