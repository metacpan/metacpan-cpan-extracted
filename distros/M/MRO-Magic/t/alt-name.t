use strict;
use warnings;
use Test::More 'no_plan';

# *all* this is meant to do is test a class that says:
# use metamethod sub { ... }

use lib 't/lib';
require ClassMMN;

my $parent_class = ClassMMN->new({
  name             => 'ParentClass',
  class_methods    => { ping  => sub { 'pong' }, pong => sub { 'ping' } },
  instance_methods => { plugh => sub { 'fool' }, y2   => sub { 'y2'   } },
});

my $child_class = $parent_class->new_subclass({
  name             => 'ChildClass',
  class_methods    => { ping  => sub { 'reply' }, foo => sub { 'bar' } },
  instance_methods => { plugh => sub { 'xyzzy' }, foo => sub { 'fee' } },
});

is(ref $parent_class, 'ClassMMN', 'check ref of ParentClass');
is(ref $child_class,  'ClassMMN', 'check ref of ChildClass');

is($parent_class->name, 'ParentClass', 'name of ParentClass');
is($child_class->name,  'ChildClass',  'name of ChildClass');

is($parent_class->ping, 'pong',  'ping ParentClass');
is($child_class->ping,  'reply', 'ping ChildClass');

is($parent_class->pong, 'ping', 'pong ParentClass');
is($child_class->pong,  'ping', 'pong ChildClass');

eval { $parent_class->foo };
like($@, qr/no class method/, 'no "foo" on ParentClass');
is($child_class->foo, 'bar', 'foo on ChildClass');
