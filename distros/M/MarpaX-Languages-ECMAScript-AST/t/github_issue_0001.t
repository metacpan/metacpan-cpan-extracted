#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my $x = MarpaX::Languages::ECMAScript::AST->new->parse(<< 'EoC');
    x = 42;
    /* Allo */
    bluh = function() {
        // Lorem ipsum dolor sit amet, consectetur adipisicing elit, 
        // sed do eiusmod tempor incididunt ut labore et dolore
        // magna aliqua. Ut enim ad minim veniam, quis nostrud
        // exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
};
EoC

ok(defined($x), 'Code that throws a "subexpression recursion limit exception". (github issue #1)');
done_testing(2);
