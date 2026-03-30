# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::RON::Num2Word;
# ABSTRACT: Number to word conversion in Romanian

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

# {{{ num2ron_cardinal                 convert number to text

sub num2ron_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @units = ('zero', 'unu', 'doi', 'trei', 'patru', 'cinci',
                 'șase', 'șapte', 'opt', 'nouă');

    my @teens = ('zece', 'unsprezece', 'doisprezece', 'treisprezece',
                 'paisprezece', 'cincisprezece', 'șaisprezece',
                 'șaptesprezece', 'optsprezece', 'nouăsprezece');

    my @tens = ('', '', 'douăzeci', 'treizeci', 'patruzeci', 'cincizeci',
                'șaizeci', 'șaptezeci', 'optzeci', 'nouăzeci');

    return $units[$positive]          if ($positive >= 0 && $positive < 10);
    return $teens[$positive - 10]     if ($positive >= 10 && $positive < 20);

    my $out;
    my $remain;

    if ($positive > 19 && $positive < 100) {                   # 20 .. 99
        my $ten_idx = int($positive / 10);
        $remain     = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' și ' . $units[$remain] if ($remain);
    }
    elsif ($positive == 100) {                                 # 100
        $out = 'o sută';
    }
    elsif ($positive > 100 && $positive < 200) {               # 101 .. 199
        $remain = $positive % 100;
        $out = 'o sută ' . num2ron_cardinal($remain);
    }
    elsif ($positive >= 200 && $positive < 1000) {             # 200 .. 999
        my $hun_idx = int($positive / 100);
        $remain     = $positive % 100;

        $out = $hun_idx == 2
            ? 'două sute'
            : num2ron_cardinal($hun_idx) . ' sute';
        $out .= ' ' . num2ron_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 2000) {            # 1000 .. 1999
        $remain = $positive % 1000;

        $out = 'o mie';
        $out .= ' ' . num2ron_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2000 && $positive < 1_000_000) {       # 2000 .. 999_999
        my $tho_idx = int($positive / 1000);
        $remain     = $positive % 1000;

        $out = $tho_idx == 2
            ? 'două mii'
            : num2ron_cardinal($tho_idx) . ' mii';
        $out .= ' ' . num2ron_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 2_000_000) {  # 1_000_000 .. 1_999_999
        $remain = $positive % 1_000_000;

        $out = 'un milion';
        $out .= ' ' . num2ron_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2_000_000 && $positive < 1_000_000_000) { # 2_000_000 .. 999_999_999
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out = $mil_idx == 2
            ? 'două milioane'
            : num2ron_cardinal($mil_idx) . ' milioane';
        $out .= ' ' . num2ron_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}


# {{{ num2ron_ordinal                  convert number to ordinal text

sub num2ron_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Irregular ordinals 1-10
    my %irregular = (
        1  => 'primul',
        2  => 'al doilea',
        3  => 'al treilea',
        4  => 'al patrulea',
        5  => 'al cincilea',
        6  => 'al șaselea',
        7  => 'al șaptelea',
        8  => 'al optulea',
        9  => 'al nouălea',
        10 => 'al zecelea',
    );

    return $irregular{$number} if exists $irregular{$number};

    # For 11+, form: "al" + cardinal + "lea"
    my $cardinal = num2ron_cardinal($number);

    return 'al ' . $cardinal . 'lea';
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

Lingua::RON::Num2Word - Number to word conversion in Romanian


=head1 VERSION

version 0.2603300

Lingua::RON::Num2Word is module for converting numbers into their written
representation in Romanian. Converts whole numbers from 0 up to 999 999 999.

Text output is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::RON::Num2Word;

 my $text = Lingua::RON::Num2Word::num2ron_cardinal( 123 );

 print $text || "sorry, can't convert this number into Romanian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ron_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2ron_ordinal> (positional)

  1   num    number to convert
  =>  str    ordinal string (e.g. 'primul', 'al doilea')

Convert number to its Romanian ordinal form.
Only numbers from interval [1, 999_999_999] will be converted.

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

=item num2ron_cardinal

=item num2ron_ordinal

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
