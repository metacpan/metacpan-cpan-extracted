#!/usr/bin/env perl

# Copyright 2014 Ruslan Shvedov

# Example from Parsing Techniques: A Practical Guide by Grune and Jacobs 2008 (G&J)
# 3.7.4 Parse-Forest Grammars

use 5.010;
use strict;
use warnings;

use Test::More;

use Marpa::R2;

# ------------------------------------------------

use_ok 'MarpaX::ASF::PFG';

# Unambiguous grammar to parse sum of digits
my $ug = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

:default ::= action => [ name, value]
lexeme default = action => [ name, value] latm => 1

    Sum ::=
           Digit        # digits have higher precedence
        || Sum '+' Sum  # left-associative by default
    Digit ~ '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'

END_OF_SOURCE
} );

# Ambiguous grammar (G&J Fig. 3.1.)
my $ag = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

:default ::= action => [ name, value]
lexeme default = action => [ name, value] latm => 1

    Sum ::= Sum '+' Sum
    Sum ::= Digit
    Digit ~ '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'

END_OF_SOURCE
} );

# parse input with unambiguous grammar then
# with ambiguous grammars and pruning via PFG
# the results must be the same
my $input = q{3+5+1};

# unambiguous grammar: parse() will yell on ambiguities
my $expected_ast = ${ $ug->parse( \$input ) };

# ambiguous grammar
my $ar = Marpa::R2::Scanless::R->new( { grammar => $ag } );
$ar->read(\$input);

# abstract syntax forest (ASF)
my $asf = Marpa::R2::ASF->new( { slr => $ar } );
die 'No ASF' if not defined $asf;

# parse-forest grammar (PFG) from ASF
my $pfg = MarpaX::ASF::PFG->new($asf);
isa_ok $pfg, 'MarpaX::ASF::PFG', 'pfg';

say "# before pruning:\n", $pfg->show_rules;

# prune PFG to get the right AST
# G&J 3.7.3.2 Retrieving Parse Trees from a Parse Forest:
# + operator is left-associative, which means that a+b+c should be parsed as
# ((a+b)+c) rather than as (a+(b+c)).
$pfg->prune(
    sub { # return 1 if the rule needs to be pruned, 0 otherwise
        my ($rule_id, $lhs, $rhs) = @_;
        # The criterion would then be that for each node that has a + operator,
        # its right operand cannot be a non-terminal that has a node with a + operator.
                $pfg->has_symbol_at ( $rule_id, '+', 1 ) # rule has + and its right
        and not $pfg->is_terminal   ( $rhs->[2]     ) # operand is a non-terminal
        and     $pfg->has_symbol_at ( $pfg->rule_id( $rhs->[2] ), '+', 1 ) # and has +
    }
);

#say "# after pruning:\n", $pfg->show_rules;

# AST from pruned PFG
my $ast = $pfg->ast;

# after pruning, ASTs from unambiguous and ambiguous grammars
# must be the same
is_deeply $ast, $expected_ast, "sum of digits";

done_testing();