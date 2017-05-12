#!perl
use strict;
use warnings;
use Carp qw/croak/;
use Test::More tests => 12;
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
    [
        q{-a+b*x},
        q{b}
    ],
    [
        q{a+b*x+c*x^2},
        q{b+2*c*x}
    ],
    [
        q{a+x+}.join('+', map {"x^$_"} 2..10),
        '1+'.join('+', map {"$_*x^".($_-1)} 2..10)
    ],
    [
        q{sin(2*x)*cos(3*x)},
        q{2*cos(2*x)*cos(3*x)-3*sin(3*x)*sin(2*x)},
    ],
    [
        q{log(a, 2*x)},
        q{2/(log(2.71828182845905, a)*2*x)},
        { x => sub {$_[0] > 0}, a => sub {$_[0] > 0}, }
    ],
    [
        q{x/x^2},
        q{-1/x^2},
        { x => sub {$_[0] > 0} },
    ],
    [
        q{2/x},
        q{-2/x^2},
        { x => sub {$_[0] > 0} },
    ],
    [
        q{c/x},
        q{-c/x^2},
        { x => sub {$_[0] > 0} },
    ],
);

foreach my $ref (@f) {
    my ($f, $deriv) = map { parse_from_string($_) } @{$ref}[0,1];
    my $limits = $ref->[2];
    die "parse of '$ref->[0]' failed" if not defined $f;
    die "parse of '$ref->[1]' failed" if not defined $deriv;
    my $d = partial_derivative($f, 'x');
    ok($d->test_num_equiv($deriv, limits => $limits), "$d == $deriv");
}

# Test for regression RT #43783
{
  my $formula1    = parse_from_string('K-C*exp(-L*x)');
  my $formula2    = parse_from_string('K+-C*exp(-L*x)');

  my %parameters = ( C => 0.8, K => 1., L => 1. );

  my $deriv1 = partial_derivative($formula1, 'C')->apply_derivatives()->simplify();
  my $deriv2 = partial_derivative($formula2, 'C')->apply_derivatives()->simplify();

  foreach (1, 2, 3) {
    ok(
      float_eq( 
        $deriv1->value(%parameters, x => $_),
        $deriv2->value(%parameters, x => $_)
      ),
      "Derivatives of semantically equivalent formulas equivalent at x=$_"
    );
  }
}

sub float_eq {
  $_[0] + 1.e-6 > $_[1] and $_[0] - 1.e-6 < $_[1]
}

