# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::DAN::Num2Word;
# ABSTRACT: Number to word conversion in Danish

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

# {{{ num2dan_cardinal                 convert number to text

sub num2dan_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(nul en to tre fire fem seks syv otte ni ti elleve tolv);
    my @teens   = qw(tretten fjorten femten seksten sytten atten nitten);
    my @tokens2 = qw(tyve tredive fyrre halvtreds tres halvfjerds firs halvfems);

    return $tokens1[$positive]              if ($positive >= 0 && $positive < 13); # 0 .. 12
    return $teens[$positive - 13]           if ($positive > 12 && $positive < 20); # 13 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 100) {              # 20 .. 99
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain]og" if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 99 && $positive < 1000) {         # 100 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        # Danish uses "et" (neuter) before hundrede, not "en" (common)
        my $prefix = $one_idx == 1 ? 'et' : $tokens1[$one_idx];
        $out  = "${prefix}hundrede";
        $out .= $remain ? num2dan_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {   # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2dan_cardinal($one_idx).'tusind';
        $out .= $remain ? num2dan_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        $out  = num2dan_cardinal($one_idx) . ' million';
        $out .= 'er' if ($one_idx > 1);
        $out .= $remain ? ' ' . num2dan_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ num2dan_ordinal                 convert number to ordinal text

sub num2dan_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular 1-3
    return 'første' if $number == 1;
    return 'anden'  if $number == 2;
    return 'tredje' if $number == 3;

    # Irregular 4-12
    my %irregular = (
         4 => 'fjerde',
         5 => 'femte',
         6 => 'sjette',
         7 => 'syvende',
         8 => 'ottende',
         9 => 'niende',
        10 => 'tiende',
        11 => 'ellevte',
        12 => 'tolvte',
    );
    return $irregular{$number} if exists $irregular{$number};

    # 13-19: teens
    my %teens = (
        13 => 'trettende',
        14 => 'fjortende',
        15 => 'femtende',
        16 => 'sekstende',
        17 => 'syttende',
        18 => 'attende',
        19 => 'nittende',
    );
    return $teens{$number} if exists $teens{$number};

    # Tens ordinal forms (exact multiples)
    my %tens_ord = (
        20 => 'tyvende',
        30 => 'tredivte',
        40 => 'fyrretyvende',
        50 => 'halvtredsindstyvende',
        60 => 'tresindstyvende',
        70 => 'halvfjerdsindstyvende',
        80 => 'firsindstyvende',
        90 => 'halvfemsindstyvende',
    );

    # 20-99
    if ($number < 100) {
        my $tens = int($number / 10) * 10;
        my $ones = $number % 10;
        return $tens_ord{$tens} if $ones == 0;

        # Compound: cardinal ones + "og" + tens ordinal
        my @tokens1 = qw(nul en to tre fire fem seks syv otte ni);
        return $tokens1[$ones] . 'og' . $tens_ord{$tens};
    }

    # 100-999
    if ($number < 1000) {
        my $hundreds = int($number / 100);
        my $remain   = $number % 100;

        if ($remain == 0) {
            my $prefix = $hundreds == 1 ? 'et' : num2dan_cardinal($hundreds);
            return "${prefix}hundrede";
        }
        my $prefix = $hundreds == 1 ? 'et' : num2dan_cardinal($hundreds);
        return "${prefix}hundrede" . num2dan_ordinal($remain);
    }

    # 1000-999_999
    if ($number < 1_000_000) {
        my $remain = $number % 1000;
        if ($remain == 0) {
            return num2dan_cardinal(int($number / 1000)) . 'tusinde';
        }
        return num2dan_cardinal(int($number / 1000)) . 'tusind' . num2dan_ordinal($remain);
    }

    # 1_000_000 - 999_999_999
    if ($number < 1_000_000_000) {
        my $millions = int($number / 1_000_000);
        my $remain   = $number % 1_000_000;

        if ($remain == 0) {
            my $base = num2dan_cardinal($millions);
            my $suf  = $millions > 1 ? 'er' : '';
            return "$base million${suf}te";
        }
        my $base = num2dan_cardinal($millions);
        my $suf  = $millions > 1 ? 'er' : '';
        return "$base million${suf} " . num2dan_ordinal($remain);
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

Lingua::DAN::Num2Word - Number to word conversion in Danish


=head1 VERSION

version 0.2603270

Lingua::DAN::Num2Word is module for converting numbers into their written
representation in Danish. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DAN::Num2Word;

 my $text = Lingua::DAN::Num2Word::num2dan_cardinal( 123 );
 print $text || "sorry, can't convert this number into danish language.";

 my $ord = Lingua::DAN::Num2Word::num2dan_ordinal( 3 );
 print $ord;    # "tredje"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2dan_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2dan_ordinal> (positional)

  1   num    number to convert (1 .. 999_999_999)
  =>  str    converted ordinal string

Convert number to its Danish ordinal text representation.
Handles irregular forms (første, anden, tredje, etc.)
and applies correct suffixes for regular forms.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2dan_cardinal

=item num2dan_ordinal

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
