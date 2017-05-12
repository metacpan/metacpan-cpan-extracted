use 5.014;
use warnings;

Class::Multimethods::multimethod __imod__ => qw(Math::GMPz Math::GMPz) => sub {
    my ($x, $y) = @_;

    my $sign_y = Math::GMPz::Rmpz_sgn($y)
      || goto &Math::AnyNum::_nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($r, $x, $y);

    if (!Math::GMPz::Rmpz_sgn($r)) {
        ## OK
    }
    elsif ($sign_y < 0) {
        Math::GMPz::Rmpz_add($r, $r, $y);
    }

    $r;
};

Class::Multimethods::multimethod __imod__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;

    CORE::int($y)
      || goto &Math::AnyNum::_nan;

    my $neg_y = $y < 0;
    $y = -$y if $neg_y;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod_ui($r, $x, $y);

    if (!Math::GMPz::Rmpz_sgn($r)) {
        ## OK
    }
    elsif ($neg_y) {
        Math::GMPz::Rmpz_sub_ui($r, $r, $y);
    }

    $r;
};

1;
