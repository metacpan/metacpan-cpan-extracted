# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::ARA::Num2Word;
# ABSTRACT: Number to word conversion in Arabic

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

# {{{ num2ara_cardinal                 convert number to text

sub num2ara_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # Units (masculine counting forms)
    my @ones = (
        "صفر",                                       # 0  صفر
        "واحد",                                # 1  واحد
        "اثنان",                         # 2  اثنان
        "ثلاثة",                         # 3  ثلاثة
        "أربعة",                         # 4  أربعة
        "خمسة",                                # 5  خمسة
        "ستة",                                       # 6  ستة
        "سبعة",                                # 7  سبعة
        "ثمانية",                  # 8  ثمانية
        "تسعة",                                # 9  تسعة
    );

    # Tens
    my @tens_word = (
        q{},                                                            # 0  (unused)
        "عشرة",                                # 10 عشرة
        "عشرون",                         # 20 عشرون
        "ثلاثون",                  # 30 ثلاثون
        "أربعون",                  # 40 أربعون
        "خمسون",                         # 50 خمسون
        "ستون",                                # 60 ستون
        "سبعون",                         # 70 سبعون
        "ثمانون",                  # 80 ثمانون
        "تسعون",                         # 90 تسعون
    );

    # Special teens (11-19)
    my @teens;
    $teens[11] = "أحد عشر";       # أحد عشر
    $teens[12] = "اثنا عشر"; # اثنا عشر
    # 13-19: unit + عشر
    my $ashar = "عشر";                               # عشر
    for my $i (13..19) {
        $teens[$i] = "$ones[$i - 10] $ashar";
    }

    # Connector
    my $wa = " و";                                               # و (and)

    # Hundred forms
    my $mi_a    = "مئة";                             # مئة
    my $mi_atan = "مئتان";              # مئتان

    # Thousand forms
    my $alf   = "ألف";                               # ألف
    my $alfan = "ألفان";                 # ألفان
    my $alaf  = "آلاف";                        # آلاف

    # Million forms
    my $milyun   = "مليون";             # مليون
    my $milyunan = "مليونان"; # مليونان
    my $malayin  = "ملايين";      # ملايين

    return $ones[0] if $positive == 0;

    return _convert($positive, \@ones, \@tens_word, \@teens,
                    $wa, $mi_a, $mi_atan,
                    $alf, $alfan, $alaf,
                    $milyun, $milyunan, $malayin);
}

# }}}
# {{{ _convert                          recursive number-to-word engine

sub _convert {
    my ($n, $ones, $tens_word, $teens,
        $wa, $mi_a, $mi_atan,
        $alf, $alfan, $alaf,
        $milyun, $milyunan, $malayin) = @_;

    my @params = ($ones, $tens_word, $teens,
                  $wa, $mi_a, $mi_atan,
                  $alf, $alfan, $alaf,
                  $milyun, $milyunan, $malayin);

    return q{} if $n == 0;

    # --- Millions ---
    if ($n >= 1_000_000) {
        my $millions = int($n / 1_000_000);
        my $remain   = $n % 1_000_000;

        my $out;
        if ($millions == 1) {
            $out = $milyun;
        }
        elsif ($millions == 2) {
            $out = $milyunan;
        }
        elsif ($millions >= 3 && $millions <= 10) {
            $out = _convert($millions, @params) . ' ' . $malayin;
        }
        else {
            # 11+ millions: number + مليون (singular)
            $out = _convert($millions, @params) . ' ' . $milyun;
        }

        if ($remain) {
            $out .= "$wa" . _convert($remain, @params);
        }
        return $out;
    }

    # --- Thousands ---
    if ($n >= 1000) {
        my $thousands = int($n / 1000);
        my $remain    = $n % 1000;

        my $out;
        if ($thousands == 1) {
            $out = $alf;
        }
        elsif ($thousands == 2) {
            $out = $alfan;
        }
        elsif ($thousands >= 3 && $thousands <= 10) {
            $out = _convert($thousands, @params) . ' ' . $alaf;
        }
        else {
            # 11+ thousands: number + ألف (singular)
            $out = _convert($thousands, @params) . ' ' . $alf;
        }

        if ($remain) {
            $out .= "$wa" . _convert($remain, @params);
        }
        return $out;
    }

    # --- Hundreds ---
    if ($n >= 100) {
        my $hundreds = int($n / 100);
        my $remain   = $n % 100;

        my $out;
        if ($hundreds == 1) {
            $out = $mi_a;
        }
        elsif ($hundreds == 2) {
            $out = $mi_atan;
        }
        else {
            # 300-900: unit form (without taa marbuTa for 3-9) + مئة
            # Use shortened forms for hundreds: ثلاث، أربع، خمس، ست، سبع، ثمان، تسع
            my @hund_prefix = (
                q{},                                                    # 0
                q{},                                                    # 1
                q{},                                                    # 2
                "ثلاث",                        # 3  ثلاث
                "أربع",                        # 4  أربع
                "خمس",                                # 5  خمس
                "ست",                                       # 6  ست
                "سبع",                                # 7  سبع
                "ثمان",                        # 8  ثمان
                "تسع",                                # 9  تسع
            );
            $out = $hund_prefix[$hundreds] . $mi_a;
        }

        if ($remain) {
            $out .= "$wa" . _convert($remain, @params);
        }
        return $out;
    }

    # --- Teens (11-19) ---
    if ($n >= 11 && $n <= 19) {
        return $teens->[$n];
    }

    # --- Ten ---
    if ($n == 10) {
        return $tens_word->[1];
    }

    # --- Tens with units (21-99) ---
    if ($n >= 20) {
        my $ten_idx = int($n / 10);
        my $unit    = $n % 10;

        if ($unit) {
            return $ones->[$unit] . "$wa" . $tens_word->[$ten_idx];
        }
        return $tens_word->[$ten_idx];
    }

    # --- Units (1-9) ---
    return $ones->[$n];
}

# }}}


# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::ARA::Num2Word - Number to word conversion in Arabic


=head1 VERSION

version 0.2603300

Lingua::ARA::Num2Word is module for converting numbers into their written
representation in Modern Standard Arabic (masculine counting forms).
Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ARA::Num2Word;

 my $text = Lingua::ARA::Num2Word::num2ara_cardinal( 123 );

 print $text || "sorry, can't convert this number into Arabic.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ara_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string (UTF-8 Arabic)
      undef  if input number is not known

Convert number to text representation in Modern Standard Arabic.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<_convert> (positional)

  Internal recursive conversion engine. Not exported.


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

=item num2ara_cardinal

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
