# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::ELL::Num2Word;
# ABSTRACT: Number to word conversion in Greek

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2004-present';
our $VERSION = '0.2603300';

# }}}

# {{{ num2ell_cardinal                 convert number to text

sub num2ell_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(μηδέν ένα δύο τρία τέσσερα πέντε έξι επτά οκτώ εννέα δέκα έντεκα δώδεκα);
    my @teens = (
        'δεκατρία',     # 13
        'δεκατέσσερα',  # 14
        'δεκαπέντε',    # 15
        'δεκαέξι',      # 16
        'δεκαεπτά',     # 17
        'δεκαοκτώ',     # 18
        'δεκαεννέα',    # 19
    );
    my @tens = qw(είκοσι τριάντα σαράντα πενήντα εξήντα εβδομήντα ογδόντα ενενήντα);
    my @hundreds = (
        'εκατό',        # 100
        'διακόσια',     # 200
        'τριακόσια',    # 300
        'τετρακόσια',   # 400
        'πεντακόσια',   # 500
        'εξακόσια',     # 600
        'επτακόσια',    # 700
        'οκτακόσια',    # 800
        'εννιακόσια',   # 900
    );

    return $ones[$positive]           if ($positive >= 0 && $positive < 13);
    return $teens[$positive - 13]     if ($positive >= 13 && $positive < 20);

    my $out;
    my $remain;

    if ($positive > 19 && $positive < 100) {                   # 20 .. 99
        my $ten_idx = int($positive / 10) - 2;
        $remain     = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' ' . $ones[$remain] if ($remain);
    }
    elsif ($positive == 100) {                                  # 100
        $out = 'εκατό';
    }
    elsif ($positive > 100 && $positive < 200) {                # 101 .. 199
        $remain = $positive % 100;
        $out    = 'εκατόν ' . num2ell_cardinal($remain);
    }
    elsif ($positive >= 200 && $positive < 1000) {              # 200 .. 999
        my $h_idx = int($positive / 100) - 1;
        $remain   = $positive % 100;

        $out = $hundreds[$h_idx];
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 2000) {             # 1000 .. 1999
        $remain = $positive % 1000;

        $out = 'χίλια';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2000 && $positive < 1_000_000) {        # 2000 .. 999_999
        my $k_val = int($positive / 1000);
        $remain   = $positive % 1000;

        $out = num2ell_cardinal($k_val) . ' χιλιάδες';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 2_000_000) {   # 1_000_000 .. 1_999_999
        $remain = $positive % 1_000_000;

        $out = 'ένα εκατομμύριο';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2_000_000 && $positive < 1_000_000_000) { # 2_000_000 .. 999_999_999
        my $m_val = int($positive / 1_000_000);
        $remain   = $positive % 1_000_000;

        $out = num2ell_cardinal($m_val) . ' εκατομμύρια';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}

# {{{ num2ell_ordinal                  convert number to ordinal text

