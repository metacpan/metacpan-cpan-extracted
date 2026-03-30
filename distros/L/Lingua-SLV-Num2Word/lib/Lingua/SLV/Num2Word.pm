# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SLV::Num2Word;
# ABSTRACT: Number to word conversion in Slovenian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my %token1 = qw( 0 nič            1 ena            2 dva
                 3 tri            4 štiri          5 pet
                 6 šest           7 sedem          8 osem
                 9 devet          10 deset          11 enajst
                 12 dvanajst      13 trinajst       14 štirinajst
                 15 petnajst      16 šestnajst      17 sedemnajst
                 18 osemnajst     19 devetnajst
               );
my %token2 = qw( 20 dvajset       30 trideset       40 štirideset
                 50 petdeset      60 šestdeset      70 sedemdeset
                 80 osemdeset     90 devetdeset
               );
my %token3 = ( 100, 'sto',        200, 'dvesto',     300, 'tristo',
               400, 'štiristo',   500, 'petsto',     600, 'šeststo',
               700, 'sedemsto',   800, 'osemsto',    900, 'devetsto'
            );

# }}}

# {{{ num2slv_cardinal           number to string conversion

sub num2slv_cardinal :Export {
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
            # Slovenian: units + "in" + tens (like German)
            $result = $token1{$reminder}.'in'.$token2{$number - $reminder};
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2slv_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);

        if ($tmp2 == 1) {
            $tmp2 = 'tisoč';
        }
        else {
            $tmp2 = num2slv_cardinal($tmp2).' tisoč';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;
        my $mega;

        # Slovenian million declension:
        #   1          -> milijon
        #   2          -> dva milijona  (dual)
        #   3-4        -> milijone      (plural nominative)
        #   5+, 11-19  -> milijonov     (genitive plural)
        if ($tmp3 >= 11 && $tmp3 <= 19) {
            # teens always use genitive plural
            $mega = 'milijonov';
        }
        elsif ($tmp4 == 1 && $tmp2 == 1) {
            $mega = 'milijon';
        }
        elsif ($tmp4 == 1) {
            # 21, 31, ... -> en milijon
            $mega = 'milijon';
        }
        elsif ($tmp4 == 2 && $tmp2 == 2) {
            $mega = 'milijona';  # dual
        }
        elsif ($tmp4 == 2) {
            $mega = 'milijona';  # dual ending
        }
        elsif ($tmp4 == 3 || $tmp4 == 4) {
            $mega = 'milijone';
        }
        else {
            $mega = 'milijonov';
        }

        if ($tmp2 == 1) {
            $tmp2 = 'en '.$mega;
        }
        else {
            $tmp2 = num2slv_cardinal($tmp2).' '.$mega;
        }

        $result = $tmp2.$tmp1;
    }

    return $result;
}

# }}}

# {{{ num2slv_ordinal           number to ordinal string conversion

sub num2slv_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-10
    my %irregular = (
        0  => 'ničti',
        1  => 'prvi',
        2  => 'drugi',
        3  => 'tretji',
        4  => 'četrti',
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
        11 => 'enajsti',
        12 => 'dvanajsti',
        13 => 'trinajsti',
        14 => 'štirinajsti',
        15 => 'petnajsti',
        16 => 'šestnajsti',
        17 => 'sedemnajsti',
        18 => 'osemnajsti',
        19 => 'devetnajsti',
    );

    return $teens{$number} if exists $teens{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'dvajseti',
        30 => 'trideseti',
        40 => 'štirideseti',
        50 => 'petdeseti',
        60 => 'šestdeseti',
        70 => 'sedemdeseti',
        80 => 'osemdeseti',
        90 => 'devetdeseti',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'stoti',
        200 => 'dvestoti',
        300 => 'tristoti',
        400 => 'štiristoti',
        500 => 'petstoti',
        600 => 'šeststoti',
        700 => 'sedemstoti',
        800 => 'osemstoti',
        900 => 'devetstoti',
    );

    # For numbers >= 1_000_000
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            if ($millions == 1) {
                return 'milijonti';
            }
            return num2slv_cardinal($millions) . ' milijonti';
        }
        my $prefix = num2slv_cardinal($millions);
        my $mil_word = ($millions == 1) ? 'en milijon' : 'milijonov';
        return $prefix . ' ' . $mil_word . ' ' . num2slv_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            if ($thousands == 1) {
                return 'tisočti';
            }
            return num2slv_cardinal($thousands) . ' tisočti';
        }
        my $thou_cardinal;
        if ($thousands == 1) {
            $thou_cardinal = 'tisoč';
        }
        else {
            $thou_cardinal = num2slv_cardinal($thousands) . ' tisoč';
        }
        return $thou_cardinal . ' ' . num2slv_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        return $token3{$h} . ' ' . num2slv_ordinal($remainder);
    }

    # 20-99 compound: Slovenian uses unit+in+tens for cardinals,
    # but ordinals follow the same compound pattern
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

Lingua::SLV::Num2Word - Number to word conversion in Slovenian


=head1 VERSION

version 0.2603300

Lingua::SLV::Num2Word is module for conversion numbers into their representation
in Slovenian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SLV::Num2Word;

 my $text = Lingua::SLV::Num2Word::num2slv_cardinal( 123 );

 print $text || "sorry, can't convert this number into slovenian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2slv_cardinal> (positional)

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

=item num2slv_cardinal

=item num2slv_ordinal

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
