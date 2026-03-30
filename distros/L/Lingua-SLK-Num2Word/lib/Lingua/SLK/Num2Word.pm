# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SLK::Num2Word;
# ABSTRACT: Number to word conversion in Slovak

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my %token1 = qw( 0 nula         1 jedna         2 dva
                 3 tri          4 štyri         5 päť
                 6 šesť         7 sedem         8 osem
                 9 deväť        10 desať        11 jedenásť
                 12 dvanásť     13 trinásť      14 štrnásť
                 15 pätnásť     16 šestnásť     17 sedemnásť
                 18 osemnásť    19 devätnásť
               );
my %token2 = qw( 20 dvadsať     30 tridsať      40 štyridsať
                 50 päťdesiat   60 šesťdesiat   70 sedemdesiat
                 80 osemdesiat  90 deväťdesiat
               );
my %token3 = (  100, 'sto',        200, 'dvesto',    300, 'tristo',
                400, 'štyristo',   500, 'päťsto',    600, 'šesťsto',
                700, 'sedemsto',   800, 'osemsto',   900, 'deväťsto'
             );

# }}}

# {{{ num2slk_cardinal           number to string conversion

sub num2slk_cardinal :Export {
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
            $result = $token2{$number - $reminder}.' '.num2slk_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2slk_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slk_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'tisíc';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2slk_cardinal($tmp2 - $tmp4).' jeden tisíc';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2slk_cardinal($tmp2).' tisíce';
            }
            else {
                $tmp2 = num2slk_cardinal($tmp2).' tisíc';
            }
        }
        else {
            $tmp2 = num2slk_cardinal($tmp2).' tisíc';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slk_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'milión';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2slk_cardinal($tmp2 - $tmp4).' jeden milión';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2slk_cardinal($tmp2).' milióny';
            }
            else {
                $tmp2 = num2slk_cardinal($tmp2).' miliónov';
            }
        }
        else {
            $tmp2 = num2slk_cardinal($tmp2).' miliónov';
        }

        $result = $tmp2.$tmp1;
    }

    return $result;
}

# }}}

# {{{ num2slk_ordinal           number to ordinal string conversion

sub num2slk_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-10
    my %irregular = (
        0  => 'nultý',
        1  => 'prvý',
        2  => 'druhý',
        3  => 'tretí',
        4  => 'štvrtý',
        5  => 'piaty',
        6  => 'šiesty',
        7  => 'siedmy',
        8  => 'ôsmy',
        9  => 'deviaty',
        10 => 'desiaty',
    );

    return $irregular{$number} if exists $irregular{$number};

    # Irregular teens 11-19
    my %teens = (
        11 => 'jedenásty',
        12 => 'dvanásty',
        13 => 'trinásty',
        14 => 'štrnásty',
        15 => 'pätnásty',
        16 => 'šestnásty',
        17 => 'sedemnásty',
        18 => 'osemnásty',
        19 => 'devätnásty',
    );

    return $teens{$number} if exists $teens{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'dvadsiaty',
        30 => 'tridsiaty',
        40 => 'štyridsiaty',
        50 => 'päťdesiaty',
        60 => 'šesťdesiaty',
        70 => 'sedemdesiaty',
        80 => 'osemdesiaty',
        90 => 'deväťdesiaty',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'stý',
        200 => 'dvojstý',
        300 => 'trojstý',
        400 => 'štvorsťý',
        500 => 'päťstý',
        600 => 'šesťstý',
        700 => 'sedemstý',
        800 => 'osemstý',
        900 => 'deväťstý',
    );

    # For numbers >= 1_000_000
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            my $prefix = num2slk_cardinal($millions);
            if ($millions == 1) {
                return 'milióntý';
            }
            return $prefix . ' milióntý';
        }
        my $prefix = num2slk_cardinal($millions);
        my $mil_word = ($millions == 1) ? 'milión' :
                       ($millions >= 2 && $millions <= 4) ? 'milióny' : 'miliónov';
        $mil_word = 'milión' if $millions == 1;
        return $prefix . ' ' . $mil_word . ' ' . num2slk_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            if ($thousands == 1) {
                return 'tisíci';
            }
            return num2slk_cardinal($thousands) . ' tisíci';
        }
        my $thou_cardinal;
        if ($thousands == 1) {
            $thou_cardinal = 'tisíc';
        }
        else {
            $thou_cardinal = num2slk_cardinal($thousands) .
                (($thousands % 100 >= 2 && $thousands % 100 <= 4 &&
                  !($thousands % 100 >= 12 && $thousands % 100 <= 14))
                 ? ' tisíce' : ' tisíc');
        }
        return $thou_cardinal . ' ' . num2slk_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        return $token3{$h} . ' ' . num2slk_ordinal($remainder);
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

Lingua::SLK::Num2Word - Number to word conversion in Slovak


=head1 VERSION

version 0.2603300

Lingua::SLK::Num2Word is module for conversion numbers into their representation
in Slovak. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SLK::Num2Word;

 my $text = Lingua::SLK::Num2Word::num2slk_cardinal( 123 );

 print $text || "sorry, can't convert this number into slovak language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2slk_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.

=item B<num2slk_ordinal> (positional)

  1   num    number to convert
  =>  str    ordinal string (e.g. 'prvý', 'druhý')

Convert number to its Slovak ordinal form.
Only numbers from interval [0, 999_999_999] will be converted.

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

=item num2slk_cardinal

=item num2slk_ordinal

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
