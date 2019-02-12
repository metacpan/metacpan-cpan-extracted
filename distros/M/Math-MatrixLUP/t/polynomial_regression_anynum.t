#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.30 is needed"
      if ($Math::AnyNum::VERSION < 0.30);
}

plan tests => 2;

use Math::MatrixLUP;
use Math::AnyNum qw(:overload ipow);

sub regress {
    my ($x, $y, $degree) = @_;

    my $mx = Math::MatrixLUP->build(
        scalar(@$x),
        $degree + 1,
        sub {
            my ($i, $j) = @_;
            ipow($x->[$i], $j);
        }
    );

    my $my = Math::MatrixLUP->column($y);

    my $r1 = $mx->transpose->mul($mx)->invert->mul($mx->transpose)->mul($my)->transpose;
    my $r2 = ~((~$mx * $mx)**(-1) * ~$mx * $my);

    return ($r1, $r2);
}

#<<<
my ($r1, $r2) = regress(
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    [1, 6, 17, 34, 57, 86, 121, 162, 209, 262, 321],
    2
);
#>>>

is_deeply($r1->as_array, $r2->as_array);
is_deeply($r1->as_array, [[1, 2, 3]]);
