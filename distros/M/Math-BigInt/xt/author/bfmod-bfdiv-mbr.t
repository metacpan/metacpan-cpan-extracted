# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 19125;

use Math::BigRat;

use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

my $scalar_util_ok = eval { require Scalar::Util; };
Scalar::Util -> import('refaddr') if $scalar_util_ok;

diag "Skipping some tests since Scalar::Util is not installed."
  unless $scalar_util_ok;

# Return 1 if the input argument is +inf or -inf, and "" otherwise.

sub isinf {
    my $x = shift;
    return $x == $inf || $x == -$inf;
}

# Return 1 if the input argument is a nan (Not-a-Number), and "" otherwise.

sub isnan {
    my $x = shift;
    return $x != $x;
}

# Convert a Perl scalar to a Math::BigRat object. This function is used for
# consistent comparisons. For instance, a Not-a-Number might be stringified to
# 'nan', but Math::BigRat uses 'NaN'.

sub pl2mbr {
    my $x = shift;
    return Math::BigRat -> binf('+') if $x == $inf;
    return Math::BigRat -> binf('-') if $x == -$inf;
    return Math::BigRat -> bnan()    if isnan($x);
    return Math::BigRat -> new($x);
}

# Does a floored division (F-division).

sub fdiv {
    die "Usage: fdiv X Y\n" if @_ != 2;

    #no integer;

    my $x = shift;                          # numerator
    my $y = shift;                          # denominator

    # Convert Perl strings representing nan, +inf, and -inf into Perl numbers.

    if ($x =~ /^\s*nan\s*$/i) {
        $x = $nan;
    } elsif ($x =~ /^\s*([+-]?)inf(inity)?\s*$/i) {
        $x = $1 eq '-' ? -$inf : $inf;
    }

    if ($y =~ /^\s*nan\s*$/i) {
        $y = $nan;
    } elsif ($y =~ /^\s*([+-]?)inf(inity)?\s*$/i) {
        $y = $1 eq '-' ? -$inf : $inf;
    }

    # If any input is nan, the output is nan.

    if (isnan($x) || isnan($y)) {
        return wantarray ? ($nan, $nan) : $nan;
    }

    # Divide by zero and modulo zero.

    if ($y == 0) {

        # Core Perl gives an "Illegal division by zero" error whenever the
        # denominator is zero. Math::BigRat, however, has a different
        # convention.

        my $q = $x < 0 ? -$inf
              : $x > 0 ?  $inf
              :           $nan;
        my $r = $x;
        return wantarray ? ($q, $r) : $q;
    }

    # Numerator is +/-infinity, and denominator is non-zero.

    if (isinf($x)) {
        my $q = $x / $y;
        my $r = $nan;
        return wantarray ? ($q, $r) : $q;

        if (isinf($y)) {
            return wantarray ? ($nan, $nan) : $nan;
        } else {
            if (($x <=> 0) == ($y <=> 0)) {
                return wantarray ? ($inf, $nan) : $inf;
            } else {
                return wantarray ? (-$inf, $nan) : -$inf;
            }
        }
    }

    # Denominator is +/- infinity, and the numerator is finite.
    #
    # Core Perl:    5 %  Inf =    5
    #              -5 % -Inf =   -5
    #              -5 %  Inf =  Inf
    #               5 % -Inf = -Inf

    if (isinf($y)) {
        if (wantarray) {
            if ($x == 0 || ($x <=> 0) == ($y <=> 0)) {
                return 0, $x;
            } else {
                return -1, ($y <=> 0) * $inf;
            }
        } else {
            return 0;
        }
    }

    return $x / $y unless wantarray;

    # First do a truncated division ...

    my $q = int($x / $y);
    my $r = $x - $y * $q;

    # ... then convert it to a floored division.

    if ($y > 0 && $r < 0 ||
        $y < 0 && $r > 0)
    {
        $q -= 1;
        $r += $y;
    }

    return wantarray ? ($q, $r) : $q;
}

# Tests where the invocand and the argument are two different objects.

