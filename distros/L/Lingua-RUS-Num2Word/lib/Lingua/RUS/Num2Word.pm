# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
#
# (c) 2002-2010 PetaMem, s.r.o.
#

package Lingua::RUS::Num2Word;
# ABSTRACT: Converts numbers to money sum in words (in Russian roubles)

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ variables declaration
our $VERSION = '0.2603300';

# Preloaded methods go here.
use vars qw(%diw %nom);

%diw = (
    0 => {
        0  => { 0 => "ноль",         1 => 1},
        1  => { 0 => "",             1 => 2},
        2  => { 0 => "",             1 => 3},
        3  => { 0 => "три",          1 => 0},
        4  => { 0 => "четыре",       1 => 0},
        5  => { 0 => "пять",         1 => 1},
        6  => { 0 => "шесть",        1 => 1},
        7  => { 0 => "семь",         1 => 1},
        8  => { 0 => "восемь",       1 => 1},
        9  => { 0 => "девять",       1 => 1},
        10 => { 0 => "десять",       1 => 1},
        11 => { 0 => "одинадцать",   1 => 1},
        12 => { 0 => "двенадцать",   1 => 1},
        13 => { 0 => "тринадцать",   1 => 1},
        14 => { 0 => "четырнадцать", 1 => 1},
        15 => { 0 => "пятнадцать",   1 => 1},
        16 => { 0 => "шестнадцать",  1 => 1},
        17 => { 0 => "семнадцать",   1 => 1},
        18 => { 0 => "восемнадцать", 1 => 1},
        19 => { 0 => "девятнадцать", 1 => 1},
    },
    1 => {
        2  => { 0 => "двадцать",    1 => 1},
        3  => { 0 => "тридцать",    1 => 1},
        4  => { 0 => "сорок",       1 => 1},
        5  => { 0 => "пятьдесят",   1 => 1},
        6  => { 0 => "шестьдесят",  1 => 1},
        7  => { 0 => "семьдесят",   1 => 1},
        8  => { 0 => "восемьдесят", 1 => 1},
        9  => { 0 => "девяносто",   1 => 1},
    },
    2 => {
        1  => { 0 => "сто",       1 => 1},
        2  => { 0 => "двести",    1 => 1},
        3  => { 0 => "триста",    1 => 1},
        4  => { 0 => "четыреста", 1 => 1},
        5  => { 0 => "пятьсот",   1 => 1},
        6  => { 0 => "шестьсот",  1 => 1},
        7  => { 0 => "семьсот",   1 => 1},
        8  => { 0 => "восемьсот", 1 => 1},
        9  => { 0 => "девятьсот", 1 => 1}
    }
);

%nom = (
    0  =>  {0 => "копейки",  1 => "копеек",    2 => "одна копейка", 3 => "две копейки"},
    1  =>  {0 => "рубля",    1 => "рублей",    2 => "один рубль",   3 => "два рубля"},
    2  =>  {0 => "тысячи",   1 => "тысяч",     2 => "одна тысяча",  3 => "две тысячи"},
    3  =>  {0 => "миллиона", 1 => "миллионов", 2 => "один миллион", 3 => "два миллиона"},
    4  =>  {0 => "миллиарда",1 => "миллиардов",2 => "один миллиард",3 => "два миллиарда"},
    5  =>  {0 => "триллиона",1 => "триллионов",2 => "один триллион",3 => "два триллиона"}
);

my $out_rub;

# }}}

# {{{ rur_in_words

sub num2rus_cardinal :Export { goto &rur_in_words }

sub rur_in_words :Export {
    my ($sum) = shift // 0;
    my ($retval, $i, $sum_rub, $sum_kop);

    $retval = "";
    $out_rub = ($sum >= 1) ? 0 : 1;
    $sum_rub = sprintf("%d", $sum);
    $sum_rub-- if (($sum_rub - $sum) > 0);
    $sum_kop = sprintf("%0.2f", ($sum - $sum_rub)) * 100;
    my $kop  = get_string($sum_kop, 0);

    for ($i=1; $i<6 && $sum_rub >= 1; $i++) {
        my $sum_tmp  = $sum_rub / 1000;
        my $sum_part = sprintf("%0.3f", $sum_tmp - sprintf("%d", $sum_tmp) ) * 1000;
        $sum_rub     = sprintf("%d", $sum_tmp);

        $sum_rub-- if ($sum_rub - $sum_tmp > 0);
        $retval = get_string($sum_part, $i)." ".$retval;
    }
    $retval .= " рублей" if ($out_rub == 0);
    $retval .= " ".$kop;
    $retval =~ s/\s+/ /g;

    return $retval;
}

# }}}
# {{{ get_string

