use Test::More tests => 8;
BEGIN { use_ok('Lang::Tree::Builder') }

my $builder = Lang::Tree::Builder->new( dir => 'test/perl', prefix => 'Foo::' );
ok($builder);
$builder->build('t/data2');

unshift @INC, './test/perl';
eval "use Foo::API qw(:all)";
die $@ if $@;

my $exprlist = ExprList(
    Plus( Number(2), Times( Number(3), Number(4) ) ),
    ExprList( Number(5), EmptyExprList() )
);

ok( $exprlist, 'generated Perl ok' );
isa_ok( $exprlist,            'Foo::ExprList' );
isa_ok( $exprlist->getExpr(), 'Foo::Plus' );
is( $exprlist->getExpr->getLeft->getValue(), 2, 'generated perl deeply ok' );

$builder =
  Lang::Tree::Builder->new( dir => 'test/php', prefix => 'Bar::', lang => 'PHP' );
ok($builder);
$builder->build('t/data2');

$builder =
  Lang::Tree::Builder->new( dir => 'test/cpp', prefix => 'Baz::', lang => 'C++' );
ok($builder);
$builder->build('t/data2');