#for my $num (-20 .. 20) {
#    for my $den (-20 .. -1, 1 .. 20) {
for my $num (-$inf, -20 .. 20, $inf, $nan) {
    for my $den (-$inf, -20, -16, -10, -8, -5, -4, -2, -1,
                 0, 1, 2, 4, 5, 8, 10, 16, 20, $inf, $nan)
    {

        #######################################################################
        # bfdiv() in list context.
        #######################################################################

        {
            # Compute expected output.

            my ($quo, $rem) = fdiv($num, $den);

            note(qq|\n(\$quo, \$rem) = | .
                 qq|Math::BigRat -> new("$num") -> bfdiv("$den")\n\n|);

            # Input values as objects.

            my $mbr_num = Math::BigRat -> new("$num");
            my $mbr_den = Math::BigRat -> new("$den");

            # Get addresses for later tests.

            my ($mbr_num_addr, $mbr_den_addr);
            $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;
            $mbr_den_addr = refaddr($mbr_den) if $scalar_util_ok;

            # Compute actual output values.

            my ($mbr_quo, $mbr_rem) = $mbr_num -> bfdiv($mbr_den);

            # Check classes.

            is(ref($mbr_num), 'Math::BigRat',
               "class of numerator is still Math::BigRat");
            is(ref($mbr_den), 'Math::BigRat',
               "class of denominator is still Math::BigRat");

            is(ref($mbr_quo), 'Math::BigRat',
               "class of quotient is Math::BigRat");
            is(ref($mbr_rem), 'Math::BigRat',
               "class of remainder is Math::BigRat");

            # Check values.

            is($mbr_quo, pl2mbr($quo), "$num / $den = $quo");
            is($mbr_rem, pl2mbr($rem), "$num % $den = $rem");

            is($mbr_den, pl2mbr($den), "value of denominator has not changed");

            # Check addresses.

            my ($mbr_quo_addr, $mbr_rem_addr);
            $mbr_quo_addr = refaddr($mbr_quo) if $scalar_util_ok;
            $mbr_rem_addr = refaddr($mbr_rem) if $scalar_util_ok;

            is($mbr_quo_addr, $mbr_num_addr,
               "the quotient object is the numerator object");

          SKIP: {
                skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                ok($mbr_rem_addr != $mbr_num_addr &&
                   $mbr_rem_addr != $mbr_den_addr &&
                   $mbr_rem_addr != $mbr_quo_addr,
                   "the remainder object is neither the numerator," .
                   " denominator, nor quotient object");
            }
        }

        #######################################################################
        # bfdiv() in scalar context.
        #######################################################################

        {
            # Compute expected output.

            my $quo = fdiv($num, $den);

            note(qq|\n\$quo = | .
                 qq|Math::BigRat -> new("$num") -> bfdiv("$den")\n\n|);

            # Input values as objects.

            my $mbr_num = Math::BigRat -> new("$num");
            my $mbr_den = Math::BigRat -> new("$den");

            # Get addresses for later tests.

            my ($mbr_num_addr, $mbr_den_addr);
            $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;
            $mbr_den_addr = refaddr($mbr_den) if $scalar_util_ok;

            # Compute actual output values.

            my $mbr_quo = $mbr_num -> bfdiv($mbr_den);

            # Check classes.

            is(ref($mbr_num), 'Math::BigRat',
               "class of numerator is still Math::BigRat");
            is(ref($mbr_den), 'Math::BigRat',
               "class of denominator is still Math::BigRat");

            is(ref($mbr_quo), 'Math::BigRat',
               "class of quotient is Math::BigRat");

            # Check values.

            is($mbr_quo, pl2mbr($quo), "$num / $den = $quo");

            is($mbr_den, pl2mbr($den), "value of numerator has not changed");

            # Check addresses.

            my $mbr_quo_addr;
            $mbr_quo_addr = refaddr($mbr_quo) if $scalar_util_ok;

          SKIP: {
                skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                is($mbr_quo_addr, $mbr_num_addr,
                   "the quotient object is the numerator object");
            }
        }

        #######################################################################
        # bfmod() (scalar context only).
        #######################################################################

        {
            # Compute expected output.

            my (undef, $rem) = fdiv($num, $den);

            note(qq|\n\$quo = | .
                 qq|Math::BigRat -> new("$num") -> bfmod("$den")\n\n|);

            # Input values as objects.

            my $mbr_num = Math::BigRat -> new("$num");
            my $mbr_den = Math::BigRat -> new("$den");

            # Get addresses for later tests.

            my ($mbr_num_addr, $mbr_den_addr);
            $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;
            $mbr_den_addr = refaddr($mbr_den) if $scalar_util_ok;

            # Compute actual output values.

            my $mbr_rem = $mbr_num -> bfmod($mbr_den);

            # Check classes.

            is(ref($mbr_num), 'Math::BigRat',
               "class of numerator is still Math::BigRat");
            is(ref($mbr_den), 'Math::BigRat',
               "class of denominator is still Math::BigRat");

            is(ref($mbr_rem), 'Math::BigRat',
               "class of remainder is Math::BigRat");

            # Check values.

            is($mbr_rem, pl2mbr($rem), "$num % $den = $rem");

            is($mbr_den, pl2mbr($den), "value of denominator has not changed");

            # Check addresses.

            my $mbr_rem_addr;
            $mbr_rem_addr = refaddr($mbr_rem) if $scalar_util_ok;

          SKIP: {
                skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                is($mbr_rem_addr, $mbr_num_addr,
                   "the remainder object is the numerator object");
            }
        }
    }
}

