# NAME

Math::Roman - Arbitrary sized Roman numbers and conversion from and to Arabic.

# SYNOPSIS

    use Math::Roman qw(roman);

    $a = new Math::Roman 'MCMLXXIII';  # 1973
    $b = roman('MCMLXI');              # 1961
    print $a - $b,"\n";                # prints 'XII'

    $d = Math::Roman->bzero();         # ''
    $d++;                              # 'I'
    $d += 1998;                        # 'MCMXCIX'
    $d -= 'MCM';                       # 'XCIX'

    print "$d\n";                      # string       "MCMIC"
    print $d->as_number(),"\n";        # Math::BigInt "+1999"

# REQUIRES

perl5.005, Exporter, Math::BigInt

# EXPORTS

Exports nothing on default, but can export `as_number()`, `roman()`,
and `error()`.

# DESCRIPTION

Well, it seems I have been infected by the Perligata-Virus, too. ;o)

This module lets you calculate with Roman numbers, as if they were big
integers. The numbers can have arbitrary length and all the usual functions
from Math::BigInt are available.

## Input

The Roman single digits are as follows:

    I       1
    V       5
    X       10
    L       50
    C       100
    D       500
    M       1000

The following (quite modern) rules are in effect:

> Each of I, X and C can be repeated up to 3 times, V, L and D only once.
> Technically, M could be used up to four times, but this module imposes
> no limit on this to allow arbitrarily big numbers.
>
> A Roman number consists of **tokens**, each token is either a digit from
> IVXLCDM or consist of two digits, whereas the first digit is smaller than
> the second one. In the latter case the first digit is subtracted from the
> second (e.g. IV means 4, not 6).
>
> The smaller number must be a power of ten (I, X or C) and precede a
> number no larger than 10 times its own value. The smaller number itself
> can be preceded only by a number at least 10 times greater (e.g. LXC is
> invalid) and it must also be larger than any numeral that follows the one
> from which it is being subtracted (e.g. CMD is invalid).
>
> Each token must be smaller than the token before (e.g. IIV is invalid,
> since I is smaller than IV).
>
> The input will be checked and the result will be a 'NaN' if the check
> fails. You can get the cause with `Math::Roman::error()` until you try
> to create the next Roman number.
>
> The default list of valid tokens a Roman number can consist of is thus:
>
>         III     3
>         XXX     30
>         CCC     300
>         II      2
>         XX      20
>         CC      200
>         IV      4
>         IX      9
>         XL      40
>         XC      90
>         CD      400
>         CM      900
>         I       1
>         V       5
>         X       10
>         L       50
>         C       100
>         D       500
>         M       1000
>
> The default list of invalid tokens is as follows:
>
>         IIII            XXXX            CCCC
>         DD              LL              VV
>         C[MD][CDM]      X[LC][XLCDM]    I[VX][IVXLCDM]

Thanx must go to http://netdirect.net/~charta/Roman\_numerals.html for
clarifications.

## Output

The output will always be of the shortest possible form, and the tokens
will be arranged in a decreasing order.

# BENDING THE RULES

You can use `Math::Roman::tokens()` to get an array with all the defined
tokens and their value. Tokens with a value of -1 are invalid, all others
are valid. The format is token0, value0, token1, value1...

You can create your own set and store it with `Math::Roman::tokens()`.
The routine expects an array of the form token, value, token, value...
etc.  Each token can be a simple string or regular expresion. Values of
\-1 indicate invalid tokens.

Here is an example that removes the subtraction (only addition is valid)
as well as most of the other rules. It then parses 'XIIII' to be 14, then
redefine the token set completely and parses 'AAB' to be 25:

>     use Math::Roman;
>
>     Math::Roman::tokens( qw(I 1  V 5  X 10  L 50  C 100  D 500  M 1000));
>     $r = Math::Roman::roman('XIIII');
>     print "'$r' is ",$r->as_number(),"\n";
>     $r = Math::Roman::roman('XV');
>     print "'$r' is ",$r->as_number(),"\n";
>     Math::Roman::tokens ( qw(A 10 B 5) );
>     $r = Math::Roman::roman('AAB');
>     print "'$r' is ",$r->as_number(),"\n";

