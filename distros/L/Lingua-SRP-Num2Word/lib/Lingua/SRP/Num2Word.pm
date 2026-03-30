# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SRP::Num2Word;
# ABSTRACT: Number to word conversion in Serbian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my %token1 = qw( 0 нула          1 један         2 два
                  3 три           4 четири        5 пет
                  6 шест          7 седам         8 осам
                  9 девет         10 десет        11 једанаест
                  12 дванаест     13 тринаест     14 четрнаест
                  15 петнаест     16 шеснаест     17 седамнаест
                  18 осамнаест    19 деветнаест
                );
my %token2 = qw( 20 двадесет     30 тридесет     40 четрдесет
                  50 педесет      60 шездесет     70 седамдесет
                  80 осамдесет    90 деведесет
                );
my %token3 = ( 100, 'сто',        200, 'двеста',    300, 'триста',
               400, 'четиристо',  500, 'петсто',    600, 'шестсто',
               700, 'седамсто',   800, 'осамсто',   900, 'деветсто'
            );

# }}}

# {{{ num2srp_cardinal           number to string conversion

sub num2srp_cardinal :Export {
    my $result = '';
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    my $reminder = 0;

    if ($number < 20) {
        $result = $token1{$number};
    }
    elsif ($number < 100) {
        $reminder = $number % 10;
        if ($reminder == 0) {
            $result = $token2{$number};
        }
        else {
            $result = $token2{$number - $reminder}.' '.num2srp_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2srp_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2srp_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'хиљада';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2srp_cardinal($tmp2 - $tmp4).' једна хиљада';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                # 2-4: feminine "две" for 2, genitive plural "хиљаде"
                if ($tmp2 == 2) {
                    $tmp2 = 'две хиљаде';
                }
                elsif ($tmp2 == 3 || $tmp2 == 4) {
                    $tmp2 = num2srp_cardinal($tmp2).' хиљаде';
                }
                else {
                    # e.g. 22, 23, 24, 32, 33, 34...
                    if ($tmp4 == 2) {
                        $tmp2 = num2srp_cardinal($tmp2 - $tmp4).' две хиљаде';
                    }
                    else {
                        $tmp2 = num2srp_cardinal($tmp2).' хиљаде';
                    }
                }
            }
            else {
                $tmp2 = num2srp_cardinal($tmp2).' хиљада';
            }
        }
        else {
            $tmp2 = num2srp_cardinal($tmp2).' хиљада';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2srp_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'један милион';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2srp_cardinal($tmp2 - $tmp4).' један милион';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2srp_cardinal($tmp2).' милиона';
            }
            else {
                $tmp2 = num2srp_cardinal($tmp2).' милиона';
            }
        }
        else {
            $tmp2 = num2srp_cardinal($tmp2).' милиона';
        }

        $result = $tmp2.$tmp1;
    }

    return $result;
}

# }}}

# {{{ num2srp_ordinal           number to ordinal string conversion

sub num2srp_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-10
    my %irregular = (
        0  => 'нулти',
        1  => 'први',
        2  => 'други',
        3  => 'трећи',
        4  => 'четврти',
        5  => 'пети',
        6  => 'шести',
        7  => 'седми',
        8  => 'осми',
        9  => 'девети',
        10 => 'десети',
    );

    return $irregular{$number} if exists $irregular{$number};

    # Irregular teens 11-19
    my %teens = (
        11 => 'једанаести',
        12 => 'дванаести',
        13 => 'тринаести',
        14 => 'четрнаести',
        15 => 'петнаести',
        16 => 'шеснаести',
        17 => 'седамнаести',
        18 => 'осамнаести',
        19 => 'деветнаести',
    );

    return $teens{$number} if exists $teens{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'двадесети',
        30 => 'тридесети',
        40 => 'четрдесети',
        50 => 'педесети',
        60 => 'шездесети',
        70 => 'седамдесети',
        80 => 'осамдесети',
        90 => 'деведесети',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'стоти',
        200 => 'двестоти',
        300 => 'тристоти',
        400 => 'четиристоти',
        500 => 'петстоти',
        600 => 'шестстоти',
        700 => 'седамстоти',
        800 => 'осамстоти',
        900 => 'деветстоти',
    );

    # For numbers >= 1_000_000
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            if ($millions == 1) {
                return 'милионити';
            }
            return num2srp_cardinal($millions) . ' милионити';
        }
        my $prefix = num2srp_cardinal($millions);
        my $mil_word = ($millions == 1) ? 'један милион' : 'милиона';
        return $prefix . ' ' . $mil_word . ' ' . num2srp_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            if ($thousands == 1) {
                return 'хиљадити';
            }
            return num2srp_cardinal($thousands) . ' хиљадити';
        }
        my $thou_cardinal;
        if ($thousands == 1) {
            $thou_cardinal = 'хиљада';
        }
        elsif ($thousands == 2) {
            $thou_cardinal = 'две хиљаде';
        }
        elsif ($thousands >= 3 && $thousands <= 4) {
            $thou_cardinal = num2srp_cardinal($thousands) . ' хиљаде';
        }
        else {
            $thou_cardinal = num2srp_cardinal($thousands) . ' хиљада';
        }
        return $thou_cardinal . ' ' . num2srp_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        return $token3{$h} . ' ' . num2srp_ordinal($remainder);
    }

    # 20-99 compound
    if ($number >= 20) {
        my $t = int($number / 10) * 10;
        my $remainder = $number % 10;
        if ($remainder == 0) {
            return $tens_ord{$t};
        }
        return $tens_ord{$t} . ' ' . $irregular{$remainder};
    }

    # Should not reach here
    return;
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

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SRP::Num2Word - Number to word conversion in Serbian


=head1 VERSION

version 0.2603300

Lingua::SRP::Num2Word is module for conversion numbers into their representation
in Serbian (Cyrillic script). It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SRP::Num2Word;

 my $text = Lingua::SRP::Num2Word::num2srp_cardinal( 123 );

 print $text || "sorry, can't convert this number into serbian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2srp_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2srp_cardinal

=item num2srp_ordinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
