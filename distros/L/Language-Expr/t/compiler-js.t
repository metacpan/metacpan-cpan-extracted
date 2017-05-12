#!perl

use strict;
use warnings 'FATAL';

use Test::More;
use Test::Exception;
use Language::Expr;
use Language::Expr::JS qw(eval_expr_js);
use Nodejs::Util qw(nodejs_available);
use POSIX;
use lib "./t";
require "stdtests.pl";

# 0.5.10 is the first version that groks --harmony_scoping
my $res = nodejs_available(min_version => "0.5.10");
diag "node.js detection result: ", explain $res;
plan skip_all => $res->[1] unless $res->[0] == 200;

my $jsc = Language::Expr->new->get_compiler('js');
# add this to code "let a=1; let b=2; let ary1=['one','two','three']; let hash1={one:1, two:2, three:3};";
$jsc->func_mapping->{floor} = 'Math.floor';
$jsc->func_mapping->{ceil}  = 'Math.ceil';
$jsc->func_mapping->{uc}  = '.toUpperCase';
$jsc->func_mapping->{length}  = ':length';

package main;

my $opts = {
    js_compiler => $jsc,
    vars => {
        a => 1,
        b => 2,
        ary1 => [qw/one two three/],
        hash1 => {one=>1, two=>2, three=>3},
    },
};

for my $t (stdtests()) {
    next if $t->{category} eq 'comparison equal str'; # true & false
    next if $t->{category} eq 'comparison equal num'; # true & false
    next if $t->{category} eq 'comparison equal chained'; # true & false
    next if $t->{category} eq 'comparison less_greater'; # true & false
    next if $t->{category} eq 'comparison less_greater chained'; # true & false
    next if $t->{category} eq 'or_xor'; # true & false
    next if $t->{category} eq 'true'; # true & false
    next if $t->{category} eq 'unary'; # true & false

    my $tname = "category=$t->{category} $t->{text}";
    if ($t->{parse_error}) {
        $tname .= ", parse error: $t->{parse_error})";
        throws_ok { eval_expr_js($t->{text}, $opts) } $t->{parse_error}, $tname;
    } elsif ($t->{run_error}) {
        $tname .= ", run error: $t->{run_error})";
        throws_ok { eval_expr_js($t->{text}, $opts) } $t->{run_error}, $tname;
    } elsif ($t->{js_compiler_run_error}) {
        $tname .= ", run error: $t->{js_compiler_run_error})";
        throws_ok { eval_expr_js($t->{text}, $opts) } $t->{js_compiler_run_error}, $tname;
    } else {
        $tname .= ")";
        is_deeply( eval_expr_js($t->{text}, $opts), $t->{js_result} // $t->{result}, $tname );
    }
}

DONE_TESTING:
done_testing;
