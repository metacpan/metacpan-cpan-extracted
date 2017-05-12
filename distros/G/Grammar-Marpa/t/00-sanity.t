#!perl -T

use 5.018;
use Test::More ( tests => 1 );

use Grammar::Marpa;

my $dsl = <<'END_OF_DSL';
:default ::= action => ::first
:start ::= Expression
Expression ::= Term
Term ::= Factor
       | Term '+' Term action => do_add
Factor ::= Number
         | Factor '*' Factor action => do_multiply
Number ~ digits
digits ~ [\d]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $g = Grammar::Marpa($dsl, 'M');

'1 + 2 * 3' =~ $g;

is($^R, 7, "all sane");

sub M::do_add {
    my (undef, $t1, undef, $t2) = @_;
    return $t1 + $t2;
}

sub M::do_multiply {
    my (undef, $t1, undef, $t2) = @_;
    return $t1 * $t2;
}

1;
