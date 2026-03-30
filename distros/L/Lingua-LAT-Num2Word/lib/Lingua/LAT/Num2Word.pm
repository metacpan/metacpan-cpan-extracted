# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::LAT::Num2Word;
# ABSTRACT: Number to word conversion in Latin

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2002-present';
our $VERSION = '0.2603300';

# }}}

# {{{ num2lat_cardinal                 convert number to text

sub num2lat_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999;

    # {{{ tokens

    my @ones = qw(nulla unus duo tres quattuor quinque sex septem octo novem);

    my @teens = qw(
        decem undecim duodecim tredecim quattuordecim quindecim
        sedecim septendecim duodeviginti undeviginti
    );

    my @tens = qw(
        _X _X viginti triginta quadraginta quinquaginta
        sexaginta septuaginta octoginta nonaginta
    );

    # Next-decade words for subtractive forms (8/9 of decade N use decade N+1)
    my @next_decade = qw(
        _X _X triginta quadraginta quinquaginta sexaginta
        septuaginta octoginta nonaginta centum
    );

    my @hundreds = qw(
        _X centum ducenti trecenti quadringenti quingenti
        sescenti septingenti octingenti nongenti
    );

    # }}}

    return $ones[$positive]                 if $positive >= 0 && $positive <= 9;
    return $teens[$positive - 10]           if $positive >= 10 && $positive <= 19;

    # {{{ 20..99

    if ($positive >= 20 && $positive <= 99) {
        my $ten_idx = int($positive / 10);
        my $unit    = $positive % 10;

        return $tens[$ten_idx]              if $unit == 0;

        # Subtractive: 8 => duode + next decade, 9 => unde + next decade
        # Exception: 98 is additive (nonaginta octo), but 99 is subtractive (undecentum)
        if ($unit == 8 && $ten_idx != 9) {
            return 'duode' . $next_decade[$ten_idx];
        }
        if ($unit == 9) {
            return 'unde' . $next_decade[$ten_idx];
        }

        # Additive: tens + space + unit
        return $tens[$ten_idx] . ' ' . $ones[$unit];
    }

    # }}}
    # {{{ 100..999

    if ($positive >= 100 && $positive <= 999) {
        my $hun_idx = int($positive / 100);
        my $remain  = $positive % 100;

        my $out = $hundreds[$hun_idx];
        $out .= ' ' . num2lat_cardinal($remain) if $remain;
        return $out;
    }

    # }}}
    # {{{ 1000..999_999

    if ($positive >= 1000 && $positive <= 999_999) {
        my $thou_count = int($positive / 1000);
        my $remain     = $positive % 1000;

        # mille for 1000, N milia for multiples
        my $out;
        if ($thou_count == 1) {
            $out = 'mille';
        }
        else {
            $out = num2lat_cardinal($thou_count) . ' milia';
        }
        $out .= ' ' . num2lat_cardinal($remain) if $remain;
        return $out;
    }

    # }}}

    return;
}

# }}}

# {{{ num2lat_ordinal                  convert number to ordinal text

sub num2lat_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999;

    # {{{ tokens

    my @ones_ord = qw(
        _X primus secundus tertius quartus quintus
        sextus septimus octavus nonus decimus
    );

    my @teens_ord = (
        'undecimus',         # 11
        'duodecimus',        # 12
        'tertius decimus',   # 13
        'quartus decimus',   # 14
        'quintus decimus',   # 15
        'sextus decimus',    # 16
        'septimus decimus',  # 17
    );

    # Tens ordinals: 20th, 30th, ..., 90th
    my @tens_ord = qw(
        _X _X vicesimus tricesimus quadragesimus quinquagesimus
        sexagesimus septuagesimus octogesimus nonagesimus
    );

    # Next-decade ordinals for subtractive forms (18/19, 28/29, etc.)
    my @next_decade_ord = qw(
        _X _X tricesimus quadragesimus quinquagesimus sexagesimus
        septuagesimus octogesimus nonagesimus centesimus
    );

    my @hundreds_ord = qw(
        _X centesimus ducentesimus trecentesimus quadringentesimus
        quingentesimus sescentesimus septingentesimus octingentesimus
        nongentesimus
    );

    # }}}

    return $ones_ord[$number]               if $number >= 1 && $number <= 10;
    return $teens_ord[$number - 11]          if $number >= 11 && $number <= 17;

    # {{{ 18..19 — subtractive

    return 'duodevicesimus'                  if $number == 18;
    return 'undevicesimus'                   if $number == 19;

    # }}}
    # {{{ 20..99

    if ($number >= 20 && $number <= 99) {
        my $ten_idx = int($number / 10);
        my $unit    = $number % 10;

        return $tens_ord[$ten_idx]           if $unit == 0;

        # Subtractive: 8 => duode + next decade ordinal, 9 => unde + next decade ordinal
        if ($unit == 8) {
            return 'duode' . $next_decade_ord[$ten_idx];
        }
        if ($unit == 9) {
            return 'unde' . $next_decade_ord[$ten_idx];
        }

        # Additive: tens ordinal + unit ordinal
        return $tens_ord[$ten_idx] . ' ' . $ones_ord[$unit];
    }

    # }}}
    # {{{ 100..999

    if ($number >= 100 && $number <= 999) {
        my $hun_idx = int($number / 100);
        my $remain  = $number % 100;

        return $hundreds_ord[$hun_idx]       if $remain == 0;
        return $hundreds_ord[$hun_idx] . ' ' . num2lat_ordinal($remain);
    }

    # }}}
    # {{{ 1000..999_999

    if ($number >= 1000 && $number <= 999_999) {
        my $thou_count = int($number / 1000);
        my $remain     = $number % 1000;

        if ($thou_count == 1 && $remain == 0) {
            return 'millesimus';
        }

        # For compound thousands: cardinal prefix + millesimus + remainder ordinal
        my $out;
        if ($thou_count == 1) {
            $out = 'millesimus';
        }
        else {
            $out = num2lat_cardinal($thou_count) . ' millesimus';
        }
        $out .= ' ' . num2lat_ordinal($remain) if $remain;
        return $out;
    }

    # }}}

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

Lingua::LAT::Num2Word - Number to word conversion in Latin


=head1 VERSION

version 0.2603300

Lingua::LAT::Num2Word is a module for converting numbers into their written
representation in Latin. Converts whole numbers from 0 up to 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LAT::Num2Word;

 my $text = Lingua::LAT::Num2Word::num2lat_cardinal( 123 );
 print $text || "sorry, can't convert this number into Latin.";

 my $ord = Lingua::LAT::Num2Word::num2lat_ordinal( 3 );
 print $ord;    # "tertius"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2lat_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Latin cardinal text representation.
Only numbers from interval [0, 999_999] will be converted.

Latin uses subtractive forms for 8 and 9 of each decade
(e.g. duodeviginti = 18, undeviginti = 19), with the notable
exception of 98 which uses the additive form (nonaginta octo).

=item B<num2lat_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string
      undef  if input number is not known

Convert number to Latin ordinal text representation (masculine nominative singular).
Only numbers from interval [1, 999_999] will be converted.

Uses subtractive forms for 8th and 9th of each decade
(e.g. duodevicesimus = 18th, undevicesimus = 19th).

=item B<capabilities> (void)

  =>  hashref  hash of supported conversion types

Returns a hash reference indicating which conversion types are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2lat_cardinal

=item num2lat_ordinal

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
