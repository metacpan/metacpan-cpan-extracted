# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::HRV::Num2Word;
# ABSTRACT: Number to word conversion in Croatian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my %token1 = qw( 0 nula         1 jedan         2 dva
                 3 tri          4 četiri        5 pet
                 6 šest         7 sedam         8 osam
                 9 devet        10 deset        11 jedanaest
                 12 dvanaest    13 trinaest     14 četrnaest
                 15 petnaest    16 šesnaest     17 sedamnaest
                 18 osamnaest   19 devetnaest
               );
my %token2 = qw( 20 dvadeset    30 trideset     40 četrdeset
                 50 pedeset     60 šezdeset     70 sedamdeset
                 80 osamdeset   90 devedeset
               );
my %token3 = ( 100, 'sto',        200, 'dvjesto',    300, 'tristo',
               400, 'četiristo',  500, 'petsto',     600, 'šeststo',
               700, 'sedamsto',   800, 'osamsto',    900, 'devetsto'
            );

# }}}

# {{{ num2hrv_cardinal           number to string conversion

sub num2hrv_cardinal :Export {
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
            $result = $token2{$number - $reminder}.' '.num2hrv_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2hrv_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2hrv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'tisuća';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2hrv_cardinal($tmp2 - $tmp4).' jedna tisuća';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                # 2-4: feminine "dvije" for 2, genitive plural "tisuće"
                if ($tmp2 == 2) {
                    $tmp2 = 'dvije tisuće';
                }
                elsif ($tmp2 == 3 || $tmp2 == 4) {
                    $tmp2 = num2hrv_cardinal($tmp2).' tisuće';
                }
                else {
                    # e.g. 22, 23, 24, 32, 33, 34...
                    if ($tmp4 == 2) {
                        $tmp2 = num2hrv_cardinal($tmp2 - $tmp4).' dvije tisuće';
                    }
                    else {
                        $tmp2 = num2hrv_cardinal($tmp2).' tisuće';
                    }
                }
            }
            else {
                $tmp2 = num2hrv_cardinal($tmp2).' tisuća';
            }
        }
        else {
            $tmp2 = num2hrv_cardinal($tmp2).' tisuća';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2hrv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'jedan milijun';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2hrv_cardinal($tmp2 - $tmp4).' jedan milijun';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2hrv_cardinal($tmp2).' milijuna';
            }
            else {
                $tmp2 = num2hrv_cardinal($tmp2).' milijuna';
            }
        }
        else {
            $tmp2 = num2hrv_cardinal($tmp2).' milijuna';
        }

        $result = $tmp2.$tmp1;
    }

    return $result;
}

# }}}

# {{{ num2hrv_ordinal           number to ordinal string conversion

sub num2hrv_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-10
    my %irregular = (
        0  => 'nulti',
        1  => 'prvi',
        2  => 'drugi',
        3  => 'treći',
        4  => 'četvrti',
        5  => 'peti',
        6  => 'šesti',
        7  => 'sedmi',
        8  => 'osmi',
        9  => 'deveti',
        10 => 'deseti',
    );

    return $irregular{$number} if exists $irregular{$number};

    # Irregular teens 11-19
    my %teens = (
        11 => 'jedanaesti',
        12 => 'dvanaesti',
        13 => 'trinaesti',
        14 => 'četrnaesti',
        15 => 'petnaesti',
        16 => 'šesnaesti',
        17 => 'sedamnaesti',
        18 => 'osamnaesti',
        19 => 'devetnaesti',
    );

    return $teens{$number} if exists $teens{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'dvadeseti',
        30 => 'trideseti',
        40 => 'četrdeseti',
        50 => 'pedeseti',
        60 => 'šezdeseti',
        70 => 'sedamdeseti',
        80 => 'osamdeseti',
        90 => 'devedeseti',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'stoti',
        200 => 'dvjestoti',
        300 => 'tristoti',
        400 => 'četiristoti',
        500 => 'petstoti',
        600 => 'šeststoti',
        700 => 'sedamstoti',
        800 => 'osamstoti',
        900 => 'devetstoti',
    );

    # For numbers >= 1_000_000
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            if ($millions == 1) {
                return 'milijunti';
            }
            return num2hrv_cardinal($millions) . ' milijunti';
        }
        my $prefix = num2hrv_cardinal($millions);
        my $mil_word = ($millions == 1) ? 'jedan milijun' : 'milijuna';
        return $prefix . ' ' . $mil_word . ' ' . num2hrv_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            if ($thousands == 1) {
                return 'tisućiti';
            }
            return num2hrv_cardinal($thousands) . ' tisućiti';
        }
        my $thou_cardinal;
        if ($thousands == 1) {
            $thou_cardinal = 'tisuća';
        }
        elsif ($thousands == 2) {
            $thou_cardinal = 'dvije tisuće';
        }
        elsif ($thousands >= 3 && $thousands <= 4) {
            $thou_cardinal = num2hrv_cardinal($thousands) . ' tisuće';
        }
        else {
            $thou_cardinal = num2hrv_cardinal($thousands) . ' tisuća';
        }
        return $thou_cardinal . ' ' . num2hrv_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        return $token3{$h} . ' ' . num2hrv_ordinal($remainder);
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

Lingua::HRV::Num2Word - Number to word conversion in Croatian


=head1 VERSION

version 0.2603300

Lingua::HRV::Num2Word is module for conversion numbers into their representation
in Croatian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HRV::Num2Word;

 my $text = Lingua::HRV::Num2Word::num2hrv_cardinal( 123 );

 print $text || "sorry, can't convert this number into croatian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2hrv_cardinal> (positional)

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

=item num2hrv_cardinal

=item num2hrv_ordinal

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
