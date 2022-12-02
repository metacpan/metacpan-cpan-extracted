package Locale::Babelfish::Phrase::Pluralizer;

# ABSTRACT: Babelfish pluralizer.

use utf8;
use strict;
use warnings;

use List::Util qw( first );

our $VERSION = '2.10'; # VERSION


my %rules;


sub add {
    my ( $locales, $rule ) = @_;
    $locales = [ $locales ]  unless ref($locales);

    $rules{$_} = $rule  for @$locales;
}


sub find_rule {
    my ( $locale ) = @_;

    $locale = ( first {
        $locale =~ m/\A\Q$_\E[\-_]/s
    } keys %rules ) // 'en'
        unless $rules{$locale};

    return $rules{$locale};
}


sub is_int {
    my ( $input ) = @_;
    return (0 == $input % 1);
}

## PLURALIZATION RULES
## https://github.com/nodeca/babelfish/blob/master/lib/babelfish/pluralizer.js#L51

# Azerbaijani, Bambara, Burmese, Chinese, Dzongkha, Georgian, Hungarian, Igbo,
# Indonesian, Japanese, Javanese, Kabuverdianu, Kannada, Khmer, Korean,
# Koyraboro Senni, Lao, Makonde, Malay, Persian, Root, Sakha, Sango,
# Sichuan Yi, Thai, Tibetan, Tonga, Turkish, Vietnamese, Wolof, Yoruba

add(['az', 'bm', 'my', 'zh', 'dz', 'ka', 'hu', 'ig',
    'id', 'ja', 'jv', 'kea', 'kn', 'km', 'ko',
    'ses', 'lo', 'kde', 'ms', 'fa', 'root', 'sah', 'sg',
    'ii',  'th', 'bo', 'to', 'tr', 'vi', 'wo', 'yo'
], sub {
    return 0;
});

# Manx

add(['gv'], sub {
    my ( $n ) = @_;
    my ($m10, $m20) = ($n % 10, $n % 20);

    if (($m10 == 1 || $m10 == 2 || $m20 == 0) && is_int($n)) {
        return 0;
    }

    return 1;
});


# Central Morocco Tamazight

add(['tzm'],  sub {
    my ( $n ) = @_;
    if ($n == 0 || $n == 1 || (11 <= $n && $n <= 99 && is_int($n))) {
        return 0;
    }

    return 1;
});


# Macedonian

add(['mk'], sub {
    my ( $n ) = @_;
    if (($n % 10 == 1) && ($n != 11) && is_int($n)) {
        return 0;
    }

    return 1;
});


# Akan, Amharic, Bihari, Filipino, Gun, Hindi,
# Lingala, Malagasy, Northern Sotho, Tagalog, Tigrinya, Walloon

add(['ak', 'am', 'bh', 'fil', 'guw', 'hi',
  'ln', 'mg', 'nso', 'tl', 'ti', 'wa'
], sub {
    my ( $n ) = @_;
    return ($n == 0 || $n == 1) ? 0 : 1;
});


# Afrikaans, Albanian, Basque, Bemba, Bengali, Bodo, Bulgarian, Catalan,
# Cherokee, Chiga, Danish, Divehi, Dutch, English, Esperanto, Estonian, Ewe,
# Faroese, Finnish, Friulian, Galician, Ganda, German, Greek, Gujarati, Hausa,
# Hawaiian, Hebrew, Icelandic, Italian, Kalaallisut, Kazakh, Kurdish,
# Luxembourgish, Malayalam, Marathi, Masai, Mongolian, Nahuatl, Nepali,
# Norwegian, Norwegian Bokmål, Norwegian Nynorsk, Nyankole, Oriya, Oromo,
# Papiamento, Pashto, Portuguese, Punjabi, Romansh, Saho, Samburu, Soga,
# Somali, Spanish, Swahili, Swedish, Swiss German, Syriac, Tamil, Telugu,
# Turkmen, Urdu, Walser, Western Frisian, Zulu

