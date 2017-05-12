#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}
use MarpaX::Languages::C::AST::Expected;

my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my $valuep = $cAst->parse(\$cSourceCode)->value();
ok(defined($valuep), 'Output from parse()->value() is ok');

__DATA__
struct s pi = { .z = "Pi", .x = 3, .y = 3.1415 };
int a[MAX] = { 1, 3, 5, 7, 9, [MAX-5] = 8, 6, 4, 2, 0 };
union u value = { 3 };
union u value = { .y = 3.1415 };
int x[] = { 0, 1, 2 } ;
struct { int a[3], b; } w[] = { [0].a = {1}, [1].a[0] = 2 };
struct { int a[3], b; } w[] =
{
   { { 1, 0, 0 }, 0 },
   { { 2, 0, 0 }, 0 }
};
