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
struct f
{
    unsigned int  flag : 1;  /* a bit flag: can either be on (1) or off (0) */
    signed int    num  : 4;  /* a signed 4-bit field; range -7...7 or -8...7 */
    signed int         : 3;  /* 3 bits of padding to round out to 8 bits */
} g;
