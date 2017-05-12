use Test::More tests => 17;
BEGIN { use_ok('Lang::Tree::Builder::Class') }

my $class1 = new Lang::Tree::Builder::Class(class => 'Foo::Expr');
ok ($class1, 'new works');
my $class2 = new Lang::Tree::Builder::Class(
    class => 'Foo::Expr',
    parent => 'Foo',
    args => [[qw(Foo)], [qw(Bar none)]]
);
is($class1, $class2, 'classes are unique');
is($class1->name, 'Foo::Expr', 'name');
is($class1->parent->name, 'Foo', 'parent');
my @args = $class1->args;
is($args[0]->name, 'Foo', 'args class [1]');
is($args[0]->argname, 'Foo', 'args name [1]');
is($args[1]->name, 'Bar', 'args class [2]');
is($args[1]->argname, 'none', 'args name [2]');
is_deeply(scalar($class1->parts), [qw(Foo Expr)], 'parts');
is($class1->lastpart, 'Expr', 'lastpart');
is($class1->namespace, 'Foo', 'namespace');
is($class1->is_scalar, 0, 'is_scalar');
is($class1->is_substantial, 0, 'is_substantial [1]');
$class1->substantiate;
is($class1->is_substantial, 1, 'is_substantial [2]');
is($class1->is_abstract, 0, 'is_abstract');
is($class1->is_concrete, 1, 'is_concrete');