add(['af', 'sq', 'eu', 'bem', 'bn', 'brx', 'bg', 'ca',
  'chr', 'cgg', 'da', 'dv', 'nl', 'en', 'eo', 'et', 'ee',
  'fo', 'fi', 'fur', 'gl', 'lg', 'de', 'el', 'gu', 'ha',
  'haw', 'he', 'is', 'it', 'kl', 'kk', 'ku',
  'lb', 'ml', 'mr', 'mas', 'mn', 'nah', 'ne',
  'no', 'nb', 'nn', 'nyn', 'or', 'om',
  'pap', 'ps', 'pt', 'pa', 'rm', 'ssy', 'saq', 'xog',
  'so', 'es', 'sw', 'sv', 'gsw', 'syr', 'ta', 'te',
  'tk', 'ur', 'wae', 'fy', 'zu'
], sub {
    my ( $n ) = @_;
    return (1 == $n) ? 0 : 1;
});


# Latvian

add(['lv'], sub {
    my ( $n ) = @_;
    if ($n == 0) {
        return 0;
    }

    if (($n % 10 == 1) && ($n % 100 != 11) && is_int($n)) {
        return 1;
    }

    return 2;
});


# Colognian

add(['ksh'], sub {
    my ( $n ) = @_;
    return ($n == 0) ? 0 : (($n == 1) ? 1 : 2);
});


# Cornish, Inari Sami, Inuktitut, Irish, Lule Sami, Northern Sami,
# Sami Language, Skolt Sami, Southern Sami

add(['kw', 'smn', 'iu', 'ga', 'smj', 'se',
  'smi', 'sms', 'sma'
], sub {
    my ( $n ) = @_;
    return ($n == 1) ? 0 : (($n == 2) ? 1 : 2);
});


# Belarusian, Bosnian, Croatian, Russian, Serbian, Serbo-Croatian, Ukrainian

add(['be', 'bs', 'hr', 'ru', 'sr', 'sh', 'uk'], sub {
    my ( $n ) = @_;
    my ($m10, $m100) = ($n % 10, $n % 100);

    if (!is_int($n)) {
        return 3;
    }

    # one → n mod 10 is 1 and n mod 100 is not 11;
    if (1 == $m10 && 11 != $m100) {
        return 0;
    }

    # few → n mod 10 in 2..4 and n mod 100 not in 12..14;
    if (2 <= $m10 && $m10 <= 4 && !(12 <= $m100 && $m100 <= 14)) {
        return 1;
    }

    ## many → n mod 10 is 0 or n mod 10 in 5..9 or n mod 100 in 11..14;
    ##  if (0 === m10 || (5 <= m10 && m10 <= 9) || (11 <= m100 && m100 <= 14)) {
    ##   return 2;
    ## }

    ## other
    ## return 3;
    return 2;
});


# Polish

add(['pl'], sub {
    my ( $n ) = @_;
    my ($m10, $m100) = ($n % 10, $n % 100);

    if (!is_int($n)) {
        return 3;
    }

    # one → n is 1;
    if ($n == 1) {
        return 0;
    }

    # few → n mod 10 in 2..4 and n mod 100 not in 12..14;
    if (2 <= $m10 && $m10 <= 4 && !(12 <= $m100 && $m100 <= 14)) {
        return 1;
    }

    # many → n is not 1 and n mod 10 in 0..1 or
    # n mod 10 in 5..9 or n mod 100 in 12..14
    # (all other except partials)
    return 2;
});


# Lithuanian

add(['lt'], sub {
    my ( $n ) = @_;
    my ($m10, $m100) = ($n % 10, $n % 100);

    if (!is_int($n)) {
        return 2;
    }

    # one → n mod 10 is 1 and n mod 100 not in 11..19
    if ($m10 == 1 && !(11 <= $m100 && $m100 <= 19)) {
        return 0;
    }

    # few → n mod 10 in 2..9 and n mod 100 not in 11..19
    if (2 <= $m10 && $m10 <= 9 && !(11 <= $m100 && $m100 <= 19)) {
        return 1;
    }

    # other
    return 2;
});


# Tachelhit

add(['shi'], sub {
    my ( $n ) = @_;
    return (0 <= $n && $n <= 1) ? 0 : ((is_int($n) && 2 <= $n && $n <= 10) ? 1 : 2);
});


