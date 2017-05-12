# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-
#
# (c) 2002-2010 PetaMem, s.r.o.
#

package Lingua::RUS::Number;
# ABSTRACT: Number 2 word conversion in RUS.

# {{{ use block

use 5.10.1;

use strict;
use warnings;
use utf8;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION = 0.136;

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


1;

__END__

# {{{ module documentation

=head1 NAME

Lingua::RUS::Number - Converts numbers to money sum in words (in Russian roubles)

=head1 VERSION

version 0.136

=head1 SYNOPSIS

  use Lingua::RUS::Number qw(rur_in_words);

  print rur_in_words(1.01), "\n";

=head1 DESCRIPTION

Number 2 word conversion in RUS.

B<Lingua::RUS::Number::rur_in_words()> helps you convert number to money sum in words.
Given a number, B<rur_in_words()> returns it as money sum in words, e.g.: 1.01 converted
to I<odin rubl' odna kopejka>, 2.22 converted to I<dwa rublja dwadcat' dwe kopejki>.
The target cyrillic charset is B<utf-8>.

Test::More::UTF8 in use in test because of encoding problems.

=head1 FUNCTIONS

=over

=item rur_in_words

Convert number to Russian currency string.

=item get_string

=back

=head1 BUGS

seems have no bugs..

=head1 AUTHOR

 fork coding, maintenance, refactoring, extensions:
   Richard C. Jelinek <info@petamem.com>
 initial coding:
   Vladislav A. Safronov, E<lt>F<vlads@yandex-team.ru>E<gt>, E<lt>F<vlad@yandex.ru>E<gt>

=cut

# }}}
