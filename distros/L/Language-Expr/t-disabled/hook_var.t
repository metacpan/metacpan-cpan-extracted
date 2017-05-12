#!perl

use strict;
use warnings;

use Test::More;

use Language::Expr::Compiler::Perl;
use Language::Expr::Compiler::PHP;
use Language::Expr::Compiler::JS;

my $plc = new Language::Expr::Compiler::Perl;
$plc->hook_var(sub { if ($_[0] eq 'x') { return } else { "get_var('$_[0]')" } });
is( $plc->perl('$a+1'), q[get_var('a') + 1], "hook_var in perl" );
is( $plc->perl('$x+1'), q[$x + 1], "hook_var in perl returns undef" );

my $phpc = new Language::Expr::Compiler::PHP;
$phpc->hook_var(sub { if ($_[0] eq 'x') { return } else { "get_var('$_[0]')" } });
is( $phpc->php('$a+1'), q[get_var('a') + 1], "hook_var in php" );
is( $phpc->php('$x+1'), q[$x + 1], "hook_var in php returns undef" );

my $jsc = new Language::Expr::Compiler::JS;
$jsc->hook_var(sub { if ($_[0] eq 'x') { return } else { "get_var('$_[0]')" } });
is( $jsc->js('$a+1'), q[get_var('a') + 1], "hook_var in js" );
is( $jsc->js('$x+1'), q[x + 1], "hook_var in js returns undef" );

DONE_TESTING:
done_testing;
