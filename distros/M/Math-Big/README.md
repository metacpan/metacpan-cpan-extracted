# NAME

Math::Big - routines (cos,sin,primes,hailstone,euler,fibbonaci etc) with big numbers

# SYNOPSIS

    use Math::Big qw/primes fibonacci hailstone factors wheel
      cos sin tan euler bernoulli arctan arcsin pi/;

    @primes     = primes(100);          # first 100 primes
    $count      = primes(100);          # number of primes <= 100
    @fib        = fibonacci (100);      # first 100 fibonacci numbers
    $fib_1000   = fibonacci (1000);     # 1000th fibonacci number
    $hailstone  = hailstone (1000);     # length of sequence
    @hailstone  = hailstone (127);      # the entire sequence

    $factorial  = factorial(1000);      # factorial 1000!

    $e = euler(1,64);                   # e to 64 digits

    $b3 = bernoulli(3);

    $cos        = cos(0.5,128);         # cosinus to 128 digits
    $sin        = sin(0.5,128);         # sinus to 128 digits
    $cosh       = cosh(0.5,128);        # cosinus hyperbolicus to 128 digits
    $sinh       = sinh(0.5,128);        # sinus hyperbolicus to 128 digits
    $tan        = tan(0.5,128);         # tangens to 128 digits
    $arctan     = arctan(0.5,64);       # arcus tangens to 64 digits
    $arcsin     = arcsin(0.5,32);       # arcus sinus to 32 digits
    $arcsinh    = arcsin(0.5,18);       # arcus sinus hyperbolicus to 18 digits

    $pi         = pi(1024);             # first 1024 digits
    $log        = log(64,2);            # $log==6, because 2**6==64
    $log        = log(100,10);          # $log==2, because 10**2==100
    $log        = log(100);             # base defaults to 10: $log==2

# REQUIRES

perl5.006002, Exporter, Math::BigInt, Math::BigFloat

# EXPORTS

Exports nothing on default, but can export `primes()`, `fibonacci()`,
`hailstone()`, `bernoulli`, `euler`, `sin`, `cos`, `tan`, `cosh`,
`sinh`, `arctan`, `arcsin`, `arcsinh`, `pi`, `log` and `factorial`.

# DESCRIPTION

This module contains some routines that may come in handy when you want to
do some math with really, really big (or small) numbers. These are primarily
examples.

# FUNCTIONS

- primes()

            @primes = primes($n);
            $primes = primes($n);

    Calculates all the primes below N and returns them as array. In scalar context
    returns the prime count of N (the number of primes less than or equal to N).

    This uses an optimized version of the **Sieve of Eratosthenes**, which takes
    half of the time and half of the space, but is still O(N).

- fibonacci()

            @fib = fibonacci($n);
            $fib = fibonacci($n);

    Calculates the first N fibonacci numbers and returns them as array.
    In scalar context returns the Nth number of the Fibonacci series.

    The scalar context version uses an ultra-fast conquer-divide style algorithm
    to calculate the result and is many times faster than the straightforward way
    of calculating the linear sum.

- hailstone()

            @hail = hailstone($n);          # sequence
            $hail = hailstone($n);          # length of sequence

    Calculates the _Hailstone_ sequence for the number N. This sequence is defined
    as follows:

            while (N != 0)
              {
              if (N is even)
                {
                N is N /2
                }
              else
                {
                N = N * 3 +1
                }
              }

    It is not yet proven whether for every N the sequence reaches 1, but it
    apparently does so. The number of steps is somewhat chaotically.

- base()

            ($n,$a) = base($number,$base);

    Reduces a number to `$base` to the `$n`th power plus `$a`. Example:

            use Math::BigInt :constant;
            use Math::Big qw/base/;

            print base ( 2 ** 150 + 42,2);

    This will print 150 and 42.

- to\_base()

            $string = to_base($number,$base);

            $string = to_base($number,$base, $alphabet);

    Returns a string of `$number` in base `$base`. The alphabet is optional if
    `$base` is less or equal than 36. `$alphabet` is a string.

    Examples:

            print to_base(15,2);            # 1111
            print to_base(15,16);           # F
            print to_base(31,16);           # 1F

- factorial()

            $n = factorial($number);

    Calculate `n!` for `n `= 0>.

    Uses internally Math::BigInt's bfac() method.

- bernoulli()

            $b = bernoulli($n);
            ($c,$d) = bernoulli($n);        # $b = $c/$d

    Calculate the Nth number in the _Bernoulli_ series. Only the first 40 are
    defined for now.

- euler()

            $e = euler($x,$d);

    Calculate _Euler's constant_ to the power of $x (usual 1), to $d digits.
    Defaults to 1 and 42 digits.

- sin()

            $sin = sin($x,$d);

    Calculate _sinus_ of `$x`, to `$d` digits.

- cos()

            $cos = cos($x,$d);

    Calculate _cosinus_ of `$x`, to `$d` digits.

- tan()

            $tan = tan($x,$d);

    Calculate _tangens_ of `$x`, to `$d` digits.

- arctan()

            $arctan = arctan($x,$d);

    Calculate _arcus tangens_ of `$x`, to `$d` digits.

- arctanh()

            $arctanh = arctanh($x,$d);

    Calculate _arcus tangens hyperbolicus_ of `$x`, to `$d` digits.

- arcsin()

            $arcsin = arcsin($x,$d);

    Calculate _arcus sinus_ of `$x`, to `$d` digits.

- arcsinh()

            $arcsinh = arcsinh($x,$d);

    Calculate _arcus sinus hyperbolicus_ of `$x`, to `$d` digits.

- cosh()

            $cosh = cosh($x,$d);

    Calculate _cosinus hyperbolicus_ of `$x`, to `$d` digits.

- sinh()

            $sinh = sinh($x,$d);

    Calculate _sinus hyperbolicus_ of $&lt;$x>, to `$d` digits.

- pi()

            $pi = pi($N);

    The number PI to `$N` digits after the dot.

- log()

            $log = log($number,$base,$A);

    Calculates the logarithmn of `$number` to base `$base`, with `$A` digits
    accuracy and returns a new number as the result (leaving `$number` alone).

    Math::BigInt objects are promoted to Math::BigFloat objects, meaning you will
    never get a truncated integer result like when using `Math::BigInt-`blog()>.

# CAVEATS

- Primes and the Fibonacci series use an array of size N and will not be able
to calculate big sequences due to memory constraints.

    The exception is fibonacci in scalar context, this is able to calculate
    arbitrarily big numbers in O(N) time:

            use Math::Big;
            use Math::BigInt qw/:constant/;

            $fib = Math::Big::fibonacci( 2 ** 320 );

- The Bernoulli numbers are not yet calculated, but looked up in a table, which
has only 40 elements. So `bernoulli($x)` with $x > 42 will fail.

    If you know of an algorithmn to calculate them, please drop me a note.

# BUGS

Please report any bugs or feature requests to
`bug-math-big at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-Big](https://rt.cpan.org/Ticket/Create.html?Queue=Math-Big)
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Big

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-Big](https://github.com/pjacklam/p5-Math-Big)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-Big](https://rt.cpan.org/Dist/Display.html?Name=Math-Big)

- MetaCPAN

    [https://metacpan.org/release/Math-Big](https://metacpan.org/release/Math-Big)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-Big](http://matrix.cpantesters.org/?dist=Math-Big)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-Big](https://cpanratings.perl.org/dist/Math-Big)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

- Tels http://bloodgate.com 2001-2007.
- Peter John Acklam <pjacklam@gmail.com> 2016-.
