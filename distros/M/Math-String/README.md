# NAME

Math::String - Arbitrary sized integers having arbitrary charsets to calculate with key rooms

# SYNOPSIS

    use Math::String;
    use Math::String::Charset;

    $a = new Math::String 'cafebabe';   # default a-z
    $b = new Math::String 'deadbeef';   # a-z
    print $a + $b;                      # Math::String ""

    $a = new Math::String 'aa';         # default a-z
    $b = $a;
    $b++;
    print "$b > $a" if ($b > $a);       # prove that ++ makes it greater
    $b--;
    print "$b == $a" if ($b == $a);     # and that ++ and -- are reverse

    $d = Math::String->bzero( ['0'...'9'] );    # like Math::Bigint
    $d += Math::String->new ( '9999', [ '0'..'9' ] );
                                        # Math::String "9999"

    print "$d\n";                       # string       "00000\n"
    print $d->as_number(),"\n";         # Math::BigInt "+11111"
    print $d->last(5),"\n";             # string       "99999"
    print $d->first(3),"\n";            # string       "111"
    print $d->length(),"\n";            # faster than length("$d");

    $d = Math::String->new ( '', Math::String::Charset->new ( {
      minlen => 2, start => [ 'a'..'z' ], } );

    print $d->minlen(),"\n";            # print 2
    print ++$d,"\n";                    # print 'aa'

# REQUIRES

perl5.005, Exporter, Math::BigInt, Math::String::Charset

# EXPORTS

Exports nothing on default, but can export `as_number()`, `string()`,
`first()`, `digits()`, `from_number`, `bzero()` and `last()`.

# DESCRIPTION

This module lets you calculate with strings (specifically passwords, but not
limited to) as if they were big integers. The strings can have arbitrary
length and charsets. Please see [Math::String::Charset](https://metacpan.org/pod/Math%3A%3AString%3A%3ACharset) for full documentation
on possible character sets.

You can thus quickly determine the number of passwords for brute force
attacks, divide key spaces etc.

- Default charset

    The default charset is the set containing "abcdefghijklmnopqrstuvwxyz"
    (thus producing always lower case output).

# INTERNAL DETAILS

Uses internally Math::BigInt to do the math, all with overloaded operators. For
the character sets, Math::String::Charset is used.

Actually, the 'numbers' created by this module are NOT equal to plain
numbers.  It works more than a counting sequence. Oh, well, example coming:

Imagine a charset from a-z (26 letters). The number 0 is defined as '', the
number one is therefore 'a' and two becomes 'b' and so on. And when you reach
'z' and increment it, you will get 'aa'. 'ab' is next and so on forever.

That works a little bit like the automagic in ++, but more consistent and
flexible. The following example 'breaks' (no, >= instead of gt won't help ;)

        $a = 'z'; $b = $a; $a++; print ($a gt $b ? 'greater' : 'lower');

With Math::String, it does work as intended, you just have to use '<' or
'>' etc for comparing. That was also the main reason for this module ;o)

incidentily, '--' as well most other mathematical operations work as you
expected them to work on big integers.

Compare a Math::String of charset '0-9' sequence to that of a 'normal' number:

       ''   0                       0
       '0'  1                       1
       '1'  2                       2
       '2'  3                       3
       '3'  4                       4
       '4'  5                       5
       '5'  6                       6
       '6'  7                       7
       '7'  8                       8
       '8'  9                       9
       '9'  10                     10
      '00'  11                1*10+ 1
      '01'  12                1*10+ 2
          ...
      '98'  109               9*10+ 9
      '99'  110               9*10+10
     '000'  111         1*100+1*10+ 1
     '001'  112         1*100+1*10+ 2
          ...
    '0000'  1111  1*1000+1*100+1*10+1
          ...
    '1234'  2345  2*1000+3*100+4*10+5

And so on. Here is another example that shows how it works with a number
having 4 digits in each place (named "a","b","c", and "d"):

      a    1           1
      b    2           2
      c    3           3
      d    4           4
     aa    5       1*4+1
     ab    6       1*4+2
     ac    7       1*4+3
     ad    8       1*4+4
     ba    9       2*4+1
     bb   10       2*4+2
     bc   11       2*4+3
     bd   12       2*4+4
     ca   13       3*4+1
     cb   14       3*4+2
     cc   15       3*4+3
     cd   16       3*4+4
     da   17       4*4+1
     db   18       4*4+2
     dc   19       4*4+3
     dd   20       4*4+4
    aaa   21  1*16+1*4+1

Here is one with a charset containing 'characters' longer than one, namely
the words 'foo', 'bar' and 'fud':

           foo           1
           bar           2
           fud           3
        foofoo           4
        foobar           5
        foofud           6
        barfoo           7
        barbar           8
        barfud           9
        fudfoo          10
        fudbar          11
        fudfud          12
     foofoofoo          13 etc

The number sequences are symmetrical to 0, e.g. 'a' is both 1 and -1.
Internally the sign is stored and honoured, only on conversation to string it
is lost.

The caveat is that you can NOT use Math::String to work, let's say with
hexadecimal numbers. If you do calculate with Math::String like you would
with 'normal' hexadecimal numbers (any base would or rather, would not do),
the result may not mean anything and can not nesseccarily compared to plain
hexadecimal math.

The charset given upon creation need not be a 'simple' set consisting of all
the letters. You can, actually, give a set consisting of bi-, tri- or higher
grams.

See Math::String::Charset for examples of higher order charsets and charsets
with more than one character per, well, character.

# USEFUL METHODS

- new()

            Math::String->new();

    Create a new Math::String object. Arguments are the value, and optional
    charset. The charset is set to 'a'..'z' as default.

    Since the charset caches some things, it is much better to give an already
    existing Math::String::Charset object to the contructor, instead of creating
    a new one for each Math::String. This will save you memory and computing power.
    See http://bloodgate.com/perl/benchmarks.html for details, and
    [Math::String::Charset](https://metacpan.org/pod/Math%3A%3AString%3A%3ACharset) for how to construct charsets.

- error()

            $string->error();

    Return the last error message or ''. The error message stems primarily from the
    underlying charset, and is created when you create an illegal charset.

- order()

            $string->order();

    Return the order of the string derived from the underlying charset.
    1 for SIMPLE (or order 1), 2 for bi-grams etc.

- type()

            $string->type();

    Return the type of the string derived from the underlying charset.
    0 for simple and nested charsets, 1 for grouped ones.

- first()

            $string->first($length);

    It is a bit tricky to get the first string of a certain length, because you
    need to consider the charsets at each digit. This method sets the given
    Math::String object to the first possible string of the given length.
    The length defaults to 1.

- last()

            $string->last($length);

    It is a bit tricky to get the last string of a certain length, because you
    need to consider the charsets at each digit. This method sets the given
    Math::String object to the last possible string of the given length.
    The length defaults to 1.

- as\_number()

            $string->as_number();

    Return internal number as normalized string including sign.

- from\_number()

            $string = Math::String::from_number(1234,$charset);

    Create a Math::String from a given integer value and a charset.

    If you want to use big integers as input, quote them:

            $string = Math::String::from_number('12345678901234567890',$set);

    This avoids loosing precision due to intermidiate storage of the number as
    Perl scalar.

- scale()

            $scale = $string->scale();
            $string->scale(120);

    Get/set the (optional) scale of the characterset (thus setting it for all
    strings of that set from this point onwards). A scale is an integer factor
    that will be applied to each as\_number() output as well as each from\_number()
    input. E.g. for a scale of 3, the string to number mapping would be changed
    from the left to the right column:

            string form             normal number   scaled number
            ''                      0               0
            'a'                     1               3
            'b'                     2               6
            'c'                     3               9

    And so on. Input like 8 will be divided by 3, which results in 2 due to
    rounding down to the nearest integer. So:

            $string = Math::String->new( 'a' );             # a..z
            print $string->as_number();                     # 1
            $string->scale(3);
            print $string->as_number();                     # 3
            $string = Math::String->from_number(9,3);       # 9/3 => 3

- bzero()

            $string = Math::String->bzero($charset);

    Create a Math::String with the number value 0 (evaluates to '').
    The following would set $x to '':

            $x = Math::String->new('cafebabe');
            $x->bzero();

- bone()

            $string = Math::String->bone($charset);

    Create a Math::String with the number value 1 and the given charset

    The following would set $x to the number 1 (and it's respective string):

            $x = Math::String->new('cafebabe');
            $x->bone();

- binf()

            $string = Math::String->binf($sign);

    Create a Math::String with the number infinity.

    The following would set $x to -infinity (and it's respective string):

            $x = Math::String->new('deadbeef');
            $x->binf('-');

- bnan()

            $string = Math::String->bnan();

    Create a Math::String as a NotANumber.

    The following would set $x to NaN (and it's respective string):

            $x = Math::String->new('deadbeef');
            $x->bnan();

- is\_valid()

            print $string->error(),"\n" if !$string->is_valid();

    Returns 0 if the string is valid (according to it's charset and string
    representation) and the cached string value matches the string's internal
    number represantation. Costly operation, but usefull for tests.

- class()

            $count = $string->class($length);

    Returns the number of possible strings with the given length, aka so many
    characters (not bytes or chars!).

            $count = $string->class(3);     # how many strings with len 3

- minlen()

            $string->minlen();

    Return the minimum length of a valid string as defined by it's charset.
    Note that the string '' has a length of 0, and thus is not valid if `minlen`
    is greater than 0.
    Returns 0 if no minimum length is required. The minimum length must be smaller
    or equal to the `maxlen`.

- maxlen()

            $string->maxlen();

    Return the maximum length of a valid string as defined by it's charset.
    Returns 0 if no maximum length is required. The maximum length must be greater
    or equal to the `minlen`.

- length()

            $string->length();

    Return the number of characters in the resulting string (aka it's length). The
    zero string '' has a length of 0.

    This is faster than doing `length("$string");` because it doesn't need to do
    the costly creation of the string version from the internal number
    representation.

    Note: The length() will be always in characters. If your characters in the
    charset are longer than one byte/character, you need to multiply the length
    by the character length to find out how many bytes the string would have.

    This is nearly impossible if your character set has characters with different
    lengths (aka if it has a separator character). In this case you need to
    construct the string to find out the actual length in bytes.

- bstr()

            $string->bstr();

    Return a string representing the internal number with the given charset.
    Since this omitts the sign, you can not distinguish between negative and
    positiv values. Use `as_number()` or `sign()` if you need the sign.

    This returns undef for 'NaN', since with a charset of
    \[ 'a', 'N' \] you would not be able to tell 'NaN' from true 'NaN'!
    '+inf' or '-inf' return undef for the same reason.

- charset()

            $string->charset();

    Return a reference to the charset of the Math::String object.

- string()

            Math::String->string();

    Just like new, but you can import it to save typing.

# LIMITS

For the actual math, the same limits as in [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt) apply. Negative
Math::Strings are possible, but produce no different output than positive.
You can use `as_number()` or `sign()` to get the sign, or do math with
them, of course.

Also, the limits detailed in [Math::String::Charset](https://metacpan.org/pod/Math%3A%3AString%3A%3ACharset) apply, like:

- No doubles

    The sets must not contain doubles. With a set of "eerr" you would not
    be able to tell the output "er" from "er", er, if you get my drift...

- Charset items

    All charset items must have the same length, unless you specify a separator
    string:

            use Math::String;

            $b = Math::String->new( '',
               { start => [ qw/ the green car a/ ], sep => ' ', }
               );

            while ($b ne 'the green car')
              {
              print ++$b,"\n";      # print "a green car" etc
              }

- Objectify

    Writing things like

            $a = Math::String::bsub('hal', 'aaa');

    does not work, unlike with Math::BigInt (which just knows how to treat
    the arguments to become BigInts). The first argument must be a
    reference to a Math::String object.

    The following two lines do what you want and are more or less (except output)
    equivalent:

            $a = new Math::String 'vms'; $a -= 'aaa';
            $a = new Math::String 'ibm'; $a->badd('aaa');

    Also, things like

            $a = Math::String::bsub('hal', 5);

    does not work, since Math::String can not decide whether 5 is the number 5,
    or the string '5'. It could, if the charset does not contain '0'..'9', but
    this would lead to confusion if you change the charset. So, the second paramter
    must always be a Math::String object, or a string that is valid with the
    charset of the first parameter. You can use `Math::String::from_number()`:

            $a = Math::String::bsub('hal', Math::String::from_number(5) );

# EXAMPLES

Fun with Math::String:

        use Math::String;

        $ibm = new Math::String ('ibm');
        $vms = new Math::String ('vms');
        $ibm -= 'aaa';
        $vms += 'aaa';
        print "ibm is now $ibm\n";
        print "vms is now $vms\n";

Some more serious examples:

        use Math::String;
        use Math::BigFloat;

        $a = new Math::String 'henry';                  # default a-z
        $b = new Math::String 'foobar';                 # a-z

        # Get's you the amount of passwords between 'henry' and 'foobar'.
        print "a  : ",$a->as_numbert(),"\n";
        print "b  : ",$b->as_bigint(),"\n";
        $c = $b - $a; print $c->as_bigint(),"\n";

        # You want to know what is the first or last password of a certain
        # length (without multiple charsets this looks a bit silly):
        print $a->first(5),"\n";                        # aaaaa
        print Math::String::first(5,['a'..'z']),"\n";   # aaaaa
        print $a->last(5),"\n";                         # zzzzz
        print Math::String::last(5,['A'..'Z']),"\n";    # ZZZZZ

        # Lets assume you had a password of length 4, which contained a
        # Capital, some lowercase letters, somewhere either a number, or
        # one of '.,:;', but you forgot it. How many passwords do you need
        # to brute force in the worst case, testing every combination?
        $a = new Math::String '', ['a'..'z','A'..'Z','0'..'9','.',',',':',';'];
        # produce last possibility ';;;;;' and first 'aaaaa'
        $b = $a->last(4);   # last possibility of length 4
        $c = $a->first(4);  # whats the first password of length 4

        $c->bsub($b);
        print $c->as_bigint(),"\n";             # all of length 4
        print $b->as_bigint(),"\n";             # testing length 1..3 too

        # Let's say your computer can test 100.000 passwords per second, how
        # long would it take?
        $d = $c->bdiv(100000);
        print $d->as_bigint()," seconds\n";     #

        # or:
        $d = new Math::BigFloat($c->as_bigint()) / '100000';
        print "$d seconds\n";                   #

        # You want your computer to run for one hour and see if the password
        # is to be found. What would be the last password to be tested?
        $c = $b + (Math::BigInt->new('100000') * 3600);
        print "Last tested would be: $c\n";

        # You want to know what the 10.000th try would be
        $c = Math::String->from_number(10000,
         ['a'..'z','A'..'Z','0'..'9','.',',',':',';']);
        print "Try #10000 would be: $c\n";

# PERFORMANCE

For simple things, like generating all passwords from 'a' to 'zzz', this
is expensive and slow. A custom, table-driven generator or the build-in
automagic of ++ (if it would work correctly for all cases, that is ;) would
beat it anytime. But if you want to do more than just counting, then this
code is what you want to use.

## BENCHMARKS

See http://bloodgate.com/perl/benchmarks.html

# BUGS

- Charsets with bi-grams do not work fully yet.
- Adding/subtracting etc Math::Strings with different charsets treats the
second argument as it had the charset of the first. This is thought as a
feature, not a bug.

    Only if the first charset contains all the characters of second string, you
    could convert the second string to the first charset, but whether this is
    usefull is questionable:

            use Math::String;

            $a = new Math::String ( 'a',['a'..'z']);        # is 1
            $z = new Math::String ( 'z',['z'..'a']);        # is 1, too

            $b = $a + $z;                                   # is 2, with set a..z
            $y = $z + $a;                                   # is 2, with set z..a

    If you convert $z to $a's charset, you would get either an 1 ('a'),
    or a 26 ('z'), and which one is the right one is unclear.

- Please report any bugs or feature requests to
`bug-math-string at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-String](https://rt.cpan.org/Ticket/Create.html?Queue=Math-String)
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::String

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-String](https://github.com/pjacklam/p5-Math-String)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-String](https://rt.cpan.org/Dist/Display.html?Name=Math-String)

- MetaCPAN

    [https://metacpan.org/release/Math-String](https://metacpan.org/release/Math-String)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-String](http://matrix.cpantesters.org/?dist=Math-String)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-String](https://cpanratings.perl.org/dist/Math-String)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHORS

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

Tels http://bloodgate.com 2000 - 2005.

Maintained by Peter John Acklam, pjacklam@gmail.com 2017-