Another idea is to implement the dash over symbols, this indicates
multiplying by 1000. Since it is hard to do this in ASCII, lower-case
letters could be used like in the following:

    use Math::Roman;

    # will wrongly ommit the 'M's, but so much 'M's would not fit
    # on your screen anyway
    print 'old: ',new Math::Roman ('+12345678901234567890'),"\n";
    @a = Math::Roman::tokens();
    push @a, qw ( v 5000  x 10000  l 50000  c 100000  d 500000
                  m 1000000 );
    Math::Roman::tokens(@a);
    print 'new: ',new Math::Roman ('+12345678901234567890'),"\n";

# USEFUL METHODS

- new()

        new();

    Create a new Math::Roman object. Argument is a Roman number as string,
    like 'MCMLXXIII' (1973) of the form /^\[IVXLCDM\]\*$/ (see above for further
    rules) or a string number as used by Math::BigInt.

- roman()

        roman();

    Just like new, but you can import it to write shorter code.

- error()

        Math::Roman::error();

    Return error of last number creation when result was NaN.

- bstr()

        $roman->bstr();

    Return a string representing the internal value as a Roman number
    according to the aforementioned rules. A zero will be represented by
    ''.  The output will only consist of valid tokens, and not contain a
    sign.  Use `as_number()` if you need the sign.

    This function always generates the shortest possible form.

- as\_number()

        $roman->as_number();

    Return a string representing the internal value as a normalized arabic
    number, including sign.

# DETAILS

Uses internally Math::BigInt to do the math, all with overloaded
operators.

Roman has neither negative numbers nor zero, but this module handles
these, too. You will get only the absolute value as Roman number, but
can look at the sign with `sign()` or use `as_number()`.

# EXAMPLES

    use Math::Roman qw(roman);

    print Math::Roman->new('MCMLXXII')->as_number(),"\n";
    print Math::Roman->new('LXXXI')->as_number(),"\n";
    print roman('MDCCCLXXXVIII')->as_number(),"\n";

    $a = roman('1311');
    print "$a is ",$a->as_number(),"\n";

    $a = roman('MCMLXXII');
    print "\$a is now $a (",$a->as_number(),")\n";
    $a++; $a += 'MCMXII'; $a = $a * 'X' - 'I';
    print "\$a is now $a (",$a->as_number(),")\n";

# LIMITS

## Internal Number Length

For the actual math, the same limits as in Math::BigInt apply.

## Output length

The output in Roman is limited to 65536 times the biggest symbol. With
the default set this is 'M', so the biggest Roman number you can print
is 65536000 - and it will give you 64 KBytes M's in a row. This could be
fixed, but who really needs it? ;)

## Number Rules

The rule "Each token must be greater than the token before" is
hard-coded in and can not be overcome. So 'IIX' will be invalid for
subtraction-less numbers unless you define an 'IIX' token with a value
of 12.

# BUGS

## Importing functions

You can not import ordinary math functions like `badd()` and write
things like:

    use Math::Roman qw(badd);               # will fail

    $a = badd('MCM','M');                   # does not work
    $a = Math::Roman::badd('MCM','M');      # neither

It is be possible to make this work, but this takes quite a lot of
Copy&Paste code, and some small overhead price for every calculation.
I think this is really not needed, since you can always use:

    use Math::Roman;

    $a = new Math::Roman 'MCM'; $a += 'M';  # neat isn't it?
    $a = Math::Roman->badd('MCM','M');      # or this

## '0'-'9' as tokens

0-9 in the token set produce wrong results in new() if the given argument
consists only of 0-9. That is because first a Math::BigInt is tried to be
constructed, and in this case, would succeed.

## Reporting bugs

Please report any bugs or feature requests to
`bug-math-roman at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-Roman](https://rt.cpan.org/Ticket/Create.html?Queue=Math-Roman)
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Roman

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-Roman](https://github.com/pjacklam/p5-Math-Roman)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-Roman](https://rt.cpan.org/Dist/Display.html?Name=Math-Roman)

- MetaCPAN

    [https://metacpan.org/release/Math-Roman](https://metacpan.org/release/Math-Roman)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-Roman](http://matrix.cpantesters.org/?dist=Math-Roman)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-Roman](https://cpanratings.perl.org/dist/Math-Roman)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

Copyright (C) MCMXCIX-MMIV by Tels [http://bloodgate.com/](http://bloodgate.com/)
