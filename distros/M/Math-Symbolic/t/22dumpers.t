#!perl
use strict;
use warnings;
use Carp qw/croak/;
use Test::More tests => 1+4*7;
BEGIN {
    use_ok('Math::Symbolic');
}
use Math::Symbolic qw/:all/;
use Math::Symbolic::Derivative qw/partial_derivative/;

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}


my @f = (
        q{-a+b*x},
        q{a+b*x+c*x^2},
        q{b+2*c*x},
        q{a+x+}.join('+', map {"x^$_"} 2..10),
        '1+'.join('+', map {"$_*x^".($_-1)} 2..10),
        q{sin(2*x)*cos(3*x)},
        q{2*cos(2*x)*cos(3*x)-3*sin(3*x)*sin(2*x)},
);

foreach (@f) {
    my $f = parse_from_string($_);
    my ($code) = $f->to_code();
    ok(defined $code);
    my ($sub) = $f->to_sub();
    ok(defined $sub);
    ok(ref($sub) eq 'CODE');

    ok($f->test_num_equiv($sub), "to_sub works");
}