sub num2ell_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # {{{ tokens

    my @ones_ord = (
        '',              # 0 placeholder
        'πρώτος',        # 1st
        'δεύτερος',      # 2nd
        'τρίτος',        # 3rd
        'τέταρτος',      # 4th
        'πέμπτος',       # 5th
        'έκτος',         # 6th
        'έβδομος',       # 7th
        'όγδοος',        # 8th
        'ένατος',        # 9th
        'δέκατος',       # 10th
        'ενδέκατος',     # 11th
        'δωδέκατος',     # 12th
    );

    # 13th-19th: δέκατος + unit ordinal
    my @teens_ord = (
        'δέκατος τρίτος',      # 13th
        'δέκατος τέταρτος',    # 14th
        'δέκατος πέμπτος',     # 15th
        'δέκατος έκτος',       # 16th
        'δέκατος έβδομος',     # 17th
        'δέκατος όγδοος',      # 18th
        'δέκατος ένατος',      # 19th
    );

    my @tens_ord = (
        '',              # 0 placeholder
        '',              # 10 placeholder
        'εικοστός',      # 20th
        'τριακοστός',    # 30th
        'τεσσαρακοστός', # 40th
        'πεντηκοστός',   # 50th
        'εξηκοστός',     # 60th
        'εβδομηκοστός',  # 70th
        'ογδοηκοστός',   # 80th
        'ενενηκοστός',   # 90th  (modern standard, Triantafyllidis)
    );

    my @hundreds_ord = (
        '',                # 0 placeholder
        'εκατοστός',       # 100th
        'διακοσιοστός',    # 200th
        'τριακοσιοστός',   # 300th
        'τετρακοσιοστός',  # 400th
        'πεντακοσιοστός',  # 500th
        'εξακοσιοστός',    # 600th
        'επτακοσιοστός',   # 700th
        'οκτακοσιοστός',   # 800th
        'εννεακοσιοστός',  # 900th
    );

    # }}}

    return $ones_ord[$number]           if $number >= 1 && $number <= 12;
    return $teens_ord[$number - 13]     if $number >= 13 && $number <= 19;

    # {{{ 20..99

    if ($number >= 20 && $number <= 99) {
        my $ten_idx = int($number / 10);
        my $unit    = $number % 10;

        return $tens_ord[$ten_idx]      if $unit == 0;
        return $tens_ord[$ten_idx] . ' ' . $ones_ord[$unit];
    }

    # }}}
    # {{{ 100..999

    if ($number >= 100 && $number <= 999) {
        my $hun_idx = int($number / 100);
        my $remain  = $number % 100;

        return $hundreds_ord[$hun_idx]  if $remain == 0;
        return $hundreds_ord[$hun_idx] . ' ' . num2ell_ordinal($remain);
    }

    # }}}
    # {{{ 1000..999_999

    if ($number >= 1000 && $number <= 999_999) {
        my $thou_count = int($number / 1000);
        my $remain     = $number % 1000;

        my $out;
        if ($thou_count == 1 && $remain == 0) {
            return 'χιλιοστός';
        }
        elsif ($thou_count == 1) {
            $out = 'χιλιοστός';
        }
        elsif ($thou_count == 2 && $remain == 0) {
            return 'δισχιλιοστός';
        }
        elsif ($thou_count == 2) {
            $out = 'δισχιλιοστός';
        }
        else {
            # Cardinal prefix + χιλιοστός
            $out = num2ell_cardinal($thou_count) . ' χιλιοστός';
        }
        $out .= ' ' . num2ell_ordinal($remain) if $remain;
        return $out;
    }

    # }}}
    # {{{ 1_000_000..999_999_999

    if ($number >= 1_000_000 && $number <= 999_999_999) {
        my $mil_count = int($number / 1_000_000);
        my $remain    = $number % 1_000_000;

        my $out;
        if ($mil_count == 1) {
            $out = 'εκατομμυριοστός';
        }
        else {
            $out = num2ell_cardinal($mil_count) . ' εκατομμυριοστός';
        }
        $out .= ' ' . num2ell_ordinal($remain) if $remain;
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

Lingua::ELL::Num2Word - Number to word conversion in Greek


=head1 VERSION

version 0.2603300

Lingua::ELL::Num2Word is a module for converting numbers into their written
representation in Modern Greek. Converts whole numbers from 0 up to 999 999 999.

Follows Modern Standard Greek orthography (Triantafyllidis / single-ν forms,
e.g. ενενήντα not εννενήντα). Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ELL::Num2Word;

 my $text = Lingua::ELL::Num2Word::num2ell_cardinal( 123 );
 print $text || "sorry, can't convert this number into Greek.";

 my $ord = Lingua::ELL::Num2Word::num2ell_ordinal( 3 );
 print $ord;    # "τρίτος"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ell_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation in Modern Greek.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2ell_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string (masculine nominative singular)
      undef  if input number is not known

Convert number to Greek ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Uses masculine forms (ending in -ος).


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

=item num2ell_cardinal

=item num2ell_ordinal

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
