package Lingua::EN::Fractions;
$Lingua::EN::Fractions::VERSION = '0.08';
use 5.008;
use strict;
use warnings;
use utf8;

use parent 'Exporter';
use Lingua::EN::Numbers qw/ num2en num2en_ordinal /;

our @EXPORT_OK = qw/ fraction2words /;

my %special_denominators =
(
    2 => { singular => 'half',    plural => 'halve'   },
    4 => { singular => 'quarter', plural => 'quarter' },
);

my %unicode =
(
    '¼' => '1/4',
    '½' => '1/2',
    '¾' => '3/4',
    '⅓' => '1/3',
    '⅔' => '2/3',
    '⅕' => '1/5',
    '⅖' => '2/5',
    '⅗' => '3/5',
    '⅘' => '4/5',
    '⅙' => '1/6',
    '⅚' => '5/6',
    '⅛' => '1/8',
    '⅜' => '3/8',
    '⅝' => '5/8',
    '⅞' => '7/8',
    '⁄' => '/',     # FRACTION SLASH (U+2044)
    '−' => '-',     # MINUS SIGN (U+2212)
);
my $unicode_regexp = join('|', keys %unicode);

sub fraction2words
{
    my $number = shift;
    my $fraction = qr|
                        ^
                        (\s*-)?
                        (\s*([0-9]+)\s+)?
                        \s*
                        ([0-9]+)
                        \s*
                        /
                        \s*
                        ([0-9]+)
                        \s*
                        $
                     |x;

    $number =~ s/($unicode_regexp)/ $unicode{$1}/g;

    if (my ($negate, $preamble, $wholepart, $numerator, $denominator) = $number =~ $fraction) {
        my $denominator_as_words = do {
            if (exists $special_denominators{$denominator}) {
                if ($numerator == 1) {
                    $special_denominators{ $denominator }->{singular};
                }
                else {
                    $special_denominators{ $denominator }->{plural};
                }
            }
            else {
                num2en_ordinal($denominator);
            }
        };
        my $numerator_as_words = do {
            if ($numerator == 1 && $wholepart) {
                # "1 1/2" -> "one and *a* half"
                # "1 1/8" -> "one and *an* eighth"
                $denominator_as_words =~ /^[aeiou]/i ? 'an' : 'a';
            }
            else {
                num2en($numerator);
            }
        };
        my $phrase = '';
        
        $phrase .= 'minus ' if $negate;
        $phrase .= num2en($wholepart).' and ' if $wholepart;
        $phrase .= "$numerator_as_words $denominator_as_words";
        $phrase .= 's' if $numerator > 1;
        return $phrase;
    }

    return undef;
}

1;

=encoding utf8

=head1 NAME

Lingua::EN::Fractions - convert "3/4" into "three quarters", etc

=head1 SYNOPSIS

 use Lingua::EN::Fractions qw/ fraction2words /;

 my $fraction = '3/4';
 my $as_words = fraction2words($fraction);

Or using L<Number::Fraction>:

 use Number::Fraction;

 my $fraction = Number::Fraction->new(2, 7);
 my $as_words = fraction2words($fraction);

=head1 DESCRIPTION

This module provides a function, C<fraction2words>,
which takes a string containing a fraction and returns
the English phrase for that fraction.
If no fraction was found in the input, then C<undef> is returned.

For example

 fraction2words('1/2');    # "one half"
 fraction2words('3/4');    # "three quarters"
 fraction2words('5/17');   # "five seventeenths"
 fraction2words('5');      # undef
 fraction2words('-3/5');   # "minus three fifths"

You can also pass a whole number ahead of the fraction:

 fraction2words('1 1/2');  # "one and a half"
 fraction2words('-1 1/8'); # "minus one and an eighth"
 fraction2words('12 3/4'); # "twelve and three quarters"

Note that instead of "one and one half",
you'll get back "one and a half".

=head2 Unicode fraction characters

As of version 0.05,
certain Unicode characters are also supported.  For example:

 fraction2words('½')        # "one half"
 fraction2words('1⅜')       # "one and three eighths"
 fraction2words('-1⅘')      # "minus one and four fifths"

You can also use the Unicode FRACTION SLASH, which is a different
character from the regular slash:

 fraction2words('1/2')      # "one half"
 fraction2words('1⁄2')      # "one half"

As of version 0.06, you an also use the Unicode MINUS SIGN:

 fraction2words('−1/2')    # "minus one half"
 fraction2words('−⅘')      # "minus four fifths"

At the moment, the DIVISION SLASH character isn't handled.
Feel free to tell me if you think I got that wrong.

=head2 Working with Number::Fraction

You can also pass in a fraction represented using L<Number::Fraction>:

 $fraction = Number::Fraction->new(2, 7);
 $as_words = fraction2words($fraction);    # "two sevenths"

=head1 CAVEATS

At the moment, no attempt is made to simplify the fraction,
so C<'5/2'> will return "five halves" rather than "two and a half".
Note though, that if you're using L<Number::Fraction>, then it
does normalise fractions, so "3/6" will become "1/2".

At the moment it's not very robust to weird inputs.

=head1 SEE ALSO

L<Lingua::EN::Numbers>,
L<Lingua::EN::Numbers::Ordinate>,
L<Lingua::EN::Numbers::Years> - other modules for converting numbers
into words.

L<Number::Fraction> - a class for representing fractions and
operations on them.

=head1 REPOSITORY

L<https://github.com/neilb/Lingua-EN-Fractions>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

This module was suggested by Sean Burke, who created the
other C<Lingua::EN::*> modules that I now maintain.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
