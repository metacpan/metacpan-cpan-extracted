# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::HUN::Num2Word;
# ABSTRACT: Number to word conversion in Hungarian

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

# {{{ num2hun_cardinal                 convert number to text

sub num2hun_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(nulla egy kettő három négy öt hat hét nyolc kilenc);
    my @tens = qw(tíz húsz harminc negyven ötven hatvan hetven nyolcvan kilencven);

    # 0 .. 9
    return $ones[$positive] if $positive < 10;

    # 10 .. 19
    if ($positive >= 10 && $positive < 20) {
        return 'tíz' if $positive == 10;
        return 'tizen' . $ones[$positive - 10];
    }

    # 20 .. 29
    if ($positive >= 20 && $positive < 30) {
        return 'húsz' if $positive == 20;
        return 'huszon' . $ones[$positive - 20];
    }

    # 30 .. 99
    if ($positive >= 30 && $positive < 100) {
        my $ten_idx = int($positive / 10);
        my $remain  = $positive % 10;

        my $out = $tens[$ten_idx - 1];
        $out .= $ones[$remain] if $remain;
        return $out;
    }

    my $out;
    my $idx;
    my $remain;

    # 100 .. 999
    if ($positive >= 100 && $positive < 1000) {
        $idx    = int($positive / 100);
        $remain = $positive % 100;

        $out  = $idx == 1 ? 'száz' : _compound_cardinal($idx) . 'száz';
        $out .= $remain ? num2hun_cardinal($remain) : '';
    }
    # 1000 .. 999_999
    elsif ($positive >= 1000 && $positive < 1_000_000) {
        $idx    = int($positive / 1000);
        $remain = $positive % 1000;

        $out  = $idx == 1 ? 'ezer' : _compound_cardinal($idx) . 'ezer';
        $out .= $remain ? num2hun_cardinal($remain) : '';
    }
    # 1_000_000 .. 999_999_999
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) {
        $idx    = int($positive / 1_000_000);
        $remain = $positive % 1_000_000;

        $out  = _compound_cardinal($idx) . 'millió';
        $out .= $remain ? '-' . num2hun_cardinal($remain) : '';
    }

    return $out;
}

# }}}
# {{{ _compound_cardinal               cardinal form using két instead of kettő

sub _compound_cardinal {
    my $positive = shift;

    my $text = num2hun_cardinal($positive);
    $text =~ s{kettő}{két}gxms;

    return $text;
}

# }}}


# {{{ num2hun_ordinal                 convert number to ordinal text

sub num2hun_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular forms (only for standalone 1 and 2)
    return 'első'    if $number == 1;
    return 'második' if $number == 2;

    return _hun_ordinal_compound($number);
}

# }}}
# {{{ _hun_ordinal_compound      ordinal for any number (compound-safe)

# Internal: returns the compound ordinal form for any number.
# Unlike the public function, 1 -> egyedik, 2 -> kettedik (not első/második).
sub _hun_ordinal_compound {
    my $number = shift;

    # Ordinal forms of single digits (compound-safe)
    my @ones_ord = (
        q{},           # 0 - unused
        'egyedik',     # 1
        'kettedik',    # 2
        'harmadik',    # 3
        'negyedik',    # 4
        'ötödik',      # 5
        'hatodik',     # 6
        'hetedik',     # 7
        'nyolcadik',   # 8
        'kilencedik',  # 9
    );

    # Simple 1-9: direct lookup
    return $ones_ord[$number] if $number >= 1 && $number <= 9;

    # Ordinal forms of round tens
    my @tens_ord = (
        q{},              # 0
        'tizedik',        # 10
        'huszadik',       # 20
        'harmincadik',    # 30
        'negyvenedik',    # 40
        'ötvenedik',      # 50
        'hatvanadik',     # 60
        'hetvenedik',     # 70
        'nyolcvanadik',   # 80
        'kilencvenedik',  # 90
    );

    # 10-99
    if ($number >= 10 && $number < 100) {
        my $ten_idx = int($number / 10);
        my $remain  = $number % 10;

        return $tens_ord[$ten_idx] if $remain == 0;

        # Compound: cardinal prefix of tens + ordinal of ones
        # 10s use "tizen-", 20s use "huszon-", 30+ use cardinal tens form
        my $prefix;
        if    ($ten_idx == 1) { $prefix = 'tizen';  }
        elsif ($ten_idx == 2) { $prefix = 'huszon'; }
        else {
            my @tens = qw(tíz húsz harminc negyven ötven hatvan hetven nyolcvan kilencven);
            $prefix = $tens[$ten_idx - 1];
        }

        return $prefix . $ones_ord[$remain];
    }

    # 100-999
    if ($number >= 100 && $number < 1000) {
        my $hun_idx = int($number / 100);
        my $remain  = $number % 100;

        if ($remain == 0) {
            return 'századik' if $hun_idx == 1;
            return _compound_cardinal($hun_idx) . 'századik';
        }

        my $prefix = $hun_idx == 1 ? 'száz' : _compound_cardinal($hun_idx) . 'száz';
        return $prefix . _hun_ordinal_compound($remain);
    }

    # 1000-999_999
    if ($number >= 1000 && $number < 1_000_000) {
        my $tho_idx = int($number / 1000);
        my $remain  = $number % 1000;

        if ($remain == 0) {
            return 'ezredik' if $tho_idx == 1;
            return _compound_cardinal($tho_idx) . 'ezredik';
        }

        my $prefix = $tho_idx == 1 ? 'ezer' : _compound_cardinal($tho_idx) . 'ezer';
        return $prefix . _hun_ordinal_compound($remain);
    }

    # 1_000_000-999_999_999
    if ($number >= 1_000_000 && $number < 1_000_000_000) {
        my $mil_idx = int($number / 1_000_000);
        my $remain  = $number % 1_000_000;

        if ($remain == 0) {
            return _compound_cardinal($mil_idx) . 'milliomodik';
        }

        my $prefix = _compound_cardinal($mil_idx) . 'millió-';
        return $prefix . _hun_ordinal_compound($remain);
    }

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

Lingua::HUN::Num2Word - Number to word conversion in Hungarian


=head1 VERSION

version 0.2603300

Lingua::HUN::Num2Word is a module for converting numbers into their written
representation in Hungarian. Converts whole numbers from 0 up to 999 999 999.

Text output is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HUN::Num2Word;

 my $text = Lingua::HUN::Num2Word::num2hun_cardinal( 123 );

 print $text || "sorry, can't convert this number into Hungarian.";

 my $ord = Lingua::HUN::Num2Word::num2hun_ordinal( 3 );
 print $ord;    # "harmadik"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2hun_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2hun_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Uses proper Hungarian ordinal morphology with vowel harmony suffixes.


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

=item num2hun_cardinal

=item num2hun_ordinal

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
