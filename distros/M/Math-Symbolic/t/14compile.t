#!perl
use strict;
use warnings;

use Test::More tests => 21;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $x   = $var->new( 'x' => 10 );
my $y   = $var->new( 'y' => 5 );
my $z   = $var->new( 'z' => 1 );

my ( $sub, $code, $trees );

my $func = $z + $x * 2 + $y;

eval <<'HERE';
($sub, $trees) = Math::Symbolic::Compiler->compile_to_sub($func);
HERE
ok( !$@, 'compile_to_sub(), one argument.' );
is_deeply( $trees, [], '- checking results.' );
ok( $sub->( 11, 2, 100 ) == 124, '- checking results.' );

( $sub, $trees ) = ( undef, undef );

eval <<'HERE';
($sub, $trees) = Math::Symbolic::Compiler->compile_to_sub(
			$func,
			[qw/y/]
		);
HERE
ok( !$@, 'compile_to_sub(), two arguments.' );
is_deeply( $trees, [], '- checking results.' );
ok( $sub->( 11, 2, 100 ) == ( 11 + 2 * 2 + 100 ), '- checking results.' );

( $sub, $trees ) = ( undef, undef );

eval <<'HERE';
($sub, $trees) = Math::Symbolic::Compiler->compile_to_sub(
			$func,
			[qw/z y x/]
		);
HERE
ok( !$@, 'compile_to_sub(), two arguments.' );
is_deeply( $trees, [], '- checking results.' );
ok( $sub->( 11, 2, 100 ) == ( 11 + 2 + 2 * 100 ), '- checking results.' );

( $sub, $trees ) = ( undef, undef );

eval <<'HERE';
($code, $trees) = Math::Symbolic::Compiler->compile_to_code($func);
HERE
ok( !$@, 'compile_to_code() - one argument.' );
is_deeply( $trees, [], '- checking results.' );
{
    local @_ = ( 2, 100, 3 );
    my $res = eval $code;
    ok( $res == ( 3 + 100 + 2 * 2 ), '- checking results.' );
}

( $code, $trees ) = ( undef, undef );

eval <<'HERE';
($code, $trees) = Math::Symbolic::Compiler->compile_to_code(
			$func,
			[qw/z y x/]
			);
HERE
ok( !$@, 'compile_to_code() - two arguments.' );
is_deeply( $trees, [], '- checking results.' );
{
    local @_ = ( 2, 100, 3 );
    my $res = eval $code;
    ok( $res == ( 2 * 3 + 100 + 2 ), '- checking results.' );
}

( $code, $trees ) = ( undef, undef );

eval <<'HERE';
($code, $trees) = Math::Symbolic::Compiler->compile_to_code(
			$func,
			[qw/y/]
			);
HERE
ok( !$@, 'compile_to_code() - two arguments.' );
is_deeply( $trees, [], '- checking results.' );
{
    local @_ = ( 2, 100, 3 );
    my $res = eval $code;
    ok( $res == ( 3 + 2 * 100 + 2 ), '- checking results.' );
}

( $code, $trees ) = ( undef, undef );

$@ = undef;
eval <<'HERE';
($sub, $code, $trees) =
Math::Symbolic::Compiler->compile($func, [qw/x/]);
HERE
ok( !$@, 'compile()' );

my $no = $sub->( 1, 2, 3 );
ok( $no == ( 2 + 2 + 3 ), 'Correct result of sub', );

