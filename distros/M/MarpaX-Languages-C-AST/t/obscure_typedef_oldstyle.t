#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}
my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my $valuep = $cAst->parse(\$cSourceCode)->value();
ok(defined($valuep), 'Output from parse()->value() is ok');

__DATA__
/* Note: Compilers will usually rejects this because of ANSI C recommendation */
/* saying this SHALL not be accepted. Though this is legal from pure grammar */
/* point of view */
typedef char *d;
void func(d)
  long d;
{
  d = 0;
}
