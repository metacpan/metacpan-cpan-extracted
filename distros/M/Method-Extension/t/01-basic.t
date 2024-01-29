#!perl
use Test::More;

use lib 't/lib';

use Foo;
use Bar;

my $foo = Foo->new;

isa_ok $foo, 'Foo';

can_ok $foo, 'baz';

is $foo->baz, 'Baz from extension method', 'should call baz';

done_testing;
