# NAME

Math::BigInt::Random::OO - generate uniformly distributed Math::BigInt objects

# SYNOPSIS

    use Math::BigInt::Random::OO;

    # Random numbers between 1e20 and 2e30:

    $gen = Math::BigInt::Random::OO -> new(min => "1e20",
                                           min => "2e30");
    $x = $gen -> generate();      # one number
    $x = $gen -> generate(1);     # ditto
    @x = $gen -> generate(100);   # 100 numbers

    # Random numbers with size fitting 20 hexadecimal digits:

    $gen = Math::BigInt::Random::OO -> new(length => 20,
                                           base => 16);
    @x = $gen -> generate(100);

# ABSTRACT

Math::BigInt::Random::OO is a module for generating arbitrarily large random
integers from a discrete, uniform distribution. The numbers are returned as
Math::BigInt objects.

# DESCRIPTION

Math::BigInt::Random::OO is a module for generating arbitrarily large random
integers from a discrete, uniform distribution. The numbers are returned as
Math::BigInt objects.

# CONSTRUCTORS

- CLASS -> new ( ... )

    Returns a new `Math::BigInt::Random::OO` random number generator object. The
    arguments are given in the "hash style", as shown in the following example
    which constructs a generator for random numbers in the range from -2 to 3,
    inclusive.

        my $gen = Math::BigInt::Random::OO -> new(min => -2,
                                                  max =>  3);

    The following parameters are recognized.

    - min => NUM

        Specifies the minimum possible output value, i.e., the lower bound. If \`max' is
        given, but \`min' is not, then \`min' is set to zero.

    - max => NUM

        Specifies the maximum possible output value, i.e., the upper bound. If \`max' is
        given, but \`min' is not, then \`max' must be non-negative.

    - length => NUM

        Specifies the length of the output value, i.e., the number of digits. This
        parameter, possibly used together with \`base', is more convenient than \`min'
        and \`max' when you want all random numbers have the same number of digits. If
        the base is not given explicitly with the \`base' option, then a base of 10 is
        used. The following two constructors are equivalent

            $gen1 = Math::BigInt::Random::OO -> new(length => $n, base => $b);

            $min  = Math::BigInt -> new($b) -> bpow($n - 1);
            $max  = Math::BigInt -> new($b) -> bpow($n) -> bsub(1));
            $gen2 = Math::BigInt::Random::OO -> new(min => $min, max => $max);

        For instance, if the length is 4 and the base is 10, the random numbers will be
        in the range from 1000 to 9999, inclusive. If the length is 3 and the base is
        16, the random numbers will be in the range from 256 to 4095, which is 100 to
        fff hexadecimal.

        This option is ignored if the \`max' option is present.

    - base => NUM

        Sets the base to be used with the \`length' option. See also the description for
        the \`length' option.

    - length\_bin => NUM

        This option is only for compatibility with Math::BigInt::Random. The following
        two cases are equivalent

            $class -> new(length_bin => $n);
            $class -> new(length => $n, base => 2);

    - length\_hex => NUM

        This option is only for compatibility with Math::BigInt::Random. The following
        two cases are equivalent

            $class -> new(length_hex => $n);
            $class -> new(length => $n, base => 16);

- OBJECT -> generate ( COUNT )
- OBJECT -> generate ( )

    Generates the given number of random numbers, or one number, if no input
    argument is given.

        # Generate ten random numbers:

        my @num = $gen -> generate(10);

# TODO

- Add a way to change the core uniform random number generator. Currently,
CORE::rand() is used, but it would be nice to be able to switch to, e.g.,
Math::Random::random\_uniform\_integer().
- Add functionality similar to the `use_internet` parameter argument in
Math::BigInt::Random::random\_bigint(). This could be implemented using, e.g.,
Net::Random.
- Add more tests.

# NOTES

The task is to generate a random integer X satisfying X\_min <= X <=
X\_max. This is equivalent to generating a random integer U satisfying 0 <=
U < U\_max, where U\_max = X\_max - X\_min + 1, and then returning X, where X =
U + X\_min.

- Find the smallest integer N so that U\_max <= 2\*\*N.
- Generate uniformly distributed random integers U in the range 0 <= U <
2\*\*N until we have the first U < U\_max. Then return X, where X = U + X\_min.

The random integer U, where 0 <= U < 2\*\*N is generated as a sequence of
random bytes, except for the N % 8 most significant bits, if any. For example,
if N = 21 = 5 + 8 + 8, then the 5 most significand bits are generated first,
followed by two 8 bit bytes.

      |    top bits   |    first whole byte    |    second whole byte   |
        0  0  0  0  0   1  1  1  1  1  1  1  1   2  2  2  2  2  2  2  2
    int(rand(1 << 5))     int(rand(1 << 8))         int(rand(1 << 8))

## Problems with Math::BigInt::Random

I wrote this module partly since Math::BigInt::Random v0.04 is buggy, and in
many cases slower, and partly because I prefer an object-oriented interface.
The bugs in Math::BigInt::Random v0.04 are

- When the range (the maximum value minus the minimum value) is smaller than
1048575 (fffff hexadecimal), the maximum value will never be returned.
- When the range is not a power of two, certain values are more likely to occur
than others.

The core of this last problem is the use of int(rand(X)), which only returns
uniformly distributed numbers when X is a power of two no larger than
_RANDBITS_.

In addition, the function Math::BigInt::Random::random\_bigint() generates only
one random integer at a time, and in doing so, there is some overhead. In
Math::BigInt::Random::OO, this overhead is placed in the new() constructor, so
it is done only once, independently of how many random numbers are generated by
the generator() method.

# CAVEATS

- Some versions of CORE::rand() behave poorly, so the quality of the random
numbers generated depend on the quality of the random number returned
by int(rand(256)).

# BUGS

Please report any bugs or feature requests to `bug-math-bigint-random-oo at
rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/Public/Bug/Report.html?Queue=Math-BigInt-Random-OO](http://rt.cpan.org/Public/Bug/Report.html?Queue=Math-BigInt-Random-OO) I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Random::OO

You can also look for information at:

- GitHub Source Repository

    [https://github.com/pjacklam/p5-Math-BigInt-Random-OO](https://github.com/pjacklam/p5-Math-BigInt-Random-OO)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-Random-OO](https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-Random-OO)

- MetaCPAN

    [https://metacpan.org/dist/Math-BigInt-Random-OO](https://metacpan.org/dist/Math-BigInt-Random-OO)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-Random-OO](http://matrix.cpantesters.org/?dist=Math-BigInt-Random-OO)

# SEE ALSO

Math::BigInt::Random(3), Math::Random(3), Net::Random(3).

# AUTHOR

Peter John Acklam &lt;pjacklam (at) gmail.com>.

# COPYRIGHT & LICENSE

Copyright 2010,2020,2023 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
