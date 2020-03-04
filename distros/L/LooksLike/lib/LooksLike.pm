
use v5.12.0;

use strict;
use warnings;

package LooksLike;
# ABSTRACT: See if a number looks like a number, integer, numeric, infinity, not-a-number, zero, non-zero, positive, negative, even, or odd.


use B ();


our $VERSION = 'v0.20.060'; # VERSION


my $digits = '[0123456789]';
my $int    = qr/$digits+/;
my $bits   = '[01]';
my $binary = qr/0b$bits+/i;
my $octits = '[01234567]';
my $octal  = qr/0$octits+/;
my $xigits = '[[:xdigit:]]';
my $hex    = qr/0x$xigits+/i;


### The following can only be tested with regular expressions ###


our $Binary  = $binary;


sub binary {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    return /\A\s*$Binary\s*\z/;
}



our $Octal   = $octal;


sub octal {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    return /\A\s*$Octal\s*\z/;
}



our $Hex     = $hex;


sub hex {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    return /\A\s*$Hex\s*\z/;
}



our $Decimal = qr/[+-]?(?:$int(?:\.$digits*)?|\.$int)/;


sub decimal {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    return /\A\s*$Decimal\s*\z/;
}



my $infinity = 8888e8888;
my $inf = do {
    my $inf = qr/inf(?:inity)?/i;
    if ( $^O eq 'MSWin32' || $^V ge v5.22.0 ) {
        # Some versions of Perl accept a broader
        # range of representations of infinity.
        # 1.#infinity, 1.#inf*
        my $dotinf = qr/1\.\#inf(?:inity|0*)/i;
        qr/$dotinf|$inf/;
    } elsif ( $infinity !~ $inf ) {
        $inf = join( '|',
            sort { length($b) <=> length($a) } $inf, quotemeta($infinity)
        );
        qr/$inf/;
    } else {
        $inf;
    }
};

my $notanumber = $infinity / $infinity;
my $nan = do {
    my $nan = qr/nan/i;
    if ( $^O eq 'MSWin32' || $^V ge v5.22.0 ) {
        # Some versions of Perl accept a broader
        # range of representations of NaN.
        # https://en.wikipedia.org/wiki/NaN#Display
        # nan[qs]?, [qs]nan,
        # nan\($int\), nan\($hex\), nan\(\"$octal\"\), nan\($binary\)
        # 1\.\#nan[qs]?, 1\.\#[qs]nan, 1\.\#ind0*
        my $nan    = qr/nan[qs]?|[qs]nan/i;
        my $nandig = qr/$nan\((?:$binary|\"$octal\"|$hex|$int)\)/i;
        my $ind    = qr/ind0*/i;
        my $dotnan = qr/1\.\#(?:$nandig|$nan|$ind)/;
        qr/$dotnan|$nandig|$nan/
    } elsif ( $notanumber !~ $nan ) {
        $nan = join( '|',
            sort { length($b) <=> length($a) } $nan, quotemeta($notanumber)
        );
        qr/$nan/;
    } else {
        $nan;
    }
};

sub grok_number {
    local $_ = shift if @_;
    return unless defined;
    return if ref;

    my ( $sign, $number, $frac, $exp_sign, $exp_number, $excess );

    ( $sign, $number ) = m/\A\s*([+-]?)($inf|$nan|$int?)/cg;
    if ( $number =~ m/\A(?:$inf|$nan)\z/ ) {
        $frac = $1
            if ( $^V ge v5.22.0
            && $number =~ s/\A1\.\#//
            && $number =~ s/(?:\(($binary|\"$octal\"|$hex|$int)\)|0*)\z// );

        # There should be no additional fractional
        # nor exponent portion to parse.
    } else {
        ( $frac, $exp_sign, $exp_number )
            = /\G(?:\.($int?))?(?:[Ee]([+-]?)($int))?/cg;
    }
    if ( !length($number) && !length($frac) ) {
        # Nope, this is not a legitimate number.
        $sign = $number = $frac = $exp_sign = $exp_number = undef;
        pos() = 0;
    }
    m/\G\s*/cg if pos();
    $excess = substr( $_, pos() );

    return ( $sign, $number, $frac, $exp_sign, $exp_number, $excess );
}


# The following can be tested with mathematics or regular expressions.


our $Infinity = qr/[+-]?$inf/;


sub infinity {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & B::SVp_NOK ) {
        return $_ == $infinity || $_ == -$infinity;
    }
    return /\A\s*$Infinity\s*\z/;
}



our $NaN = qr/[+-]?$nan/;


sub nan {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & B::SVp_NOK ) {
        return not defined( $_ <=> 0 );
    }
    return /\A\s*$NaN\s*\z/;
}



our $Integer = qr/[+-]?$int/;


sub integer {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    my $flags = B::svref_2object( \$_ )->FLAGS;
    if ( $flags & B::SVp_IOK && !( $flags & B::SVp_NOK ) ) {
        return 1;
    }
    return /\A\s*$Integer\s*\z/;
}



my $exponent = qr/[Ee]$Integer/;
our $Numeric = qr/$Decimal$exponent?/;


sub numeric {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return defined( $_ <=> 0 ) && $_ != $infinity && $_ != -$infinity;
    }
    return /\A\s*$Numeric\s*\z/;
}



# NaN is not comparable.
sub comparable {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return defined( $_ <=> 0 );
    }
    return /\A\s*(?:$Infinity|$Integer|$Numeric)\s*\z/;
}



sub number {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return 1;
    }
    return /\A\s*(?:$Infinity|$Integer|$NaN|$Numeric)\s*\z/;
}



# 0, 0.0*, .0+, 0E0, 0.0E0, .0E100, ...
my $zero  = qr/(?:0+(?:[.]0*)?|[.]0+)$exponent?/;
our $Zero = qr/[+-]?$zero/;


sub zero {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return $_ == 0;
    }
    return /\A\s*$Zero\s*\z/;
}



