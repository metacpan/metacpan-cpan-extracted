# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::MLT::Num2Word;
# ABSTRACT: Number to word conversion in Maltese

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
our $VERSION = '0.2603270';

# }}}

# {{{ num2mlt_cardinal                 convert number to text

sub num2mlt_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # Units (standalone / counting forms)
    my @ones = (
        "żero",         # 0
        "wieħed",       # 1
        "tnejn",        # 2
        "tlieta",       # 3
        "erbgħa",       # 4
        "ħamsa",        # 5
        "sitta",        # 6
        "sebgħa",       # 7
        "tmienja",      # 8
        "disgħa",       # 9
    );

    # Tens
    my @tens_word = (
        q{},            # 0  (unused)
        "għaxra",       # 10
        "għoxrin",      # 20
        "tletin",       # 30
        "erbgħin",      # 40
        "ħamsin",       # 50
        "sittin",       # 60
        "sebgħin",      # 70
        "tmenin",       # 80
        "disgħin",      # 90
    );

    # Teens (11-19)
    my @teens;
    $teens[11] = "ħdax";
    $teens[12] = "tnax";
    $teens[13] = "tlettax";
    $teens[14] = "erbatax";
    $teens[15] = "ħmistax";
    $teens[16] = "sittax";
    $teens[17] = "sbatax";
    $teens[18] = "tmintax";
    $teens[19] = "dsatax";

    # Connector
    my $u = " u ";

    # Hundred forms — construct-state prefixes for 3-9
    my $mija   = "mija";
    my $mitejn = "mitejn";
    my @hund_prefix = (
        q{},            # 0
        q{},            # 1
        q{},            # 2
        "tliet",        # 3
        "erba'",        # 4  erba' mija
        "ħames",        # 5  ħames mija (alt: hames)
        "sitt",         # 6
        "seba'",        # 7
        "tminn",        # 8
        "disa'",        # 9
    );

    # Thousand forms — construct-state prefixes for 3-10
    my $elf    = "elf";
    my $elfejn = "elfejn";
    my @thou_prefix = (
        q{},            # 0
        q{},            # 1
        q{},            # 2
        "tlitt",        # 3  tlitt elef
        "erbat",        # 4
        "ħamest",       # 5
        "sitt",         # 6
        "sebat",        # 7
        "tmint",        # 8
        "disat",        # 9
        "għaxart",      # 10 għaxart elef
    );
    my $elef = "elef";      # plural form for 3-10

    # Million forms
    my $miljun    = "miljun";
    my $miljunejn = "żewġ miljuni";   # 2 million

    return $ones[0] if $positive == 0;

    return _convert($positive, \@ones, \@tens_word, \@teens,
                    $u, $mija, $mitejn, \@hund_prefix,
                    $elf, $elfejn, $elef, \@thou_prefix,
                    $miljun, $miljunejn);
}

# }}}
# {{{ _convert                          recursive number-to-word engine

sub _convert {
    my ($n, $ones, $tens_word, $teens,
        $u, $mija, $mitejn, $hund_prefix,
        $elf, $elfejn, $elef, $thou_prefix,
        $miljun, $miljunejn) = @_;

    my @params = ($ones, $tens_word, $teens,
                  $u, $mija, $mitejn, $hund_prefix,
                  $elf, $elfejn, $elef, $thou_prefix,
                  $miljun, $miljunejn);

    return q{} if $n == 0;

    # --- Millions ---
    if ($n >= 1_000_000) {
        my $millions = int($n / 1_000_000);
        my $remain   = $n % 1_000_000;

        my $out;
        if ($millions == 1) {
            $out = $miljun;
        }
        elsif ($millions == 2) {
            $out = $miljunejn;
        }
        else {
            $out = _convert($millions, @params) . " $miljun";
        }

        if ($remain) {
            $out .= "${u}" . _convert($remain, @params);
        }
        return $out;
    }

    # --- Thousands ---
    if ($n >= 1000) {
        my $thousands = int($n / 1000);
        my $remain    = $n % 1000;

        my $out;
        if ($thousands == 1) {
            $out = $elf;
        }
        elsif ($thousands == 2) {
            $out = $elfejn;
        }
        elsif ($thousands >= 3 && $thousands <= 10) {
            $out = $thou_prefix->[$thousands] . " $elef";
        }
        else {
            # 11+ thousands: compound number + elf
            $out = _convert($thousands, @params) . " $elf";
        }

        if ($remain) {
            $out .= "${u}" . _convert($remain, @params);
        }
        return $out;
    }

    # --- Hundreds ---
    if ($n >= 100) {
        my $hundreds = int($n / 100);
        my $remain   = $n % 100;

        my $out;
        if ($hundreds == 1) {
            $out = $mija;
        }
        elsif ($hundreds == 2) {
            $out = $mitejn;
        }
        else {
            $out = $hund_prefix->[$hundreds] . " $mija";
        }

        if ($remain) {
            $out .= "${u}" . _convert($remain, @params);
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
            return $ones->[$unit] . "${u}" . $tens_word->[$ten_idx];
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

Lingua::MLT::Num2Word - Number to word conversion in Maltese

=head1 VERSION

version 0.2603270

Lingua::MLT::Num2Word is module for converting numbers into their written
representation in Maltese (Malti). Converts whole numbers from 0 up to
999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::MLT::Num2Word;

 my $text = Lingua::MLT::Num2Word::num2mlt_cardinal( 123 );

 print $text || "sorry, can't convert this number into Maltese.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2mlt_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string (UTF-8 Maltese)
      undef  if input number is not known

Convert number to text representation in Maltese.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<_convert> (positional)

  Internal recursive conversion engine. Not exported.

=item B<capabilities> (void)

  =>  hashref  with keys 'cardinal' and 'ordinal'

Returns a hashref describing supported conversion types.
Currently: cardinal => 1, ordinal => 0.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2mlt_cardinal

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