sub get_string :Export{
    my $sum     = shift // return;
    my $nominal = shift;
    my ($retval, $nom) = ('', -1);

    if ((!$nominal && $sum < 100) || ($nominal > 0 && $nominal < 6 && $sum < 1000)) {
        my $s2 = sprintf("%d", $sum / 100);
        if ($s2 > 0) {
            $retval .= ' '.$diw{2}{$s2}{0};
            $nom = $diw{2}{$s2}{1};
        }
        my $sx = sprintf("%d", $sum - $s2 * 100);
        $sx-- if ($sx - ($sum - $s2*100) > 0);

        if (($sx<20 && $sx>0) || ($sx == 0 && !$nominal)) {
            $retval .= " ".$diw{0}{$sx}{0};
            $nom = $diw{0}{$sx}{1};
        } else {
            my $s1 = sprintf("%d", $sx / 10);
            $s1-- if (($s1 - $sx/10) > 0);
            my $s0 = sprintf("%d", $sum - $s2*100 - $s1*10 + 0.5);
            if ($s1 > 0) {
                $retval .= ' '.$diw{1}{$s1}{0};
                $nom = $diw{1}{$s1}{1};
            }
            if ($s0 > 0) {
                $retval .= ' '.$diw{0}{$s0}{0};
                $nom = $diw{0}{$s0}{1};
            }
        }
    }
    if ($nom >= 0) {
        $retval .= defined $nominal ? ' '.$nom{$nominal}{$nom} : '';
        $out_rub = 1 if (defined $nominal && $nominal == 1);
    }
    $retval =~ s/^\s*//g;
    $retval =~ s/\s*$//g;

    return $retval;
}

# }}}


# {{{ num2rus_ordinal           number to ordinal string conversion

sub num2rus_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-10
    my %irregular = (
        0  => 'нулевой',
        1  => 'первый',
        2  => 'второй',
        3  => 'третий',
        4  => 'четвёртый',
        5  => 'пятый',
        6  => 'шестой',
        7  => 'седьмой',
        8  => 'восьмой',
        9  => 'девятый',
        10 => 'десятый',
    );

    return $irregular{$number} if exists $irregular{$number};

    # Teens ordinals 11-19
    my %teens = (
        11 => 'одиннадцатый',
        12 => 'двенадцатый',
        13 => 'тринадцатый',
        14 => 'четырнадцатый',
        15 => 'пятнадцатый',
        16 => 'шестнадцатый',
        17 => 'семнадцатый',
        18 => 'восемнадцатый',
        19 => 'девятнадцатый',
    );

    return $teens{$number} if exists $teens{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'двадцатый',
        30 => 'тридцатый',
        40 => 'сороковой',
        50 => 'пятидесятый',
        60 => 'шестидесятый',
        70 => 'семидесятый',
        80 => 'восьмидесятый',
        90 => 'девяностый',
    );

    # Cardinal tens (for compound numbers)
    my %tens_card = (
        20 => 'двадцать',
        30 => 'тридцать',
        40 => 'сорок',
        50 => 'пятьдесят',
        60 => 'шестьдесят',
        70 => 'семьдесят',
        80 => 'восемьдесят',
        90 => 'девяносто',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'сотый',
        200 => 'двухсотый',
        300 => 'трёхсотый',
        400 => 'четырёхсотый',
        500 => 'пятисотый',
        600 => 'шестисотый',
        700 => 'семисотый',
        800 => 'восьмисотый',
        900 => 'девятисотый',
    );

    # Cardinal hundreds (for compound numbers)
    my %hundreds_card = (
        100 => 'сто',
        200 => 'двести',
        300 => 'триста',
        400 => 'четыреста',
        500 => 'пятьсот',
        600 => 'шестьсот',
        700 => 'семьсот',
        800 => 'восемьсот',
        900 => 'девятьсот',
    );

    # For numbers >= 1_000_000
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            if ($millions == 1) {
                return 'миллионный';
            }
            return _rus_cardinal($millions) . ' миллионный';
        }
        my $prefix = _rus_cardinal($millions);
        my $tmp4 = $millions % 10;
        my $tmp3 = $millions % 100;
        my $mil_word;
        if ($tmp3 >= 11 && $tmp3 <= 19) {
            $mil_word = 'миллионов';
        }
        elsif ($tmp4 == 1) {
            $mil_word = 'миллион';
        }
        elsif ($tmp4 >= 2 && $tmp4 <= 4) {
            $mil_word = 'миллиона';
        }
        else {
            $mil_word = 'миллионов';
        }
        return $prefix . ' ' . $mil_word . ' ' . num2rus_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            if ($thousands == 1) {
                return 'тысячный';
            }
            return _rus_cardinal($thousands) . ' тысячный';
        }
        my $tmp4 = $thousands % 10;
        my $tmp3 = $thousands % 100;
        my $thou_cardinal;
        if ($thousands == 1) {
            $thou_cardinal = 'тысяча';
        }
        elsif ($thousands == 2) {
            $thou_cardinal = 'две тысячи';
        }
        elsif ($tmp3 >= 11 && $tmp3 <= 19) {
            $thou_cardinal = _rus_cardinal($thousands) . ' тысяч';
        }
        elsif ($tmp4 == 1) {
            $thou_cardinal = _rus_cardinal($thousands - 1) . ' одна тысяча';
        }
        elsif ($tmp4 == 2) {
            $thou_cardinal = _rus_cardinal($thousands - 2) . ' две тысячи';
        }
        elsif ($tmp4 >= 3 && $tmp4 <= 4) {
            $thou_cardinal = _rus_cardinal($thousands) . ' тысячи';
        }
        else {
            $thou_cardinal = _rus_cardinal($thousands) . ' тысяч';
        }
        $thou_cardinal =~ s{^\s+}{};
        return $thou_cardinal . ' ' . num2rus_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        return $hundreds_card{$h} . ' ' . num2rus_ordinal($remainder);
    }

    # 20-99 compound
    if ($number >= 20) {
        my $t = int($number / 10) * 10;
        my $remainder = $number % 10;
        if ($remainder == 0) {
            return $tens_ord{$t};
        }
        return $tens_card{$t} . ' ' . $irregular{$remainder};
    }

    # Should not reach here
    return;
}