my $nonzero = do {
    my $digits19     = '[123456789]';
    my $nonzeroint   = qq/$digits*$digits19+$digits*/;
    my $nonzerofloat = qq/[.]$nonzeroint/;
    my $nonzeronum   = qr/$nonzeroint(?:[.]$digits*)?|$digits*$nonzerofloat/;
    qr/$inf|$nonzeronum$exponent?/;
};
our $NonZero = qr/[+-]?$nonzero/;


sub nonzero {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return $_ != 0;
    }
    return /\A\s*$NonZero\s*\z/;
}



our $Positive = qr/[+]?$nonzero/;


# Returns true if number would be greater than 0
sub positive {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return $_ > 0;
    }
    return /\A\s*$Positive\s*\z/;
}


our $Negative = qr/[-]$nonzero/;


# Returns true if number would be less than 0
sub negative {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    if ( B::svref_2object( \$_ )->FLAGS & ( B::SVp_NOK | B::SVp_IOK ) ) {
        return $_ < 0;
    }
    return /\A\s*$Negative\s*\z/;
}



my $evens = '[02468]';
our $Even = qr/[+-]?$digits*$evens/;


# Returns true if integer would be divisible by 2
sub even {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    my $flags = B::svref_2object( \$_ )->FLAGS;
    if ( $flags & B::SVp_IOK && !( $flags & B::SVp_NOK ) ) {
        return 0 == ( $_ % 2 );
    }
    return /\A\s*$Even\s*\z/;
}



my $odds = '[13579]';
our $Odd = qr/[+-]?$digits*$odds/;


# Returns true if integer would not be divisible by 2
sub odd {
    local $_ = shift if @_;
    return undef unless defined;
    return undef if ref;

    my $flags = B::svref_2object( \$_ )->FLAGS;
    if ( $flags & B::SVp_IOK && !( $flags & B::SVp_NOK ) ) {
        return 0 != ( $_ % 2 );
    }
    return /\A\s*$Odd\s*\z/;
}


our %representation = (
     "infinity" =>  "inf",
    "-infinity" => "-inf",
     "nan"      =>  "nan",
);


