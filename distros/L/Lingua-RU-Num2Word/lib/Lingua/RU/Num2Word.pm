package Lingua::RU::Num2Word;

use strict;
use warnings;
use utf8;
use POSIX qw/floor/;
use Carp qw/croak/;

# ABSTRACT: Numbers to words in russian (without currency, but with specified gender)
our $VERSION = '0.05'; # VERSION
# AUTHORITY

use Exporter qw/import/;
our @EXPORT_OK = qw(&num2rus_cardinal);

my %diw = (
    0 => {
        0  => { 0 => "ноль",                 1 => 1 },
        1  => { 0 => "",                         1 => 2 },
        2  => { 0 => "",                         1 => 3 },
        3  => { 0 => "три",                   1 => 0 },
        4  => { 0 => "четыре",             1 => 0 },
        5  => { 0 => "пять",                 1 => 1 },
        6  => { 0 => "шесть",               1 => 1 },
        7  => { 0 => "семь",                 1 => 1 },
        8  => { 0 => "восемь",             1 => 1 },
        9  => { 0 => "девять",             1 => 1 },
        10 => { 0 => "десять",             1 => 1 },
        11 => { 0 => "одиннадцать",     1 => 1 },
        12 => { 0 => "двенадцать",     1 => 1 },
        13 => { 0 => "тринадцать",     1 => 1 },
        14 => { 0 => "четырнадцать", 1 => 1 },
        15 => { 0 => "пятнадцать",     1 => 1 },
        16 => { 0 => "шестнадцать",   1 => 1 },
        17 => { 0 => "семнадцать",     1 => 1 },
        18 => { 0 => "восемнадцать", 1 => 1 },
        19 => { 0 => "девятнадцать", 1 => 1 },
    },

    1 => {
        2 => { 0 => "двадцать",       1 => 1 },
        3 => { 0 => "тридцать",       1 => 1 },
        4 => { 0 => "сорок",             1 => 1 },
        5 => { 0 => "пятьдесят",     1 => 1 },
        6 => { 0 => "шестьдесят",   1 => 1 },
        7 => { 0 => "семьдесят",     1 => 1 },
        8 => { 0 => "восемьдесят", 1 => 1 },
        9 => { 0 => "девяносто",     1 => 1 },
    },
    2 => {
        1 => { 0 => "сто",             1 => 1 },
        2 => { 0 => "двести",       1 => 1 },
        3 => { 0 => "триста",       1 => 1 },
        4 => { 0 => "четыреста", 1 => 1 },
        5 => { 0 => "пятьсот",     1 => 1 },
        6 => { 0 => "шестьсот",   1 => 1 },
        7 => { 0 => "семьсот",     1 => 1 },
        8 => { 0 => "восемьсот", 1 => 1 },
        9 => { 0 => "девятьсот", 1 => 1 }
      }

);

my %nom = (
    0 => { 0 => "",             1 => "",           2 => "одна",              3 => "две" },
    1 => { 0 => "",             1 => "",           2 => "один",              3 => "два" },
    2 => { 0 => "тысячи", 1 => "тысяч", 2 => "одна тысяча", 3 => "две тысячи" },
    3 => {
        0 => "миллиона",
        1 => "миллионов",
        2 => "один миллион",
        3 => "два миллиона"
    },
    4 => {
        0 => "миллиарда",
        1 => "миллиардов",
        2 => "один миллиард",
        3 => "два миллиарда"
    },
    5 => {
        0 => "триллиона",
        1 => "триллионов",
        2 => "один триллион",
        3 => "два триллиона"
    }
);

my %genders = (
    'FEMININE' => { 0 => "", 1 => "", 2 => "одна", 3 => "две" },
    'MASCULINE' => { 0 => "", 1 => "", 2 => "один", 3 => "два" },
    'NEUTER' => { 0 => "", 1 => "", 2 => "одно", 3 => "два" },
);

# Stolen from Lingua::RU::Number


