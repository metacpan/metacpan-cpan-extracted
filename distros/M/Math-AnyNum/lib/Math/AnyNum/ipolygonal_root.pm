use 5.014;
use warnings;

# $n is a Math::GMPz object
# $k is a Math::GMPz object
# $second is a boolean

sub __ipolygonal_root__ {
    my ($n, $k, $second) = @_;

    # polygonal_root(n, k)
    #   = (sqrt(8 * (k - 2) * n + (k - 4)^2) ± (k - 4)) / (2 * (k - 2))

    state $t = Math::GMPz::Rmpz_init_nobless();
    state $u = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_sub_ui($u, $k, 2);    # u = k-2
    Math::GMPz::Rmpz_mul($t, $n, $u);      # t = n*u
    Math::GMPz::Rmpz_mul_2exp($t, $t, 3);  # t = t*8

    Math::GMPz::Rmpz_sub_ui($u, $u, 2);    # u = u-2
    Math::GMPz::Rmpz_mul($u, $u, $u);      # u = u^2
    Math::GMPz::Rmpz_add($t, $t, $u);      # t = t+u

    Math::GMPz::Rmpz_sgn($t) < 0 && goto &_nan;    # `t` is negative

    Math::GMPz::Rmpz_sqrt($t, $t);                 # t = sqrt(t)
    Math::GMPz::Rmpz_sub_ui($u, $k, 4);            # u = k-4

    $second
      ? Math::GMPz::Rmpz_sub($t, $u, $t)           # t = u-t
      : Math::GMPz::Rmpz_add($t, $t, $u);          # t = t+u

    Math::GMPz::Rmpz_add_ui($u, $u, 2);            # u = u+2
    Math::GMPz::Rmpz_mul_2exp($u, $u, 1);          # u = u*2

    Math::GMPz::Rmpz_sgn($u) || return $n;         # `u` is zero

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_div($r, $t, $u);              # r = floor(t/u)
    return $r;
}

1;
