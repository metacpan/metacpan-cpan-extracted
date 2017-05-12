use Test::More tests => 4;

package Foo;
use Gloom -base;

has 'this';

package Foo::Bar;
use Foo -base;

has 'that';

package main;

my $f = Foo->new(this => 'rocks');
my $fb = Foo::Bar->new(this => 'rules', that => 'thing');

ok $f->can('this'), 'Foo can this';
ok not($f->can('that')), "Foo can't that";
ok $fb->can('this'), 'Foo::Bar can this';
ok $fb->can('that'), 'Foo::Bar can that';
