package Ops::Math;
use strict;
use warnings;
use Ex::Op;

our @EXPORT      = qw(add);
our @EXPORT_OK   = qw(add mul neg clamp is_even plain_twice plain_name);
our %EXPORT_TAGS = (
    arith => [qw(add mul neg)],
    all   => [@EXPORT_OK],
);

BEGIN {
    Ex::Op::make(add     => sub { my ($x, $y) = @_; $x + $y });
    Ex::Op::make(mul     => sub { my ($x, $y) = @_; $x * $y });
    Ex::Op::make(neg     => sub { my ($x) = @_; -$x });
    Ex::Op::make(clamp   => sub { my ($v, $lo, $hi) = @_; $v < $lo ? $lo : $v > $hi ? $hi : $v });
    Ex::Op::make(is_even => sub { my ($n) = @_; $n % 2 == 0 ? 1 : 0 });
}

sub plain_twice { my ($x) = @_; $x * 2 }
sub plain_name  { 'plain' }

1;