# }}}

# {{{ _rus_cardinal             internal: number to cardinal words (for ordinal composition)

sub _rus_cardinal {
    my ($number) = @_;

    return '' if $number == 0;

    my %card_units = (
        1 => 'один',   2 => 'два',     3 => 'три',
        4 => 'четыре', 5 => 'пять',    6 => 'шесть',
        7 => 'семь',   8 => 'восемь',  9 => 'девять',
        10 => 'десять',
        11 => 'одиннадцать', 12 => 'двенадцать',
        13 => 'тринадцать',  14 => 'четырнадцать',
        15 => 'пятнадцать',  16 => 'шестнадцать',
        17 => 'семнадцать',  18 => 'восемнадцать',
        19 => 'девятнадцать',
    );

    my %card_tens = (
        20 => 'двадцать',    30 => 'тридцать',
        40 => 'сорок',       50 => 'пятьдесят',
        60 => 'шестьдесят',  70 => 'семьдесят',
        80 => 'восемьдесят', 90 => 'девяносто',
    );

    my %card_hundreds = (
        100 => 'сто',        200 => 'двести',
        300 => 'триста',     400 => 'четыреста',
        500 => 'пятьсот',    600 => 'шестьсот',
        700 => 'семьсот',    800 => 'восемьсот',
        900 => 'девятьсот',
    );

    return $card_units{$number} if exists $card_units{$number};

    my $result = '';

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        $result = $card_hundreds{$h};
        $number %= 100;
        return $result if $number == 0;
        $result .= ' ';
    }

    if ($number >= 20) {
        my $t = int($number / 10) * 10;
        $result .= $card_tens{$t};
        $number %= 10;
        return $result if $number == 0;
        $result .= ' ' . $card_units{$number};
        return $result;
    }

    if ($number > 0) {
        $result .= $card_units{$number};
    }

    return $result;
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

# {{{ module documentation

=encoding utf-8

=head1 NAME

Lingua::RUS::Num2Word - Converts numbers to money sum in words (in Russian roubles)

=head1 VERSION

version 0.2603300

=head1 SYNOPSIS

  use Lingua::RUS::Num2Word qw(rur_in_words);

  print rur_in_words(1.01), "\n";

=head1 DESCRIPTION

Number 2 word conversion in RUS.

B<Lingua::RUS::Num2Word::rur_in_words()> helps you convert number to money sum in words.
Given a number, B<rur_in_words()> returns it as money sum in words, e.g.: 1.01 converted
to I<odin rubl' odna kopejka>, 2.22 converted to I<dwa rublja dwadcat' dwe kopejki>.
The target cyrillic charset is B<utf-8>.

Test::More::UTF8 in use in test because of encoding problems.

=head1 FUNCTIONS

=over

=item rur_in_words

Convert number to Russian currency string.

=item get_string

=item num2rus_ordinal

Convert number to Russian ordinal text representation.
Only numbers from interval [0, 999_999_999] will be converted.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=head1 BUGS

seems have no bugs..

=head1 AUTHORS

 initial coding:
   Vladislav A. Safronov E<lt>vlad at yandex.ruE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=cut

# }}}


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut
