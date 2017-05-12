#!perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $tree;
my $str;
undef $@;
eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('sinh(2)');
HERE
$str = $tree->to_string();
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'sinh(2)' ), "Parsing hyperbolic sine" );

undef $@;
eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('cosh(2)');
HERE
$str = $tree->to_string();
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'cosh(2)' ), 'Parsing hyperbolic cosine' );

undef $@;
eval <<'HERE';
$tree = Math::Symbolic->parse_from_string(
		'tan(log(cosh(2),sin(2*1*3+1*3)*sinh(0)))'
	);
HERE
$str = $tree->to_string();
$str =~ s/\s+//g;
ok(
    ( !$@ and $str eq 'tan(log(cosh(2),(sin(((2*1)*3)+(1*3)))*(sinh(0))))' ),
    'Parsing more complicated string involving sinh/cosh/tan.'
);

