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
int (*operation)(int x, int y);

int add(int x, int y)
{
    return x + y;
}

int subtract(int x, int y)
{
    return x - y;
}

int main(int argc, char* args[])
{
   int  foo = 1, bar = 1;

   operation = add;
   printf("%d + %d = %d\n", foo, bar, operation(foo, bar));
   operation = subtract;
   printf("%d - %d = %d\n", foo, bar, operation(foo, bar));
   return 0;
}
