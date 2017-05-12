#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use Test::Trap
;
BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}
use MarpaX::Languages::C::AST::Expected;

my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my @r = trap {$cAst->parse(\$cSourceCode)->value()};
#
# The error string will come from Marpa, typically: Error in SLIF G1 read: No lexemes accepted at position 34
#
like($trap->die || '', qr/.*/, $cSourceCode);
__DATA__
void func() { e = a < d ? a++ : a = d; }

