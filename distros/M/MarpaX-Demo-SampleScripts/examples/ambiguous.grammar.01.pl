#!/usr/bin/env perl

# Copyright 2014 Ruslan Shvedov

# Problem 3.10 from Parsing Techniques: A Practical Guide by Grune and Jacobs 2008 (G&J)
# adapted to Marpa::R2 SLIF

use 5.010;
use strict;
use warnings;

use Test::More;

use Marpa::R2;

use YAML;

use MarpaX::ASF::PFG;

# ------------------------------------------------
# Unambiguous grammar to parse expressions on numbers
#
my $ug = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

:default ::= action => [ name, value]
lexeme default = action => [ name, value] latm => 1

    Expr ::=
          Number
       || '(' Expr ')'      assoc => group
       || Expr '**' Expr    assoc => right
       || Expr '*' Expr     # left associativity is by default
        | Expr '/' Expr
       || Expr '+' Expr
        | Expr '-' Expr

    Number ~ [\d]+

:discard ~ whitespace
whitespace ~ [\s]+

END_OF_SOURCE
} );

#
# Ambiguous grammar
#
my $ag = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

:default ::= action => [ name, value]
lexeme default = action => [ name, value] latm => 1

    Expr ::=
         Number
       | '(' Expr ')'
       | Expr '**' Expr
       | Expr '*' Expr
       | Expr '/' Expr
       | Expr '+' Expr
       | Expr '-' Expr

    Number ~ [\d]+

:discard ~ whitespace
whitespace ~ [\s]+

END_OF_SOURCE
} );

my @input = qw{
3+5+1**10
6/6/6
6**6**6
3+5+1
6/6/6
6**6**6
42*2+7/3
42*2+7/3-1**5
2**7-3*10
4+5*6+8
2-1+5
2/1*5
};

# parse input with unambiguous and ambiguous grammars
# the results must be the same
for my $input (@input){

    # unambiguous grammar
    my $expected_ast = ${ $ug->parse( \$input ) };
#    say "# expected ast ", Dump $expected_ast;

    # parse with Ambiguous G & R
    my $ar = Marpa::R2::Scanless::R->new( { grammar => $ag } );
    $ar->read(\$input);

    # parse forest grammar (PFG) from abstract syntax forest (ASF)
    my $pfg = MarpaX::ASF::PFG->new( Marpa::R2::ASF->new( { slr => $ar } ) );

    say "# Before pruning:\n", $pfg->show_rules;

    # todo: make this a test
    # this must show nothing because ambiguity can't be traced to literals
    # associativity-only ambiguity
    # it's the grammar which is ambiguous rather than input
    # no token and rule literal is parsed differently
    $pfg->ambiguous;

    # prune PFG to get the right AST

    $pfg->prune(
        sub { # return 1 if the rule needs to be pruned, 0 otherwise
            my ($rule_id, $lhs, $rhs) = @_;

            my @rule = ($pfg, $rule_id, $lhs, $rhs);
            return (
                   assoc_left  ( @rule, qw{ + - }                    )
                or assoc_left  ( @rule, qw{ * / }                    )
                or assoc_right ( @rule, qw{ **  }                    )
                or prec        ( @rule, [qw{ * / }], [qw{ + -     }] )
                or prec        ( @rule, [qw{ **  }], [qw{ * / + - }] )
            );
        }
    );
#    say "# After pruning:\n", $pfg->show_rules;

    # AST from pruned PFG
    my $ast = $pfg->ast;
#    use YAML; say Dump $ast;

    is_deeply $ast, $expected_ast, $input;
}

done_testing();

#
# prining criterion for arithmetic expressions
#

# check rule $rule_id with $lhs, $rhs in $pfg for
# left associativity of @ops, e.g. a+b+c = ((a+b)+c) != (a+(b+c))
# for each node that has an operator in @ops, its right operand
# cannot be a non-terminal that has a node with that operator.
# return 1 if rule $rule_id breaks left associativity, 0 otherwise
sub assoc_left{
    my ($pfg, $rule_id, $lhs, $rhs, @ops) = @_;
    for my $op (@ops){
        if ( $pfg->has_symbol_at ( $rule_id, $op, 1 ) ){
            for my $op_right (@ops){
                if ( right_operand_has_op( $pfg, $rule_id, $rhs, $op_right ) ){
                    return 1;
                }
            }
        }
    }
    return 0;
}

# check rule $rule_id with $lhs, $rhs in $pfg for
# right associativity of @ops, e.g. 6**6**6 = (6**(6**6)) != ((6**6)**6)
# for each rule that has an operator in @ops, its left operand
# cannot be a non-terminal that has a node with the same operator.
# return 1 if rule $rule_id breaks right associativity, 0 otherwise
sub assoc_right{
    my ($pfg, $rule_id, $lhs, $rhs, @ops) = @_;
    for my $op (@ops){
        if ( $pfg->has_symbol_at ( $rule_id, $op, 1 ) ){
            for my $op_left (@ops){
                if ( left_operand_has_op( $pfg, $rule_id, $rhs, $op_left ) ){
                    return 1;
                }
            }
        }
    }
    return 0;
}

# check rule $rule_id with $lhs, $rhs in $pfg for
# precedence of @$ops_higher over @$ops_lower, e.g. a**b+c = ((a**b)+c) != (a**(b+c))
# for each node that has $op_higher, its right and left operands
# cannot be a non-terminal that have a node with $op_lower.
# return 1 if rule $rule_id breaks precedence, 0 otherwise
sub prec{
    my ($pfg, $rule_id, $lhs, $rhs, $ops_higher, $ops_lower) = @_;
    for my $op_higher (@$ops_higher){
        if ( $pfg->has_symbol_at ( $rule_id, $op_higher, 1 ) ){
            for my $op_lower (@$ops_lower){
                if (   left_operand_has_op( $pfg, $rule_id, $rhs, $op_lower )
                    or right_operand_has_op( $pfg, $rule_id, $rhs, $op_lower )
                    ){
                    return 1;
                }
            }
        }
    }
    return 0;
}

sub operand_has_op{
    my ($pfg, $rule_id, $rhs, $operand_id, $op) = @_;
    return (
            not $pfg->is_terminal( $rhs->[$operand_id] )
        and $pfg->has_symbol_at ( $pfg->rule_id( $rhs->[$operand_id] ), $op, 1 )
    )
}

sub right_operand_has_op{
    my ($pfg, $rule_id, $rhs, $op) = @_;
    return operand_has_op( $pfg, $rule_id, $rhs, 2, $op );
}

sub left_operand_has_op{
    my ($pfg, $rule_id, $rhs, $op) = @_;
    return operand_has_op( $pfg, $rule_id, $rhs, 0, $op );
}
