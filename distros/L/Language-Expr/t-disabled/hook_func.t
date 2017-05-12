#!perl

use strict;
use warnings;

use Test::More;

use Language::Expr::Compiler::Perl;
use Language::Expr::Compiler::PHP;
use Language::Expr::Compiler::JS;

my $plc = new Language::Expr::Compiler::Perl;
$plc->hook_func(sub { if ($_[0] eq 'orig') { return } else { "($_[1]*$_[1] + $_[2]*$_[2])" } });
is( $plc->perl('pyth($a, 2)'), q[($a*$a + 2*2)], "hook_func in perl" );
is( $plc->perl('orig($a, 2)'), q[orig($a, 2)], "hook_func in perl returns undef" );

my $phpc = new Language::Expr::Compiler::PHP;
$phpc->hook_func(sub { if ($_[0] eq 'orig') { return } else { "($_[1]*$_[1] + $_[2]*$_[2] /* $_[0] */)" } });
is( $phpc->php('pyth($a, 2)'), q[($a*$a + 2*2 /* pyth */)], "hook_func in php" );
is( $phpc->php('orig($a, 2)'), q[orig($a, 2)], "hook_func in php returns undef" );

my $jsc = new Language::Expr::Compiler::JS;
$jsc->hook_func(sub { if ($_[0] eq 'orig') { return } else { "($_[1]*$_[1] + $_[2]*$_[2])" } });
is( $jsc->js('pyth($a, 2)'), q[(a*a + 2*2)], "hook_func in js" );
is( $jsc->js('orig($a, 2)'), q[orig(a, 2)], "hook_func in js returns undef" );

DONE_TESTING:
done_testing;
