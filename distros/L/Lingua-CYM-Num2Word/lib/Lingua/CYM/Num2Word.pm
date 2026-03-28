# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::CYM::Num2Word;
# ABSTRACT: Number to word conversion in Welsh (Cymraeg)

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

# {{{ num2cym_cardinal                 convert number to text

sub num2cym_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # Basic digits 0-10
    my @ones = qw(dim un dau tri pedwar pump chwech saith wyth naw deg);

    # Tens in the modern decimal system: pum deg, chwe deg, etc.
    # Index 2 => dau ddeg (20), 3 => tri deg (30), ...
    my @tens = (
        undef,                  # 0 - unused
        undef,                  # 1 - 10 handled separately
        'dau ddeg',             # 20
        'tri deg',              # 30
        'pedwar deg',           # 40
        'pum deg',              # 50
        'chwe deg',             # 60
        'saith deg',            # 70
        'wyth deg',             # 80
        'naw deg',              # 90
    );

    return $ones[$positive]                 if $positive >= 0 && $positive <= 10;

    # 11-19: un deg un, un deg dau, ...
    if ($positive > 10 && $positive < 20) {
        my $unit = $ones[$positive - 10];
        return "un deg $unit";
    }

    my $out;
    my $remain;

    # 20-99
    if ($positive >= 20 && $positive < 100) {
        my $ten_idx = int($positive / 10);
        $remain     = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' ' . $ones[$remain] if $remain;
        return $out;
    }

    # 100-999
    if ($positive >= 100 && $positive < 1000) {
        my $hund_idx = int($positive / 100);
        $remain      = $positive % 100;

        $out = _hundreds($hund_idx);
        $out .= ' ' . num2cym_cardinal($remain) if $remain;
        return $out;
    }

    # 1000-999_999
    if ($positive >= 1000 && $positive < 1_000_000) {
        my $thou_idx = int($positive / 1000);
        $remain      = $positive % 1000;

        $out = _thousands($thou_idx);
        $out .= ' ' . num2cym_cardinal($remain) if $remain;
        return $out;
    }

    # 1_000_000-999_999_999
    if ($positive >= 1_000_000 && $positive < 1_000_000_000) {
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out = num2cym_cardinal($mil_idx) . ' miliwn';
        $out .= ' ' . num2cym_cardinal($remain) if $remain;
        return $out;
    }

    return;
}

# }}}
# {{{ _hundreds                         internal: hundreds word

sub _hundreds {
    my $n = shift;

    # Welsh mutations on "cant":
    #   1 => cant, 2 => dau gant (soft), 3 => tri chant (aspirate),
    #   4 => pedwar cant, 5 => pum cant, 6 => chwe chant (aspirate),
    #   7 => saith cant, 8 => wyth cant, 9 => naw cant
    my @h = (
        undef,
        'cant',             # 1
        'dau gant',         # 2
        'tri chant',        # 3
        'pedwar cant',      # 4
        'pum cant',         # 5
        'chwe chant',       # 6
        'saith cant',       # 7
        'wyth cant',        # 8
        'naw cant',         # 9
    );

    return $h[$n];
}

# }}}
# {{{ _thousands                        internal: thousands word

sub _thousands {
    my $n = shift;

    # Simple thousands: mil, dwy fil (2k uses feminine), tri mil, etc.
    # For simplicity using masculine forms and basic citation forms
    if ($n == 1) {
        return 'mil';
    }

    return num2cym_cardinal($n) . ' mil';
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

=head1 NAME

Lingua::CYM::Num2Word - Number to word conversion in Welsh (Cymraeg)


=head1 VERSION

version 0.2603270

Lingua::CYM::Num2Word is a module for converting numbers into their written
representation in Welsh, using the modern decimal counting system.
Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CYM::Num2Word;

 my $text = Lingua::CYM::Num2Word::num2cym_cardinal( 123 );
 print $text || "sorry, can't convert this number into Welsh.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2cym_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Welsh text representation using the modern decimal system.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<capabilities> (void)

  =>  hashref   hash of supported features

Returns a hashref indicating which conversion types are supported.
Currently: cardinal => 1, ordinal => 0.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2cym_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding (2026-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
