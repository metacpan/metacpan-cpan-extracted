#!perl
use 5.010;
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Ex::Op ();

# Each op against a plain sub with the same body.

sub p_add     { my ($x, $y) = @_; $x + $y }
sub p_clamp   { my ($v, $lo, $hi) = @_; $v < $lo ? $lo : $v > $hi ? $hi : $v }
sub p_is_even { my ($n) = @_; $n % 2 == 0 }
sub p_name    { my ($self) = @_; $self->{name} }
sub p_six     { my ($a1, $a2, $a3, $a4, $a5, $a6) = @_; $a1 + $a2 + $a3 + $a4 + $a5 + $a6 }

BEGIN {
    Ex::Op::make(o_add     => sub { my ($x, $y) = @_; $x + $y });
    Ex::Op::make(o_clamp   => sub { my ($v, $lo, $hi) = @_; $v < $lo ? $lo : $v > $hi ? $hi : $v });
    Ex::Op::make(o_is_even => sub { my ($n) = @_; $n % 2 == 0 });
    Ex::Op::make(o_name    => sub { my ($self) = @_; $self->{name} });
    Ex::Op::make(o_six     => sub { my ($a1, $a2, $a3, $a4, $a5, $a6) = @_; $a1 + $a2 + $a3 + $a4 + $a5 + $a6 });
}

my $obj = { name => 'n' };
my %cases = (
    add      => { plain => sub { p_add(1, 2) },             op => sub { o_add(1, 2) } },
    clamp    => { plain => sub { p_clamp(950, 100, 900) },  op => sub { o_clamp(950, 100, 900) } },
    is_even  => { plain => sub { p_is_even(7) },            op => sub { o_is_even(7) } },
    accessor => { plain => sub { p_name($obj) },            op => sub { o_name($obj) } },
    six      => { plain => sub { p_six(1, 2, 3, 4, 5, 6) }, op => sub { o_six(1, 2, 3, 4, 5, 6) } },
);

for my $case (qw(add clamp is_even accessor six)) {
    die "$case: not the same" unless scalar($cases{$case}{plain}->()) eq scalar($cases{$case}{op}->());
    print "\n$case\n";
    cmpthese(-3, $cases{$case});
}
