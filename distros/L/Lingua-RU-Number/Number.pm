package Lingua::RU::Number;

use utf8;
use strict;
use POSIX qw/floor/;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(rur_in_words num2words);

$VERSION = '0.61';

# Preloaded methods go here.
use vars qw(%diw %nom %genders);

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
        11 => { 0 => "одиннадцать",   1 => 1},
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

%genders = (
    0 => { 0 => "", 1 => "", 2 => "одна", 3 => "две" },
    1 => { 0 => "", 1 => "", 2 => "один", 3 => "два" },
    2 => { 0 => "", 1 => "", 2 => "одно", 3 => "два" },
);

my $out_rub;

sub rur_in_words
{
    my ($sum) = shift;
    my ($retval, $i, $sum_rub, $sum_kop);

    $retval = "";
    $out_rub = ($sum >= 1) ? 0 : 1;
    $sum_rub = sprintf("%0.0f", $sum);
    $sum_rub-- if (($sum_rub - $sum) > 0);
    $sum_kop = sprintf("%0.2f",($sum - $sum_rub))*100;

    my $kop = get_string($sum_kop, 0);

    for ($i=1; $i<6 && $sum_rub >= 1; $i++) {
        my $sum_tmp  = $sum_rub/1000;
        my $sum_part = sprintf("%0.3f", $sum_tmp - int($sum_tmp))*1000;
        $sum_rub = sprintf("%0.0f",$sum_tmp);

        $sum_rub-- if ($sum_rub - $sum_tmp > 0);
        $retval = get_string($sum_part, $i)." ".$retval;
    }
    $retval .= " рублей" if ($out_rub == 0);
    $retval .= " ".$kop;
    $retval =~ s/\s+/ /g;
    return $retval;
}

sub get_string
{
    my ($sum, $nominal) = @_;
    my ($retval, $nom) = ('', -1);

    if (($nominal == 0 && $sum < 100) || ($nominal > 0 && $nominal < 6 && $sum < 1000)) {
        my $s2 = int($sum/100);
        if ($s2 > 0) {
            $retval .= " ".$diw{2}{$s2}{0};
            $nom = $diw{2}{$s2}{1};
        }
        my $sx = sprintf("%0.0f", $sum - $s2*100);
        $sx-- if ($sx - ($sum - $s2*100) > 0);

        if (($sx<20 && $sx>0) || ($sx == 0 && $nominal == 0)) {
            $retval .= " ".$diw{0}{$sx}{0};
            $nom = $diw{0}{$sx}{1};
        } else {
            my $s1 = sprintf("%0.0f",$sx/10);
            $s1-- if (($s1 - $sx/10) > 0);
            my $s0 = int($sum - $s2*100 - $s1*10 + 0.5);
            if ($s1 > 0) {
                $retval .= " ".$diw{1}{$s1}{0};
                $nom = $diw{1}{$s1}{1};
            }
            if ($s0 > 0) {
                $retval .= " ".$diw{0}{$s0}{0};
                $nom = $diw{0}{$s0}{1};
            }
        }
    }
    if ($nom >= 0) {
        $retval .= " ".$nom{$nominal}{$nom};
        $out_rub = 1 if ($nominal == 1);
    }
    $retval =~ s/^\s*//g;
    $retval =~ s/\s*$//g;

    return $retval;
}

sub num2words {
    my ($number, $gender) = @_;

    $gender = 1 unless defined $gender; # male by default

    return _get_string(0, 0, 0) unless $number; # no extra calculations for zero

    my ($result, $negative);

    # Negative number, just add another word
    if ($number < 0) {
        $number   = abs($number);
        $negative = 1;
    }

    $result = "";
    my $int_number = floor($number); # no doubles

    for (my $i = 1; $i < 6 && $int_number >= 1; $i++) {
        my $tmp_number = $int_number / 1000;
        my $number_part = sprintf("%0.3f", $tmp_number - sprintf("%d", $tmp_number)) * 1000;

        $int_number = floor $tmp_number; # no doubles again
        $result = _get_string($number_part, $i, $gender) . " " . $result;
    }

    # Clean the result
    $result =~ s/\s+/ /g;
    $result =~ s/\s+$//;

    return ($negative) ? "минус $result" : $result;
}

sub _get_string {
    my $sum     = shift;
    my $nominal = shift;
    my $gender  = shift;
    my ($result, $nom) = ('', -1);
    
    return unless defined $sum;

    if ( ( !$nominal && $sum < 100 ) || ( $nominal > 0 && $nominal < 6 && $sum < 1000 ) ) {
        my $s2 = sprintf( "%d", $sum / 100 );

        if ( $s2 > 0 ) {    # hundreds
            $result .= ' ' . $diw{2}{$s2}{0};
            $nom = $diw{2}{$s2}{1};
        }

        my $sx = floor $sum - $s2 * 100;

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

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module.

=encoding utf-8

=head1 NAME

Lingua::RU::Number - Converts numbers to money sum in words (in Russian roubles)
and numbers (int) to words. 

=head1 SYNOPSIS

  use Lingua::RU::Number qw(rur_in_words num2words);

  print rur_in_words(1.01), "\n"; 
  # outputs "один рубль одна копейка"
  
  print num2words(32), "\n"; 
  # outputs "тридцать два"
  
  print num2words(32, 1), " зуба \n"; 
  # outputs "тридцать два зуба"
  
  print num2words(21, 2), " очко \n"; 
  # outputs "двадцать одно очко"

=head1 DESCRIPTION

B<Lingua::RU::Number::rur_in_words()> helps you convert a number to money sum in words.
Given a number, B<rur_in_words()> returns it as money sum in words, e.g.: 1.01 converted
to I<один рубль одна копейка>, 2.22 converted to I<два рубля двадцать две копейки>.
The target charset is B<UTF-8>.

B<num2words( $number, $gender )> translates a number (integer) to text in russian, using the specified gender. B<$gender> 0|1|2 - feminine, masculine and neutral respectively. Masculine by default. Returns Unicode string.

=head1 BUGS

..

=head1 AUTHOR

Vladislav Safronov, E<lt>F<vlad at yandex.ru>E<gt>

num2words() code borrowed from B<Lingua::RU::Num2Word> by Richard C. Jelinek E<lt>F<info@petamem.com>E<gt>, https://github.com/regru/lingua-ru-num2word/blob/master/lib/Lingua/RU/Num2Word.pm

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2015 by Vladislav Safronov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
