# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::HIN::Num2Word;
# ABSTRACT: Number to word conversion in Hindi

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
# {{{ lookup tables

my @ONES = qw(
    शून्य   एक      दो      तीन     चार
    पाँच    छह      सात     आठ      नौ
);

# Complete irregular forms 10-99 — Hindi requires full enumeration
my @FULL = (
    undef,  undef,  undef,  undef,  undef,     #  0- 4 (use @ONES)
    undef,  undef,  undef,  undef,  undef,     #  5- 9 (use @ONES)
    'दस',       'ग्यारह',    'बारह',      'तेरह',      'चौदह',       # 10-14
    'पंद्रह',     'सोलह',     'सत्रह',     'अट्ठारह',    'उन्नीस',     # 15-19
    'बीस',      'इक्कीस',    'बाईस',      'तेईस',      'चौबिस',      # 20-24
    'पच्चीस',    'छब्बीस',    'सत्ताईस',    'अट्ठाईस',    'उनतीस',      # 25-29
    'तीस',      'इकतीस',    'बत्तीस',     'तैंतीस',     'चौंतीस',      # 30-34
    'पैंतीस',     'छत्तीस',    'सैंतीस',     'अड़तीस',     'उनतालीस',    # 35-39
    'चालीस',    'इकतालीस',   'बयालीस',    'तैंतालीस',    'चौंतालीस',    # 40-44
    'पैंतालीस',   'छयालीस',    'सैंतालीस',    'अड़तालीस',   'उनचास',      # 45-49
    'पचास',     'इक्यावन',    'बावन',      'तिरेपन',     'चौवन',       # 50-54
    'पचपन',     'छप्पन',     'सत्तावन',    'अट्ठावन',    'उनसठ',       # 55-59
    'साठ',      'इकसठ',     'बासठ',      'तिरेसठ',     'चौंसठ',       # 60-64
    'पैंसठ',      'छयासठ',     'सरसठ',      'अड़सठ',      'उनहत्तर',     # 65-69
    'सत्तर',     'इकहत्तर',    'बहत्तर',     'तिहत्तर',     'चौहत्तर',     # 70-74
    'पचहत्तर',    'छिहत्तर',    'सतहत्तर',    'अठहत्तर',    'उन्यासी',     # 75-79
    'अस्सी',     'इक्यासी',    'बयासी',     'तिरासी',     'चौरासी',      # 80-84
    'पचासी',     'छियासी',    'सत्तासी',    'अठासी',     'नवासी',      # 85-89
    'नब्बे',      'इक्यानवे',   'बानवे',     'तिरानवे',    'चौरानवे',     # 90-94
    'पचानवे',    'छियानवे',    'सत्तानवे',    'अट्ठानवे',    'निन्यानवे',    # 95-99
);

# }}}

# {{{ _cardinal_below_100           internal: 0-99

sub _cardinal_below_100 {
    my $n = shift;
    return $ONES[$n]  if $n < 10;
    return $FULL[$n];
}

# }}}
# {{{ num2hin_cardinal               convert number to text

sub num2hin_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 99_99_99_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 99_99_99_999;

    # 0-99: direct lookup
    return _cardinal_below_100($positive) if $positive < 100;

    my $out = '';
    my $remain = $positive;

    # करोड़ (crore = 10^7)
    if ($remain >= 1_00_00_000) {
        my $crore = int($remain / 1_00_00_000);
        $remain   = $remain % 1_00_00_000;
        $out .= _build_chunk($crore) . ' करोड़';
    }

    # लाख (lakh = 10^5)
    if ($remain >= 1_00_000) {
        my $lakh = int($remain / 1_00_000);
        $remain  = $remain % 1_00_000;
        $out .= ' ' if length $out;
        $out .= _build_chunk($lakh) . ' लाख';
    }

    # हज़ार (hazaar = 10^3)
    if ($remain >= 1_000) {
        my $hazaar = int($remain / 1_000);
        $remain    = $remain % 1_000;
        $out .= ' ' if length $out;
        $out .= _build_chunk($hazaar) . ' हज़ार';
    }

    # सौ (sau = 10^2)
    if ($remain >= 100) {
        my $sau = int($remain / 100);
        $remain = $remain % 100;
        $out .= ' ' if length $out;
        $out .= _cardinal_below_100($sau) . ' सौ';
    }

    # remainder 1-99
    if ($remain > 0) {
        $out .= ' ' if length $out;
        $out .= _cardinal_below_100($remain);
    }

    return $out;
}

# }}}
# {{{ _build_chunk                   internal: render a sub-100 chunk (for multipliers)

sub _build_chunk {
    my $n = shift;
    return _cardinal_below_100($n) if $n < 100;

    # Multiplier can itself be up to 99 (e.g. 99 करोड़), so always < 100
    # But for safety, handle hundreds within multipliers
    my $h = int($n / 100);
    my $r = $n % 100;
    my $out = _cardinal_below_100($h) . ' सौ';
    $out .= ' ' . _cardinal_below_100($r) if $r > 0;
    return $out;
}

# }}}
# {{{ capabilities                   declare supported features

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

=encoding UTF-8

=head1 NAME

Lingua::HIN::Num2Word - Number to word conversion in Hindi

=head1 VERSION

version 0.2603300

Lingua::HIN::Num2Word is a module for converting numbers into their
written representation in Hindi (Devanagari script). Converts whole
numbers from 0 up to 99,99,99,999 (99 crore). Uses the Indian
numbering system (hundreds, thousands, lakhs, crores).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HIN::Num2Word;

 my $text = Lingua::HIN::Num2Word::num2hin_cardinal( 125 );
 print $text;    # "एक सौ पच्चीस"

 my $big = Lingua::HIN::Num2Word::num2hin_cardinal( 1_50_000 );
 print $big;     # "एक लाख पचास हज़ार"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2hin_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string in Devanagari
      undef  if input number is not known

Convert number to Hindi text representation.
Only numbers from interval [0, 99_99_99_999] will be converted.

=item B<capabilities> (void)

  =>  hashref  supported conversion types

Returns a hashref indicating which conversions are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2hin_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding:
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
