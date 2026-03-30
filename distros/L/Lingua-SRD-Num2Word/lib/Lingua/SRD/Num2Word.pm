# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::SRD::Num2Word;
# ABSTRACT: Number to word conversion in Sardinian (Logudorese)

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ variable declarations

our $VERSION = '0.2603300';

my @ONES  = qw(zeru unu duos tres bàtoro chimbe ses sete oto noe);
my @TEENS = qw(deghe undighi doighi treighi batordighi bindighi seighi
               deghesete degheoto deghenoe);
my @TENS  = qw(_ _ binti trinta baranta chinbanta sessanta setanta otanta nonanta);

# Hundreds multiplier prefixes: 2-9
my @HUN_PREFIX = qw(_ _ du tre bator chinbi ses sete oto nobi);

# }}}

# {{{ num2srd_cardinal                 convert number to text

sub num2srd_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # 0–9
    return $ONES[$positive]              if $positive <= 9;

    # 10–19
    return $TEENS[$positive - 10]        if $positive >= 10 && $positive <= 19;

    # 20–99
    if ($positive >= 20 && $positive <= 99) {
        my $ten_idx = int($positive / 10);
        my $unit    = $positive % 10;

        return $TENS[$ten_idx]           if $unit == 0;

        my $ten_word = $TENS[$ten_idx];

        # Apocope: tens drop final vowel before "unu"
        if ($unit == 1) {
            $ten_word =~ s/[aeiou]$//;
            return $ten_word . $ONES[$unit];
        }

        return $ten_word . $ONES[$unit];
    }

    # 100–999
    if ($positive >= 100 && $positive <= 999) {
        my $hun_idx = int($positive / 100);
        my $remain  = $positive % 100;
        my $out;

        if ($hun_idx == 1) {
            $out = 'chentu';
        }
        else {
            $out = $HUN_PREFIX[$hun_idx] . 'chentos';
        }

        $out .= num2srd_cardinal($remain) if $remain;
        return $out;
    }

    # 1_000–999_999
    if ($positive >= 1_000 && $positive <= 999_999) {
        my $tho_idx = int($positive / 1000);
        my $remain  = $positive % 1000;
        my $out;

        if ($tho_idx == 1) {
            $out = 'milli';
        }
        elsif ($tho_idx == 2) {
            $out = 'duamiza';
        }
        else {
            $out = num2srd_cardinal($tho_idx) . 'miza';
        }

        $out .= num2srd_cardinal($remain) if $remain;
        return $out;
    }

    # 1_000_000–999_999_999
    if ($positive >= 1_000_000 && $positive <= 999_999_999) {
        my $mil_idx = int($positive / 1_000_000);
        my $remain  = $positive % 1_000_000;
        my $out;

        if ($mil_idx == 1) {
            $out = 'unu milione';
        }
        else {
            $out = num2srd_cardinal($mil_idx) . ' miliones';
        }

        $out .= ' ' . num2srd_cardinal($remain) if $remain;
        return $out;
    }

    return;
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

Lingua::SRD::Num2Word - Number to word conversion in Sardinian (Logudorese)


=head1 VERSION

version 0.2603300

Lingua::SRD::Num2Word is a module for converting numbers into their written
representation in Sardinian (Logudorese variant). Converts whole numbers
from 0 up to 999 999 999.

Output text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SRD::Num2Word qw(num2srd_cardinal);

 my $text = num2srd_cardinal( 123 );

 print $text || "sorry, can't convert this number into Sardinian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2srd_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Sardinian text representation.
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

=item num2srd_cardinal

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
