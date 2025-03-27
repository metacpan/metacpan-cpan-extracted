# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 19125;

use Math::BigFloat;

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

# Convert a Perl scalar to a Math::BigFloat object. This function is used for
# consistent comparisons. For instance, a Not-a-Number might be stringified to
# 'nan', but Math::BigFloat uses 'NaN'.

sub pl2mbf {
    my $x = shift;
    return Math::BigFloat -> binf('+') if $x == $inf;
    return Math::BigFloat -> binf('-') if $x == -$inf;
    return Math::BigFloat -> bnan()    if isnan($x);
    return Math::BigFloat -> new($x);
}

# Does a truncated division (T-division).

sub tdiv {
    die "Usage: fdiv X Y\n" if @_ != 2;

    #no integer;

    my $x = shift;              # numerator
    my $y = shift;              # denominator

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
        # denominator is zero. Math::BigFloat, however, has a different
        # convention.

        my $q = $x < 0 ? -$inf
              : $x > 0 ?  $inf
              :           $nan;
        my $r = $x;
        return wantarray ? ($q, $r) : $q;
    }

    # Numerator is +/-infinity, and denominator is finite and non-zero.

    if (isinf($x)) {
        my $q = int($x / $y);
        my $r = $x - $y * $q;
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
    #              -5 %  Inf =   -5
    #               5 % -Inf =    5

    if (isinf($y)) {
        return wantarray ? (0, $x) : 0;
    }

    return $x / $y unless wantarray;

    # Do a truncated division.

    my $q = int($x / $y);
    my $r = $x - $y * $q;

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
        # btdiv() in list context.
        #######################################################################

        {
            # Compute expected output.

            my ($quo, $rem) = tdiv($num, $den);

            note(qq|\n(\$quo, \$rem) = | .
                 qq|Math::BigFloat -> new("$num") -> btdiv("$den")\n\n|);

            # Input values as objects.

            my $mbf_num = Math::BigFloat -> new("$num");
            my $mbf_den = Math::BigFloat -> new("$den");

            # Get addresses for later tests.

            my ($mbf_num_addr, $mbf_den_addr);
            $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;
            $mbf_den_addr = refaddr($mbf_den) if $scalar_util_ok;

            # Compute actual output values.

            my ($mbf_quo, $mbf_rem) = $mbf_num -> btdiv($mbf_den);

            # Check classes.

            is(ref($mbf_num), 'Math::BigFloat',
               "class of numerator is still Math::BigFloat");
            is(ref($mbf_den), 'Math::BigFloat',
               "class of denominator is still Math::BigFloat");

            is(ref($mbf_quo), 'Math::BigFloat',
               "class of quotient is Math::BigFloat");
            is(ref($mbf_rem), 'Math::BigFloat',
               "class of remainder is Math::BigFloat");

            # Check values.

            is($mbf_quo, pl2mbf($quo), "$num / $den = $quo");
            is($mbf_rem, pl2mbf($rem), "$num % $den = $rem");

            is($mbf_den, pl2mbf($den), "value of denominator has not change");

            # Check addresses.

            my ($mbf_quo_addr, $mbf_rem_addr);
            $mbf_quo_addr = refaddr($mbf_quo) if $scalar_util_ok;
            $mbf_rem_addr = refaddr($mbf_rem) if $scalar_util_ok;

          SKIP: {
                skip "Scalar::Util not available", 2 unless $scalar_util_ok;

                is($mbf_quo_addr, $mbf_num_addr,
                   "the quotient object is the numerator object");

                ok($mbf_rem_addr != $mbf_num_addr &&
                   $mbf_rem_addr != $mbf_den_addr &&
                   $mbf_rem_addr != $mbf_quo_addr,
                   "the remainder object is neither the numerator," .
                   " denominator, nor quotient object");
            }
        }

        #######################################################################
        # btdiv() in scalar context.
        #######################################################################

        {
            # Compute expected output.

            my $quo = tdiv($num, $den);

            note(qq|\n\$quo = | .
                 qq|Math::BigFloat -> new("$num") -> btdiv("$den")\n\n|);

            # Input values as objects.

            my $mbf_num = Math::BigFloat -> new("$num");
            my $mbf_den = Math::BigFloat -> new("$den");

            # Get addresses for later tests.

            my ($mbf_num_addr, $mbf_den_addr);
            $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;
            $mbf_den_addr = refaddr($mbf_den) if $scalar_util_ok;

            # Compute actual output values.

            my $mbf_quo = $mbf_num -> btdiv($mbf_den);

            # Check classes.

            is(ref($mbf_num), 'Math::BigFloat',
               "class of numerator is still Math::BigFloat");
            is(ref($mbf_den), 'Math::BigFloat',
               "class of denominator is still Math::BigFloat");

            is(ref($mbf_quo), 'Math::BigFloat',
               "class of quotient is Math::BigFloat");

            # Check values.

            is($mbf_quo, pl2mbf($quo), "$num / $den = $quo");

            is($mbf_den, pl2mbf($den), "value of numerator has not change");

            # Check addresses.

            my $mbf_quo_addr;
            $mbf_quo_addr = refaddr($mbf_quo) if $scalar_util_ok;;

          SKIP: {
                skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                is($mbf_quo_addr, $mbf_num_addr,
                   "the quotient object is the numerator object");
            }
        }

        #######################################################################
        # btmod() (scalar context only).
        #######################################################################

        {
            # Compute expected output.

            my (undef, $rem) = tdiv($num, $den);

            note(qq|\n\$quo = | .
                 qq|Math::BigFloat -> new("$num") -> btmod("$den")\n\n|);

            # Input values as objects.

            my $mbf_num = Math::BigFloat -> new("$num");
            my $mbf_den = Math::BigFloat -> new("$den");

            # Get addresses for later tests.

            my ($mbf_num_addr, $mbf_den_addr);
            $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;
            $mbf_den_addr = refaddr($mbf_den) if $scalar_util_ok;

            # Compute actual output values.

            my $mbf_rem = $mbf_num -> btmod($mbf_den);

            # Check classes.

            is(ref($mbf_num), 'Math::BigFloat',
               "class of numerator is still Math::BigFloat");
            is(ref($mbf_den), 'Math::BigFloat',
               "class of denominator is still Math::BigFloat");

            is(ref($mbf_rem), 'Math::BigFloat',
               "class of remainder is Math::BigFloat");

            # Check values.

            is($mbf_rem, pl2mbf($rem), "$num % $den = $rem");

            is($mbf_den, pl2mbf($den), "value of denominator has not change");

            # Check addresses.

            my $mbf_rem_addr;
            $mbf_rem_addr = refaddr($mbf_rem) if $scalar_util_ok;

          SKIP: {
                skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                is($mbf_rem_addr, $mbf_num_addr,
                   "the remainder object is the numerator object");
            }
        }
    }
}

