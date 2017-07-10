use 5.014;
use warnings;

Class::Multimethods::multimethod __irand__ => qw(Math::GMPz Math::GMPz *) => sub {
    my ($x, $y, $state) = @_;

    my $cmp = Math::GMPz::Rmpz_cmp($y, $x);

    if ($cmp == 0) {
        return $x;
    }
    elsif ($cmp < 0) {
        ($x, $y) = ($y, $x);
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub($r, $y, $x);
    Math::GMPz::Rmpz_add_ui($r, $r, 1);
    Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
    Math::GMPz::Rmpz_add($r, $r, $x);
    $r;
};

Class::Multimethods::multimethod __irand__ => qw(Math::GMPz *) => sub {
    my ($x, $state) = @_;

    my $sgn = Math::GMPz::Rmpz_sgn($x) || return $x;

    my $r = Math::GMPz::Rmpz_init_set($x);

    if ($sgn < 0) {
        Math::GMPz::Rmpz_sub_ui($r, $r, 1);
    }
    else {
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
    }

    Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
    Math::GMPz::Rmpz_neg($r, $r) if $sgn < 0;
    $r;
};

1;
