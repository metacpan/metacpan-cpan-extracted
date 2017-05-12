#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my $x = MarpaX::Languages::ECMAScript::AST->new->parse(<< 'EoC');
    1;
    ///////////////////////////////////////////////////////////////////////////
EoC

ok(defined($x), 'Code that throws a "lexer Earley item count exceeds warning threshold". (github issue #3)');
done_testing(2);
