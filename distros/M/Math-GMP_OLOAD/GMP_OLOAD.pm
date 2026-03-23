use strict;
use warnings;
{
  package Math::GMP_OLOAD;
  BEGIN {
    eval{ require Math::GMP;};
    if($@) {
      die "Math::GMP_OLOAD failed to load Math::GMP:\n$@";
    }
  }

  $Math::GMP_OLOAD::VERSION = '0.02';
}

{
  package Math::GMP;

    use overload "+" => sub ($$$) {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return $y + $x;
      }

      return Math::GMP::op_add($x, $y, 0);
    };

    use overload "-" => sub ($$$)  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return -($y - $x);
      }

      return Math::GMP::op_sub($x, $y, shift);
    };

    use overload "*" => sub ($$$) {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return $y * $x;
      }

      return Math::GMP::op_mul($x, $y, 0);
    };

    use overload "/" => sub ($$$) {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR') {
        return Math::MPFR->new($x) / $y;
      }
      if(ref($y) eq 'Math::GMPq') {
        return Math::GMPq->new($x) / $y;
      }
      if(ref($y) eq 'Math::GMPz') {
        return Math::GMPz->new($x) / $y;
      }

      return Math::GMP::op_div($x, $y, shift);
    };

    use overload "**" => sub {
      my($x, $y, $s) = (shift, shift, shift);
      if(ref($y) eq 'Math::MPFR') {
        # We've called GMP ** MPFR ($x ** $y)
        return Math::MPFR::overload_pow($y, $x, 1);
     }
      if(ref($y) eq 'Math::GMPq') {
        # We've called GMP ** GMPq ($x ** $y)
        return Math::GMPq::overload_pow($y, $x, 1);
      }
      if(ref($y) eq 'Math::GMPz') {
        # We've called GMP ** GMPz ($x ** $y)
        return Math::GMPz::overload_pow(Math::GMPz->new($x), $y, 0);
      }

      # We get to here because we've called either:
      # OTHER ** GMP ($y ** $x), and $s is true
      # or
      # GMP ** OTHER ($x ** $y), and $s is false
      $s ? op_pow($y, $x) : op_pow($x, $y);
    };

#    use overload "**=" => sub {
#      my($x, $y, $s) = (shift, shift, shift);
#      if(ref($y) eq 'Math::MPFR') {
#        # We've called GMP ** MPFR ($x ** $y)
#        return Math::MPFR::overload_pow($y, $x, 1);
#     }
#      if(ref($y) eq 'Math::GMPq') {
#        # We've called GMP ** GMPq ($x ** $y)
#        return Math::GMPq::overload_pow($y, $x, 1);
#      }
#      if(ref($y) eq 'Math::GMPz') {
#        # We've called GMP ** GMPz ($x ** $y)
#        return Math::GMPz::overload_pow(Math::GMPz->new($x), $y, 0);
#      }
#
#      # We get to here because we've called either:
#      # OTHER ** GMP ($y ** $x), and $s is true
#      # or
#      # GMP ** OTHER ($x ** $y), and $s is false
#      $s ? op_pow($y, $x) : op_pow($x, $y);
#    };


    use overload "<" => sub  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y > $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, shift);
      return 1 if $cmp < 0;
      return 0;
    };

    use overload ">" => sub  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y < $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, shift);
      return 1 if $cmp > 0;
      return 0;
    };

    use overload "<=" => sub  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y >= $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, shift);
      return 1 if $cmp <= 0;
      return 0;
    };

    use overload ">=" => sub  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y <= $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, shift);
      return 1 if $cmp >= 0;
      return 0;
    };

    use overload "==" => sub ($$$)  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y == $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, 0);
      return 1 if $cmp == 0;
      return 0;
    };

    use overload "!=" => sub ($$$)  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return 1 if $y != $x;
        return 0;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, 0);
      return 1 if $cmp != 0;
      return 0;
    };

    use overload "<=>" => sub ($$$)  {
      my($x, $y) = (shift, shift);
      if(ref($y) eq 'Math::MPFR' || ref($y) eq 'Math::GMPq' || ref($y) eq 'Math::GMPz') {
        return ($y <=> $x) * -1;
      }

      my $cmp = Math::GMP::op_spaceship($x, $y, shift);
      return $cmp;
    };
}

1;
