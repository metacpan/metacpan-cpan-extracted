#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

use Marpa::R2;

# Author: rns (Ruslan Shvedov).

# ------------------------------------------------

my $g = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

:default ::= action => [ name, values ]
lexeme default = action => [ name, value ] latm => 1

    seq ::= item+

    item ::= (non_parens)
    item ::= in_parens

    in_parens ::= ('(') non_parens (')' non_parens close)
    in_parens ::= ('(') non_parens (')')

    non_parens ~ [^\(\)]+
    close ~ [\)]+

:discard ~ whitespace
whitespace ~ [\s]+

END_OF_SOURCE
} );

my $input = <<EOI;
dummy
(key1)
(key2)dummy(key3)
dummy(key4)dummy
dummy(key5)dummy))))dummy
dummy(key6)dummy))(key7)dummy))))
EOI

my $ast = ${ $g->parse( \$input ) };

my @key;
ast_traverse($ast);
say "Strings from parens: \n", join "\n", @key;

sub ast_traverse{
    my $ast = shift;
    if (ref $ast){
        my ($id, @children) = @$ast;
        if ($id eq 'non_parens'){
            push @key, @children;
        }
        else {
            ast_traverse($_) for @children;
        }
    }
}
