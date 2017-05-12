use Test::More tests => 11;
BEGIN { use_ok('Lang::Tree::Builder::Args') }
my $args = Lang::Tree::Builder::Args->List([ [qw(Expr one)] ]);
is(ref($args), 'ARRAY', 'List() returns an array ref');
isa_ok($args->[0], 'Lang::Tree::Builder::Args');
is($args->[0]->name(), 'Expr');
is($args->[0]->argname(), 'one');
$args = Lang::Tree::Builder::Args->List([
    [qw(Foo::Expr)],
    [qw(Foo::Expr)],
    [qw(Foo::Expr foo)],
    [qw(Foo::Expr foo)],
    [qw(Foo::Expr bar)],
    [qw(Foo::ExprList)]
]);
is($args->[0]->argname(), 'Expr1');
is($args->[1]->argname(), 'Expr2');
is($args->[2]->argname(), 'foo1');
is($args->[3]->argname(), 'foo2');
is($args->[4]->argname(), 'bar');
is($args->[5]->argname(), 'ExprList');