# Tests where the invocand and the argument is the same object.

for my $num (-$inf, -20 .. -1, 1 .. 20, $inf, $nan) {

    #######################################################################
    # btdiv() in list context.
    #######################################################################

    {
        # Compute expected output.

        my ($quo, $rem) = tdiv($num, $num);

        note(qq|\n\$x = Math::BigFloat -> new("$num"); | .
             qq|(\$quo, \$rem) = \$x -> btdiv("\$x")\n\n|);

        # Input values as objects.

        my $mbf_num = Math::BigFloat -> new("$num");

        # Get addresses for later tests.

        my $mbf_num_addr;
        $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;

        # Compute actual output values.

        my ($mbf_quo, $mbf_rem) = $mbf_num -> btdiv($mbf_num);

        # Check classes.

        is(ref($mbf_num), 'Math::BigFloat',
           "class of numerator is still Math::BigFloat");

        is(ref($mbf_quo), 'Math::BigFloat',
           "class of quotient is Math::BigFloat");
        is(ref($mbf_rem), 'Math::BigFloat',
           "class of remainder is Math::BigFloat");

        # Check values.

        is($mbf_quo, pl2mbf($quo), "$num / $num = $quo");
        is($mbf_rem, pl2mbf($rem), "$num % $num = $rem");

        # Check addresses.

        my ($mbf_quo_addr, $mbf_rem_addr);
        $mbf_quo_addr = refaddr($mbf_quo) if $scalar_util_ok;
        $mbf_rem_addr = refaddr($mbf_rem) if $scalar_util_ok;

        is($mbf_quo_addr, $mbf_num_addr,
           "the quotient object is the numerator object");

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            ok($mbf_rem_addr != $mbf_num_addr &&
               $mbf_rem_addr != $mbf_quo_addr,
               "the remainder object is neither the numerator," .
               " denominator, nor quotient object");
        }
    }

    #######################################################################
    # btdiv() in scalar context.
    #######################################################################

    {
        # Compute expected output.

        my $quo = tdiv($num, $num);

        note(qq|\n\$x = Math::BigFloat -> new("$num"); | .
             qq|\$quo = \$x -> btdiv(\$x)\n\n|);

        # Input values as objects.

        my $mbf_num = Math::BigFloat -> new("$num");

        # Get addresses for later tests.

        my $mbf_num_addr;
        $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;

        # Compute actual output values.

        my $mbf_quo = $mbf_num -> btdiv($mbf_num);

        # Check classes.

        is(ref($mbf_num), 'Math::BigFloat',
           "class of numerator is still Math::BigFloat");

        is(ref($mbf_quo), 'Math::BigFloat',
           "class of quotient is Math::BigFloat");

        # Check values.

        is($mbf_quo, pl2mbf($quo), "$num / $num = $quo");

        # Check addresses.

        my $mbf_quo_addr;
        $mbf_quo_addr = refaddr($mbf_quo) if $scalar_util_ok;

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            is($mbf_quo_addr, $mbf_num_addr,
               "the quotient object is the numerator object");
        }
    }

    #######################################################################
    # btmod() (scalar context only).
    #######################################################################

    {
        # Compute expected output.

        my (undef, $rem) = tdiv($num, $num);

        note(qq|\n\$x = Math::BigFloat -> new("$num") | .
             qq|\$quo = \$x -> btmod(\$x)\n\n|);

        # Input values as objects.

        my $mbf_num = Math::BigFloat -> new("$num");

        # Get addresses for later tests.

        my $mbf_num_addr;
        $mbf_num_addr = refaddr($mbf_num) if $scalar_util_ok;

        # Compute actual output values.

        my $mbf_rem = $mbf_num -> btmod($mbf_num);

        # Check classes.

        is(ref($mbf_num), 'Math::BigFloat',
           "class of numerator is still Math::BigFloat");

        is(ref($mbf_rem), 'Math::BigFloat',
           "class of remainder is Math::BigFloat");

        # Check values.

        is($mbf_rem, pl2mbf($rem), "$num % $num = $rem");

        # Check addresses.

        my $mbf_rem_addr;
        $mbf_rem_addr = refaddr($mbf_rem) if $scalar_util_ok;

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            is($mbf_rem_addr, $mbf_num_addr,
               "the remainder object is the numerator object");
        }
    }
}
