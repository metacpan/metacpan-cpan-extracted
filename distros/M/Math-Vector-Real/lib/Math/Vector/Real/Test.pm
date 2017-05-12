package Math::Vector::Real::Test;

use strict;
use warnings;
use Carp;

use Exporter qw(import);
our @EXPORT_OK = qw(eq_vector eq_vector_norm);

use base 'Test::Builder::Module';
my $CLASS = __PACKAGE__;

use Math::Vector::Real;

our $epsilon = 0.00001;

sub _check_v {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $a = shift;
    unless (UNIVERSAL::isa($a, 'ARRAY')) {
        my $t = Test::Builder->new;
        $t->ok(0, shift);
        $t->diag("    Vector expected but ", $t->explain($a), " found");
        return;
    }
    1;
}

sub _args_v_s {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $a = shift;
    my $b = shift;
    my $str = shift;
    _check_v($a, $str) or return;
    (V(@$a), $b, $str)
}

sub _args_2v {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $a = shift;
    my $b = shift;
    my $str = shift;
    _check_v($a, $str) or return;
    _check_v($b, $str) or return;
    (V(@$a), V(@$b), $str)
}

sub eq_vector ($$@) {
    my $ok;
    if (my ($a, $b, $str) = &_args_2v) {
        $ok = (($a - $b)->norm2 <= $epsilon * ($epsilon + $a->norm2 + $b->norm2));
        my $t = Test::Builder->new;
        $t->ok($ok, $str);
        $ok or $t->diag("Vectors didn't match, got $a, expected $b");
    }
    $ok;
}

sub eq_vector_norm ($$@) {
    my $ok;
    if (my ($a, $b, $str) = &_args_v_s) {
        my $t = Test::Builder->new;
        $ok = abs($b * $b - $a->norm2) <= $epsilon * ($epsilon + $a->norm2 + $b * $b);
        $t->ok($ok, $str);
        $ok or $t->diag("Vector norm didn't match, got ".$a->norm.", expected $b (vector: $a)");
    }
    $ok;
}

1;
