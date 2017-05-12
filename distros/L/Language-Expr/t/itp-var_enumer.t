#!perl

use strict;
use warnings;

use Language::Expr;
use POSIX;
use Test::Exception;
use Test::More;

my @data = (
    {category=>'none', text=>'[]', result=>[]},
    {category=>'none', text=>'1+2+3', result=>[]},

    {category=>'basic', text=>'$b', result=>['b']},
    {category=>'basic', text=>q[${a b}], result=>['a b']},
    {category=>'basic', text=>'$a+2*$b', result=>['a', 'b']},

    {category=>'repeat', text=>'$b+$b*$b', result=>['b']},

    {category=>'quotestr', text=>q("${a b} $c" . '$d'), result=>['a b', 'c']},

    {category=>'func', text=>'length($a)', result=>['a']},

    {category=>'subscript', text=>'$a::b[$b]+([1, 2, $b::c])[$a]', result=>['a::b', 'b', 'b::c', 'a']},

);

my $ve = Language::Expr->new->get_interpreter('var_enumer');

for (@data) {
    is_deeply($ve->eval($_->{text}), $_->{result}, "$_->{category} ($_->{text})");
}

DONE_TESTING:
done_testing;