# Tests where the invocand and the argument is the same object.

#for my $num (-$inf, -20 .. 20, $inf, $nan) {
for my $num (-$inf, -20 .. -1, 1 .. 20, $inf, $nan) {

    #######################################################################
    # bfdiv() in list context.
    #######################################################################

    {
        # Compute expected output values.

        my ($quo, $rem) = fdiv($num, $num);

        note(qq|\n\$x = Math::BigRat -> new("$num"); | .
             qq|(\$quo, \$rem) = \$x -> bfdiv("\$x")\n\n|);

        # Input values as objects.

        my $mbr_num = Math::BigRat -> new("$num");

        # Get addresses for later tests.

        my $mbr_num_addr;
        $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;

        # Compute actual output values.

        my ($mbr_quo, $mbr_rem) = $mbr_num -> bfdiv($mbr_num);

        # Check classes.

        is(ref($mbr_num), 'Math::BigRat',
           "class of numerator is still Math::BigRat");

        is(ref($mbr_quo), 'Math::BigRat',
           "class of quotient is Math::BigRat");
        is(ref($mbr_rem), 'Math::BigRat',
           "class of remainder is Math::BigRat");

        # Check values.

        is($mbr_quo, pl2mbr($quo), "$num / $num = $quo");
        is($mbr_rem, pl2mbr($rem), "$num % $num = $rem");

        # Check addresses.

        my ($mbr_quo_addr, $mbr_rem_addr);
        $mbr_quo_addr = refaddr($mbr_quo) if $scalar_util_ok;
        $mbr_rem_addr = refaddr($mbr_rem) if $scalar_util_ok;

      SKIP: {
            skip "Scalar::Util not available", 2 unless $scalar_util_ok;

            is($mbr_quo_addr, $mbr_num_addr,
               "the quotient object is the numerator object");

            ok($mbr_rem_addr != $mbr_num_addr &&
               $mbr_rem_addr != $mbr_quo_addr,
               "the remainder object is neither the numerator," .
               " denominator, nor quotient object");
        }
    }

    #######################################################################
    # bfdiv() in scalar context.
    #######################################################################

    {
        # Compute expected output values.

        my $quo = fdiv($num, $num);

         note(qq|\n\$x = Math::BigRat -> new("$num"); | .
             qq|\$quo = \$x -> bfdiv(\$x)\n\n|);

        # Input values as objects.

        my $mbr_num = Math::BigRat -> new("$num");

        # Get addresses for later tests.

        my $mbr_num_addr;
        $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;

        # Compute actual output values.

        my $mbr_quo = $mbr_num -> bfdiv($mbr_num);

        # Check classes.

        is(ref($mbr_num), 'Math::BigRat',
           "class of numerator is still Math::BigRat");

        is(ref($mbr_quo), 'Math::BigRat',
           "class of quotient is Math::BigRat");

        # Check values.

        is($mbr_quo, pl2mbr($quo), "$num / $num = $quo");

        # Check addresses.

        my $mbr_quo_addr;
        $mbr_quo_addr = refaddr($mbr_quo) if $scalar_util_ok;

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            is($mbr_quo_addr, $mbr_num_addr,
               "the quotient object is the numerator object");
        }
    }

    #######################################################################
    # bfmod() (scalar context only).
    #######################################################################

    {
        # Compute expected output values.

        my (undef, $rem) = fdiv($num, $num);

        note(qq|\n\$x = Math::BigRat -> new("$num") | .
             qq|\$quo = \$x -> bfmod(\$x)\n\n|);

        # Input values as objects.

        my $mbr_num = Math::BigRat -> new("$num");

        # Get addresses for later tests.

        my $mbr_num_addr;
        $mbr_num_addr = refaddr($mbr_num) if $scalar_util_ok;

        # Compute actual output values.

        my $mbr_rem = $mbr_num -> bfmod($mbr_num);

        # Check classes.

        is(ref($mbr_num), 'Math::BigRat',
           "class of numerator is still Math::BigRat");

        is(ref($mbr_rem), 'Math::BigRat',
           "class of remainder is Math::BigRat");

        # Check values.

        is($mbr_rem, pl2mbr($rem), "$num % $num = $rem");

        # Check addresses.

        my $mbr_rem_addr;
        $mbr_rem_addr = refaddr($mbr_rem) if $scalar_util_ok;

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            is($mbr_rem_addr, $mbr_num_addr,
               "the remainder object is the numerator object");
        }
    }
}
