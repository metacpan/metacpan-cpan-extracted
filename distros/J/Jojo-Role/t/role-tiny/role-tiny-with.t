use strict;
use warnings;
use Test::More;

BEGIN {
  package MyRole;

  use Jojo::Role;

  sub bar { 'role bar' }

  sub baz { 'role baz' }
}

BEGIN {
  package MyClass;

  use Jojo::Role -with;

  with 'MyRole';

  sub foo { 'class foo' }

  sub baz { 'class baz' }

}

is(MyClass->foo, 'class foo', 'method from class no override');
is(MyClass->bar, 'role bar',  'method from role');
is(MyClass->baz, 'class baz', 'method from class');

BEGIN {
  package RoleWithStub;

  use Jojo::Role;

  sub foo { 'role foo' }

  sub bar ($$);
}

{
  package ClassConsumeStub;
  use Jojo::Role -with;

  eval {
    with 'RoleWithStub';
  };
}

is $@, '', 'stub composed without error';
ok exists &ClassConsumeStub::bar && !defined &ClassConsumeStub::bar,
  'stub exists in consuming class';

done_testing;