# Moldavian, Romanian

add(['mo', 'ro'], sub {
    my ( $n ) = @_;
    my $m100 = $n % 100;

    if (!is_int($n)) {
        return 2;
    }

    # one → n is 1
    if ($n == 1) {
        return 0;
    }

    # few → n is 0 OR n is not 1 AND n mod 100 in 1..19
    if ($n == 0 || (1 <= $m100 && $m100 <= 19)) {
        return 1;
    }

    # other
    return 2;
});


## Czech, Slovak

add(['cs', 'sk'], sub {
    my ( $n ) = @_;
    # one → n is 1
    if ($n == 1) {
        return 0;
    }

    # few → n in 2..4
    if ($n == 2 || $n == 3 || $n == 4) {
        return 1;
    }

    # other
    return 2;
});



# Slovenian

add(['sl'], sub {
    my ( $n ) = @_;
    my $m100 = $n % 100;

    if (!is_int($n)) {
        return 3;
    }

    # one → n mod 100 is 1
    if ($m100 == 1) {
        return 0;
    }

    # one → n mod 100 is 2
    if ($m100 == 2) {
        return 1;
    }

    # one → n mod 100 in 3..4
    if ($m100 == 3 || $m100 == 4) {
        return 2;
    }

    # other
    return 3;
});


# Maltese

add(['mt'], sub {
    my ( $n ) = @_;
    my $m100 = $n % 100;

    if (!is_int($n)) {
        return 3;
    }

    # one → n is 1
    if ($n == 1) {
        return 0;
    }

    # few → n is 0 or n mod 100 in 2..10
    if ($n == 0 || (2 <= $m100 && $m100 <= 10)) {
        return 1;
    }

    # many → n mod 100 in 11..19
    if (11 <= $m100 && $m100 <= 19) {
        return 2;
    }

    # other
    return 3;
});


# Arabic

add(['ar'], sub {
    my ( $n ) = @_;
    my $m100 = $n % 100;

    if (!is_int($n)) {
        return 5;
    }

    if ($n == 0) {
        return 0;
    }
    if ($n == 1) {
        return 1;
    }
    if ($n == 2) {
        return 2;
    }

    # few → n mod 100 in 3..10
    if (3 <= $m100 && $m100 <= 10) {
        return 3;
    }

    # many → n mod 100 in 11..99
    if (11 <= $m100 && $m100 <= 99) {
        return 4;
    }

    # other
    return 5;
});


# Breton, Welsh

add(['br', 'cy'], sub {
    my ( $n ) = @_;
    if ($n == 0) {
        return 0;
    }
    if ($n == 1) {
        return 1;
    }
    if ($n == 2) {
        return 2;
    }
    if ($n == 3) {
        return 3;
    }
    if ($n == 6) {
        return 4;
    }

    return 5;
});


## FRACTIONAL PARTS - SPECIAL CASES

# French, Fulah, Kabyle

add(['fr', 'ff', 'kab'], sub {
    my ( $n ) = @_;
    return (0 <= $n && $n < 2) ? 0 : 1;
});


# Langi

add(['lag'], sub {
    my ( $n ) = @_;
    return ($n == 0) ? 0 : ((0 < $n && $n < 2) ? 1 : 2);
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Pluralizer - Babelfish pluralizer.

=head1 VERSION

version 2.10

=head1 DESCRIPTION

Pluralization implementation.

=head1 METHODS

=head2 add

Adds locale pluralization rule. Should not be called directly.

=head2 find_rule

    find_rule( $locale )

Finds locale pluralization rule. It is coderef.

=head2 is_int

    is_int( $input )

Check if number is int or float.

=head1 AUTHORS

=over 4

=item *

Akzhan Abdulin <akzhan@cpan.org>

=item *

Igor Mironov <grif@cpan.org>

=item *

Victor Efimov <efimov@reg.ru>

=item *

REG.RU LLC

=item *

Kirill Sysoev <k.sysoev@me.com>

=item *

Alexandr Tkach <tkach@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by REG.RU LLC.

This is free software, licensed under:

  The MIT (X11) License

=cut
