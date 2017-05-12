#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;

use Marpa::R2;

# Author: rns (Ruslan Shvedov).

# -----------------------------------------------

# http://velocity.apache.org/engine/releases/velocity-1.4/specification-bnf.html
# https://velocity.apache.org/engine/releases/velocity-1.5/user-guide.html

# -----------------------------------------------

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

my $g = Marpa::R2::Scanless::G->new( {
    source => \(<<'END_OF_SOURCE'),
:default ::= action => [ name, value]
lexeme default = action => [ name, value] latm => 1

# Start rule is missing in the original grammar.
# It's optional in recent Marpas.

velocity ::= statements

<statements> ::= <statement>+

<statement>

    ::=   <text>
        | <block>
        | <if statement>
        | <else if statement>
        | <foreach statement>
        | <include statement>
        | <set statement>
        | <parse statement>
        | <param statement>
        | <stop statement>
        | <reference>
        # added to the original grammar
        | <free text>

<block>

    ::= '#begin' <expressions> '#end'

<expressions> ::= <expression>+

<if statement>

    ::= '#if' '(' <expression> ')' <statement> <else statement> '#end'
      | '#if' '(' <expression> ')' <statement> '#end'


<else if statement>

    ::= '#elseif' '(' <expression> ')' <statement> <else statement>
      | '#elseif' '(' <expression> ')' <statement>

<foreach statement>

    ::= '#foreach' '(' <reference> 'in' <reference> ')' <statements> '#end'

<include statement>

    ::= '#include' <string literal>

<set statement>

    ::= '#set' '(' <reference> '=' <expression> ')'

<parse statement>

    ::= '#parse' <string literal>

<param statement>

    ::= '#param' <reference> '=' <string literal>

<stop statement>

    ::= '#stop'

<reference>

    ::= '$' <identifier> <methods or identifiers>

    <methods or identifiers> ::= <method or identifier>*
    <method or identifier> ::= '.' <method> | <identifier>

<method>

    ::= <identifier> '(' <parameters> ')'

    <parameters> ::= <parameter>* separator => [,]

<parameter>

    ::= <reference> | <string literal>

<alpha char>

    ~ [a-zA-Z]

<identifier>

    ~ <alpha char> <identifier chars>

    <identifier chars> ~ [a-zA-Z0-9\-_]+

<expression>

    ::=   <true>
        | <false>
        | <primary expression> '=' <primary expression>
        | <conditional or expression>
        # these alternatives were added to the original grammar
        | <array expression>
        | <reference>

# array expression is missing from the grammar; added based on the description text
<array expression> ::= '[' <array items> ']'
<array items> ::= <string literal>+ separator => [,]

# hash needs also be added


<conditional or expression>

    ::= <conditional and expression>+ separator => or
    or ~ '||'

<conditional and expression>

    ::= <equality expression>+ separator => and
    and ~ '&&'

<equality expression>

    ::= <relational expression> <relational expression items>

    <relational expression items> ::= <relational expression item>+
    <relational expression item> ::= '==' <relational expression>
                                   | '!=' <relational expression>

<relational expression>

    ::= <additive expression> <additive expression items>

    <additive expression items> ::= <additive expression item>
    <additive expression item> ::= '<'  <additive expression>
                                 | '>'  <additive expression>
                                 | '<=' <additive expression>
                                 | '>=' <additive expression>

<additive expression>

    ::= <multiplicative expression> <multiplicative expression items>

    <multiplicative expression items> ::= <multiplicative expression item>+

    <multiplicative expression item> ::= '+' <multiplicative expression>
                                       | '-' <multiplicative expression>

<multiplicative expression>

    ::= <unary expression> <unary expression items>

    <unary expression items> ::= <unary expression item>+
    <unary expression item> ::= '*' <unary expression>
                              | '/' <unary expression>
                              | '%' <unary expression>

<unary expression>

    ::= '!' <unary expression> | <primary expression>

<primary expression>

    ::=   <string literal>
        | <number literal>
        | <reference>
        | '(' <expression> ')'


# the below rules are added because the original grammar
# seems to be incomplete
# todo: convert those tentative rules to some more real
<string literal> ~ '"' <alpha chars> '"'
<alpha chars> ~ [\w ]+
<true> ~ 'true'
<false> ~ 'false'
<text> ::= <string literal>
<number literal> ~ [\d]+
<else statement>
    ::= '#else' <statement>
<free text> ~ <alpha chars>

:discard ~ whitespace
whitespace ~ [\s]+

END_OF_SOURCE
} );

my $input = q{
#set( $criteria = ["name", "address"] )

#foreach( $criterion in $criteria )

    #set( $result = $query.criteria($criterion) )

    #if( $result )
        Query was successful
    #end

#end
};

my $r = Marpa::R2::Scanless::R->new( {
    grammar => $g,
#    trace_terminals => 1
} );
eval {$r->read(\$input)} || warn "Parse failure, progress report is:\n" . $r->show_progress;

my $ast = $r->value;

unless (defined $ast){
    die "No parse";
}

if ( $r->ambiguity_metric() > 1 ){
    # gather parses
    my @asts;
    my $v = $ast;
    do {
        push @asts, ${ $v };
    } until ( $v = $r->value() );
    push @asts, ${ $v };
    say "Ambiguous parse: ", $#asts + 1, " alternatives.";
    for my $i (0..$#asts){
        say "# Alternative ", $i+1, ":\n", Dumper $asts[$i];
    }
}
else{
    say Dumper $ast;
}
