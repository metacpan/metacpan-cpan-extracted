#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my $x = MarpaX::Languages::ECMAScript::AST->new->parse(<< 'EoC');
function meh () {};
EoC

ok(defined($x), 'Code that throws a "More than one parse tree value". (github issue #4)');
done_testing(2);