sub representation {
    local $_ = shift if @_ % 2;
    return undef unless defined;
    return undef if ref;

    my %repr = ( %representation, @_ );

    return nan($_)                    ? $repr{"nan"}
        : infinity($_) ? positive($_) ? $repr{"infinity"}
                       :                $repr{"-infinity"}
        : exists( $repr{$_} )         ? $repr{$_}
        :                               $_
        ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LooksLike - See if a number looks like a number, integer, numeric, infinity, not-a-number, zero, non-zero, positive, negative, even, or odd.

=head1 SYNOPSIS

    use LooksLike;

    printf( "%5s|%6s|%3s|%3s|%3s|%7s|%4s|%7s|%3s|%3s|%4s|%3s\n",
        "",
        qw(
            Number Inf NaN
            Int    Numeric
            Zero   NonZero
            Pos    Neg
            Even   Odd
        )
    );
    for ( qw( -inf -1 -.23 0 0.0 0e0 .23 1 inf -nan ),
        -1e9999, -1, -0.23, 0, 0.23, 1e9999, 1e9999/1e9999 )
    {
        printf( "%5s|%6d|%3d|%3d|%3d|%7d|%4d|%7d|%3d|%3d|%4d|%3d\n",
            $_,
            0+ LooksLike::number(),
            0+ LooksLike::infinity(),
            0+ LooksLike::nan(),
            0+ LooksLike::integer(),
            0+ LooksLike::numeric(),
            0+ LooksLike::zero(),
            0+ LooksLike::nonzero(),
            0+ LooksLike::positive(),
            0+ LooksLike::negative(),
            0+ LooksLike::even(),
            0+ LooksLike::odd(),
        );
    }
    #      |Number|Inf|NaN|Int|Numeric|Zero|NonZero|Pos|Neg|Even|Odd
    #  -inf|     1|  1|  0|  0|      0|   0|      1|  0|  1|   0|  0
    #    -1|     1|  0|  0|  1|      1|   0|      1|  0|  1|   0|  1
    #  -.23|     1|  0|  0|  0|      1|   0|      1|  0|  1|   0|  0
    #     0|     1|  0|  0|  1|      1|   1|      0|  0|  0|   1|  0
    #   0.0|     1|  0|  0|  0|      1|   1|      0|  0|  0|   0|  0
    #   0e0|     1|  0|  0|  0|      1|   1|      0|  0|  0|   0|  0
    #   .23|     1|  0|  0|  0|      1|   0|      1|  1|  0|   0|  0
    #     1|     1|  0|  0|  1|      1|   0|      1|  1|  0|   0|  1
    #   inf|     1|  1|  0|  0|      0|   0|      1|  1|  0|   0|  0
    #  -nan|     1|  0|  1|  0|      0|   0|      0|  0|  0|   0|  0
    #  -inf|     1|  1|  0|  0|      0|   0|      1|  0|  1|   0|  0
    #    -1|     1|  0|  0|  1|      1|   0|      1|  0|  1|   0|  1
    # -0.23|     1|  0|  0|  0|      1|   0|      1|  0|  1|   0|  0
    #     0|     1|  0|  0|  1|      1|   1|      0|  0|  0|   1|  0
    #  0.23|     1|  0|  0|  0|      1|   0|      1|  1|  0|   0|  0
    #   inf|     1|  1|  0|  0|      0|   0|      1|  1|  0|   0|  0
    #   nan|     1|  0|  1|  0|      0|   0|      1|  0|  0|   0|  0

=head1 DESCRIPTION

The module L<Scalar::Util> has a useful function called C<looks_like_number>,
but it doesn't tell you what kind of number it is, and it also considers
C<NaN> and C<Infinity> as numbers, which isn't always what you want.  This
attempts to be a lot more flexible about letting you ask what kind of number
you have, and lets you decide how to handle that.

The module asks Perl about the value being held in the scalar, and if it
has an integer or numeric value, it uses that for comparisons, otherwise
it performs the test with a regular expression.  This methodology should
be more efficient for values that have been converted to a numeric value.

All of the functions will use C<$_> if there is no parameter given.

=head2 Regexp Only Functions

The following functions work only on strings,
as evaluating them numerially doesn't make sense:
C<binary()>, C<octal()>, C<hex()>, C<decimal()>, and C<grok_number()>.

=head2 Numeric or Regexp Functions

The following functions operate on the numeric values, if they exist,
otherwise they fall back to the regular expression equivalent:
C<number()>, C<integer()>,
C<numeric()>, C<comparable()>,
C<infinity()>, C<nan()>,
C<zero()>, C<nonzero()>,
C<positive()>, C<negative()>,
C<even()>, and C<odd()>.

=head2 Regular Expressions

There are numerous regular expressions available,
if you'd like to search for numbers of a particular format:
C<$Binary>, C<$Octal>, C<$Hex>, C<$Decimal>,
C<$Infinity>, C<$NaN>,
C<$Integer>, C<$Numeric>,
C<$Zero>, C<$Nonzero>,
C<$Positive>, C<$Negative>,
C<$Even>, and C<$Odd>.

=head1 VARIABLES

=head2 C<$Binary>

A zero character, followed by a "B" (ignoring case),
followed by a series of zero and one characters

=head2 C<$Octal>

A zero character, followed by a series of zero through seven characters.

=head2 C<$Hex>

A zero character, followed by an "X" (ignoring case),
followed by a series of zero through nine characters
and/or "A" through "F" characters (ignoring case).

=head2 C<$Decimal>

A series of zero through nine characters,
possibly separated by a single period.

=head2 C<$Infinity>

The case insensitive words "inf" and "infinity".

Perl version 5.22 and greater recognize a larger set of representations
that include C<"1.#INF">, C<"1.#Infinity">, C<"1.#inf00">, among others.

=head2 C<$NaN>

The case insensitive words "nan".

Perl version 5.22 and greater recognize a larger set of representations
that include
C<"nanq">,        C<"nans">,
C<"qnan">,        C<"snan">,
C<"1.#nans">,     C<"1.#qnan">,
C<"1.#nan(123)">, C<"1.#nan(0x45)">,
among others.

=head2 C<$Integer>

A series of digits.

=head2 C<$Numeric>

Anything which would be recognized as an integer or floating point number.

=head2 C<$Zero>

Anything which would be regarded as equal to 0.

=head2 C<$NonZero>

Anything which looks like a number, but is not 0.

=head2 C<$Positive>

Any number that would compare to greater than 0.

=head2 C<$Negative>

Any number that would compare to less than 0.

=head2 C<$Even>

Any integer which would divide evenly by 2.

=head2 C<$Odd>

Any integer which would divde oddly by 2.

=head2 C<%representation>

The hash used by L<representation( $_ ; %representation )> to
format various numeric representations.  Has three fields:

=over

=item C<infinity>

How positive infinity should be represented.  Defaults to C<inf>.

=item C<-infinity>

How negative infinity should be represented.  Defaults to C<-inf>.

=item C<nan>

How not-a-number should be represented.  Defaults to C<nan>.

=back

=head1 FUNCTIONS

=head2 C<binary($_)>

Returns true if the string starts with C<0b> and finishes with a series of
C<0> and C<1> digits.

=head2 C<octal($_)>

Returns true if the string starts with C<0> and finishes with a series of
C<0> through C<7> digits.

=head2 C<hex($_)>

Returns true if the string starts with C<0x> and finishes with a series of
C<0> through C<9> or C<a> through C<f> digits.

=head2 C<decimal($_)>

Returns true if the string looks like a floating point number without
the C<E> exponent portion.

=head2 C<grok_number($_)>

A pure Perl representation of the internal function of the same name.
Returns 6 items:

=over

=item sign

Any leading C<+> or C<-> sign, or the empty string if there was
no leading sign.

=item number

The whole part of the number, before the dot, if there is one.
Could be the empty string.  If it was an unsuccesful parse, could be C<undef>.
Could also be some form of C<NaN>, C<IND>, C<inf>, or C<Infinity>.

=item fraction

The fractional part of the number, after the dot, if there is one.
Could be the empty string or C<undef>.

It should not be possible for the number and fraction to both
be the empty string.

=item exponent sign

Any leading C<+> or C<-> sign in the exponent,
or the empty string if there was no leading sign.
Could be the empty string or C<undef>.

=item exponent number

The digits representing the exponent.
Could be C<undef>.

=item excess

If there was any part of the string that remained unparsed, it is returned
as this substring.  In a complete parse, it is the empty string.

=back

=head2 C<infinity($_)>

Returns a true value if the value represents some form of infinity.
The strings C<infinity> and C<inf> are both valid (case-insensitively).

=head2 C<nan($_)>

Returns a true value if the value represents some form of not-a-number (C<NaN>).
The string C<nan> is valid (case-insensitively).

=head2 C<integer($_)>

Returns true if the value is a series of ASCII digits C<0> through C<9>.
Does not guarantee that the number will fit into any number of bits.

=head2 C<numeric($_)>

Returns true for any representation of a floating point number,
which includes integers.
It does not include the representations of C<inf> and C<nan>.

=head2 C<comparable($_)>

Returns true for any representation of a number that can be compared to
another number.  In other words: true for infinity, integers,
and floating point numbers; false for not-a-number, and anything else.

=head2 C<number($_)>

Equivalent to L<Scalar::Util/looks_like_number>, and returns true for
all representations of infinity, not-a-number, integer, and floating point
numbers.

=head2 C<zero($_)>

Returns true for any value that would be interepreted equal (C<==>) to 0.

=head2 C<nonzero($_)>

Returns true for any value that would be interepreted not equal (C<!=>) to 0.

=head2 C<positive($_)>

Returns true for any value that would be interpreted as greater than
(C<< > >>) 0.

=head2 C<negative($_)>

Returns true for any value that would be interpreted as less than
(C<< < >>) 0.

=head2 C<even($_)>

Returns true for any integer that would have no remainder when modulused
with 2.

=head2 C<odd($_)>

Returns true for any integer that would have a remainder when modulused
with 2.

=head2 C<representation( $_ ; %representation )>

Condense the large set of representations for infinity and not-a-number
to a simple set.  Pass in a value (or use C<$_> if nothing is passed in),
and if it's something that matches positive infinity, negative infinity,
or not-a-number, then format it as the L<C<%representation>> hash indicates.

The keys and values to override the C<%representation> hash can be passed in,
and the values will be used in place of the defaults.

Since v0.20.056.

=head1 TODO

Nothing, my code is perfect.
Please let me know if you think that statement is incorrect.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/LooksLike/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 VERSION

This document describes version v0.20.060 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
