# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::HEB::Num2Word;
# ABSTRACT: Number to word conversion in Hebrew

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

# {{{ num2heb_cardinal                 convert number to text

sub num2heb_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # {{{ tokens

    # Units 0-10 (masculine/counting form)
    my @units = (
        'אפס',      # 0  efes
        'אחד',      # 1  echad
        'שניים',     # 2  shnayim
        'שלושה',     # 3  shlosha
        'ארבעה',     # 4  arba'a
        'חמישה',     # 5  chamisha
        'שישה',      # 6  shisha
        'שבעה',      # 7  shiv'a
        'שמונה',     # 8  shmona
        'תשעה',      # 9  tish'a
        'עשרה',      # 10 asara
    );

    # Teens 11-19 (masculine)
    my @teens = (
        '',                  # placeholder for 10
        'אחד עשר',          # 11 achad asar
        'שנים עשר',          # 12 shneym asar
        'שלושה עשר',         # 13 shlosha asar
        'ארבעה עשר',         # 14 arba'a asar
        'חמישה עשר',         # 15 chamisha asar
        'שישה עשר',          # 16 shisha asar
        'שבעה עשר',          # 17 shiv'a asar
        'שמונה עשר',         # 18 shmona asar
        'תשעה עשר',          # 19 tish'a asar
    );

    # Tens 20-90
    my @tens = (
        '',          # placeholder
        '',          # placeholder
        'עשרים',     # 20 esrim
        'שלושים',    # 30 shloshim
        'ארבעים',    # 40 arba'im
        'חמישים',    # 50 chamishim
        'שישים',     # 60 shishim
        'שבעים',     # 70 shiv'im
        'שמונים',    # 80 shmonim
        'תשעים',     # 90 tish'im
    );

    # Construct forms for hundreds (3-9 before מאות)
    my @hund_prefix = (
        '',          # 0
        '',          # 1 - special case מאה
        '',          # 2 - special case מאתיים
        'שלוש',      # 3  shlosh
        'ארבע',      # 4  arba
        'חמש',       # 5  chamesh
        'שש',        # 6  shesh
        'שבע',       # 7  shva
        'שמונה',     # 8  shmone
        'תשע',       # 9  tsha
    );

    # Construct forms for thousands (3-9 before אלפים)
    my @thou_prefix = (
        '',            # 0
        '',            # 1 - special case אלף
        '',            # 2 - special case אלפיים
        'שלושת',       # 3  shloshet
        'ארבעת',       # 4  arba'at
        'חמשת',        # 5  chameshet
        'ששת',         # 6  sheshet
        'שבעת',        # 7  shiv'at
        'שמונת',       # 8  shmonat
        'תשעת',        # 9  tish'at
    );

    # }}}

    return $units[$positive] if ($positive >= 0 && $positive <= 10);
    return $teens[$positive - 10] if ($positive > 10 && $positive < 20);

    my $out;

    if ($positive >= 20 && $positive < 100) {                # 20 .. 99
        my $ten_idx = int($positive / 10);
        my $remain  = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' ו' . $units[$remain] if $remain;
    }
    elsif ($positive == 100) {                                # 100
        $out = 'מאה';
    }
    elsif ($positive > 100 && $positive < 1000) {            # 101 .. 999
        my $hund_idx = int($positive / 100);
        my $remain   = $positive % 100;

        if ($hund_idx == 1) {
            $out = 'מאה';
        }
        elsif ($hund_idx == 2) {
            $out = 'מאתיים';
        }
        else {
            $out = "$hund_prefix[$hund_idx] מאות";
        }

        if ($remain) {
            $out .= ' ' . num2heb_cardinal($remain);
        }
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {     # 1000 .. 999_999
        my $thou_idx = int($positive / 1000);
        my $remain   = $positive % 1000;

        if ($thou_idx == 1) {
            $out = 'אלף';
        }
        elsif ($thou_idx == 2) {
            $out = 'אלפיים';
        }
        elsif ($thou_idx < 10) {
            $out = "$thou_prefix[$thou_idx] אלפים";
        }
        else {
            # thou_idx >= 10, recursively convert the thousands multiplier
            $out = num2heb_cardinal($thou_idx) . ' אלף';
        }

        if ($remain) {
            $out .= ' ' . num2heb_cardinal($remain);
        }
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $mil_idx = int($positive / 1_000_000);
        my $remain  = $positive % 1_000_000;

        if ($mil_idx == 1) {
            $out = 'מיליון';
        }
        else {
            $out = num2heb_cardinal($mil_idx) . ' מיליון';
        }

        if ($remain) {
            $out .= ' ' . num2heb_cardinal($remain);
        }
    }

    return $out;
}

# }}}

# {{{ num2heb_ordinal                  convert number to ordinal text

sub num2heb_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # {{{ tokens — ordinals 1-10 (masculine)

    my @ordinals = (
        '',           # 0 placeholder
        'ראשון',      # 1st  rishon
        'שני',        # 2nd  sheni
        'שלישי',      # 3rd  shlishi
        'רביעי',      # 4th  revi'i
        'חמישי',      # 5th  chamishi
        'שישי',       # 6th  shishi
        'שביעי',      # 7th  shvi'i
        'שמיני',      # 8th  shmini
        'תשיעי',      # 9th  tshi'i
        'עשירי',      # 10th asiri
    );

    # }}}

    # 1-10: dedicated ordinal forms
    return $ordinals[$number] if $number >= 1 && $number <= 10;

    # 11+: Hebrew uses the cardinal form for ordinals
    return num2heb_cardinal($number);
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

Lingua::HEB::Num2Word - Number to word conversion in Hebrew


=head1 VERSION

version 0.2603300

Lingua::HEB::Num2Word is module for converting numbers into their written
representation in Hebrew. Converts whole numbers from 0 up to 999 999 999.
Uses masculine (counting) forms as default.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HEB::Num2Word;

 my $text = Lingua::HEB::Num2Word::num2heb_cardinal( 123 );
 print $text || "sorry, can't convert this number into Hebrew.";

 my $ord = Lingua::HEB::Num2Word::num2heb_ordinal( 3 );
 print $ord;    # "שלישי"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2heb_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string (UTF-8 Hebrew)
      undef  if input number is not known

Convert number to Hebrew text representation.
Only numbers from interval [0, 999_999_999] will be converted.
Uses masculine (counting) forms.

=item B<num2heb_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string (UTF-8 Hebrew)
      undef  if input number is not known

Convert number to Hebrew ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Uses masculine forms. For 1-10, dedicated ordinal forms are used
(rishon, sheni, shlishi, etc.). For 11 and above, Hebrew uses
the cardinal number form as ordinal.


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

=item num2heb_cardinal

=item num2heb_ordinal

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
