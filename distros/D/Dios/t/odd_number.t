package Foo;

use strict;
use Test::More 'no_plan';

use Dios;

method foo(:$name, :$value) {
    return $name, $value;
}

ok !eval{ Foo->foo(name => 42, value =>); } => 'Missing named argument value';
like $@, qr{No argument found for named parameter \:\$value}  =>  'Correct exception';
