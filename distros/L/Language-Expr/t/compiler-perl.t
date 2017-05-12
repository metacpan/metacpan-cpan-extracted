#!perl

use strict;
use warnings 'FATAL';

use Test::More;
use Test::Exception;
use Language::Expr;
use POSIX;
use lib "./t";
require "stdtests.pl";

my $plc = Language::Expr->new->get_compiler('perl');
{
    no warnings;
    $Language::Expr::Compiler::perl::a = 1;
    $Language::Expr::Compiler::perl::b = 2;
    $Language::Expr::Compiler::perl::ary1 = ["one", "two", "three"];
    $Language::Expr::Compiler::perl::hash1 = {one=>1, two=>2, three=>3};
}

package Language::Expr::Compiler::perl;
sub floor { POSIX::floor(shift) }
sub ceil { POSIX::ceil(shift) }
# uc
# length

package main;

for my $t (stdtests()) {
    my $tname = "category=$t->{category} $t->{text}";
    if ($t->{parse_error}) {
        $tname .= ", parse error: $t->{parse_error})";
        throws_ok { $plc->compile($t->{text}) } $t->{parse_error}, $tname;
    } elsif ($t->{run_error}) {
        $tname .= ", run error: $t->{run_error})";
        throws_ok { $plc->eval($t->{text}) } $t->{run_error}, $tname;
    } elsif ($t->{compiler_run_error}) {
        $tname .= ", run error: $t->{compiler_run_error})";
        throws_ok { $plc->eval($t->{text}) } $t->{compiler_run_error}, $tname;
    } else {
        $tname .= ")";
        is_deeply( $plc->eval($t->{text}), $t->{result}, $tname );
    }
}

DONE_TESTING:
done_testing;