sub num2rus_cardinal {
    my ( $number, $gender ) = @_;

    # The biggest number we know about
    if ($number > 999_999_999_999_999 ) {
        return '';
    }

    $gender ||= 'MASCULINE';    # masculine by default
    croak "Wrong gender: $gender, should be MASCULINE|FEMININE|NEUTER" unless $gender =~ /masculine|feminine|neuter/i;
    $gender = uc $gender;

    return _get_string( 0, 0, 0 ) unless $number;    # no extra calculations for zero

    my ( $result, $negative );

    # Negative number, just add another word
    if ( $number < 0 ) {
        $number   = abs( $number );
        $negative = 1;
    }

    $result = "";
    my $int_number = floor( $number );              # no doubles

    for ( my $i = 1 ; $i < 6 && $int_number >= 1 ; $i++ ) {
        my $tmp_number = $int_number / 1000;
        my $number_part = sprintf( "%0.3f", $tmp_number - sprintf( "%d", $tmp_number ) ) * 1000;

        $int_number = floor $tmp_number;
        # no doubles again
        $result = _get_string( $number_part, $i, $gender ) . " " . $result;
    }

    # Clean the result
    $result =~ s/\s+/ /g;
    $result =~ s/\s+$//;

    if ( $negative ) {
        $result = "минус $result";
    }

    return $result;
}

sub _get_string {
    my $sum     = shift;
    return unless defined $sum;

    my $nominal = shift;
    my $gender  = shift;
    my ( $result, $nom ) = ( '', -1 );

    if ( ( !$nominal && $sum < 100 ) || ( $nominal > 0 && $nominal < 6 && $sum < 1000 ) ) {
        my $s2 = sprintf( "%d", $sum / 100 );

        if ( $s2 > 0 ) {    # hundreds
            $result .= ' ' . $diw{2}{$s2}{0};
            $nom = $diw{2}{$s2}{1};
        }

        my $sx = $sum - $s2 * 100;

        if ( ( $sx < 20 && $sx > 0 ) || ( $sx == 0 && !$nominal ) ) {
            $result .= " " . $diw{0}{$sx}{0};
            $nom = $diw{0}{$sx}{1};
        }
        else {
            my $s1 = floor $sx / 10;    # tens

            my $s0 = sprintf( "%d", $sum - $s2 * 100 - $s1 * 10 + 0.5 );

            if ( $s1 > 0 ) {
                $result .= ' ' . $diw{1}{$s1}{0};
                $nom = $diw{1}{$s1}{1};
            }
            if ( $s0 > 0 ) {
                $result .= ' ' . $diw{0}{$s0}{0};
                $nom = $diw{0}{$s0}{1};
            }
        }
    }

    if ( $nom >= 0 ) {

        if ( $nominal == 1 ) {
            $result .= defined $nominal ? ' ' . $genders{$gender}{$nom} : '';
        }
        else {
            $result .= defined $nominal ? ' ' . $nom{$nominal}{$nom} : '';
        }
    }
    $result =~ s/^\s*//g;
    $result =~ s/\s*$//g;

    return $result;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::RU::Num2Word - Numbers to words in russian (without currency, but with specified gender)

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Lingua::RU::Num2Word qw/num2rus_cardinal/;
    print num2rus_cardinal(21, 'NEUTER'); # двадцать одно

=head2 num2rus_cardinal( $number, $gender )

Translates number to text converter for russian, using the specified gender. Returns Unicode string.
Main code was taken from L<Lingua::RUS::Number>.

$gender

    Can be

        FEMININE
        MASCULINE
        NEUTER

    use Lingua::RU::Num2Word qw/num2rus_cardinal/;
    my $text = num2rus_cardinal(561); # outputs пятьсот шестьдесят один


    my $bottles_on_wall = 22;
    print num2rus_cardinal($bottles_on_wall, 'FEMININE') . " бутылки пива на стене"; # outputs "двадцать две бутылки пива на стене"
    $bottles_on_wall --;
    print num2rus_cardinal($bottles_on_wall, 'FEMININE') . " бутылка пива на стене"; # outputs "двадцать одна бутылка пива на стене"

=head1 ORIGINAL MODULE L<Lingua::RUS::Number>

    fork coding, maintenance, refactoring, extensions:  Richard C. Jelinek <info@petamem.com>
    initial coding:  Vladislav A. Safronov, E<lt>F<vlads@yandex-team.ru>E<gt>, E<lt>F<vlad@yandex.ru>E<gt>

=head1 AUTHOR

Polina Shubina <925043@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
