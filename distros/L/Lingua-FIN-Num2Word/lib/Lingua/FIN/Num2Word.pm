# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::FIN::Num2Word;
# ABSTRACT: Number to word conversion in Finnish

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

# {{{ num2fin_cardinal                 convert number to text

sub num2fin_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(nolla yksi kaksi kolme neljä viisi kuusi seitsemän kahdeksan yhdeksän);

    return $ones[$positive]                          if ($positive >= 0 && $positive < 10);
    return 'kymmenen'                                if ($positive == 10);
    return $ones[$positive - 10] . 'toista'          if ($positive > 10 && $positive < 20);

    my $out;
    my $remain;

    if ($positive > 19 && $positive < 100) {                           # 20 .. 99
        my $tens_idx = int($positive / 10);
        $remain      = $positive % 10;

        $out  = $ones[$tens_idx] . 'kymmentä';
        $out .= $ones[$remain] if ($remain);
    }
    elsif ($positive == 100) {                                         # 100
        $out = 'sata';
    }
    elsif ($positive > 100 && $positive < 1000) {                      # 101 .. 999
        my $hundreds = int($positive / 100);
        $remain      = $positive % 100;

        $out  = $hundreds == 1 ? 'sata' : $ones[$hundreds] . 'sataa';
        $out .= num2fin_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {               # 1000 .. 999_999
        my $thousands = int($positive / 1000);
        $remain       = $positive % 1000;

        $out  = $thousands == 1 ? 'tuhat' : num2fin_cardinal($thousands) . 'tuhatta';
        $out .= num2fin_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) {      # 1_000_000 .. 999_999_999
        my $millions = int($positive / 1_000_000);
        $remain      = $positive % 1_000_000;

        if ($millions == 1) {
            $out = 'miljoona';
        }
        else {
            $out = num2fin_cardinal($millions) . ' miljoonaa';
        }
        $out .= ' ' . num2fin_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}

# {{{ num2fin_ordinal                 convert number to ordinal text

sub num2fin_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # In Finnish, ordinals transform ALL components of a compound number.
    # 1st and 2nd are fully irregular; 3rd onward use the -s suffix
    # on a (sometimes modified) stem.

    # Irregular/base ordinal forms for 1-10
    my @ones_ord = (
        q{},              # 0 unused
        'ensimmäinen',    # 1
        'toinen',         # 2
        'kolmas',         # 3
        'neljäs',         # 4
        'viides',         # 5
        'kuudes',         # 6
        'seitsemäs',      # 7
        'kahdeksas',      # 8
        'yhdeksäs',       # 9
    );

    # Ordinal forms used as prefix in compound numbers (stem form)
    # In compounds like 21st, 1st becomes ensimmäinen, 2nd becomes toinen
    # but in teens (11-19), 1st->yhdes, 2nd->kahdes
    my @ones_compound = (
        q{},           # 0
        'yhdes',       # 1  (used in 11th: yhdestoista)
        'kahdes',      # 2  (used in 12th: kahdestoista)
        'kolmas',      # 3
        'neljäs',      # 4
        'viides',      # 5
        'kuudes',      # 6
        'seitsemäs',   # 7
        'kahdeksas',   # 8
        'yhdeksäs',    # 9
    );

    # Simple 1-9
    return $ones_ord[$number] if $number >= 1 && $number <= 9;

    # 10
    return 'kymmenes' if $number == 10;

    # 11-19: compound_ones + 'toista'
    if ($number > 10 && $number < 20) {
        return $ones_compound[$number - 10] . 'toista';
    }

    # Round tens: 20-90
    my @tens_prefix = (
        q{},           # 0
        q{},           # 10 handled above
        'kahdes',      # 20
        'kolmas',      # 30
        'neljäs',      # 40
        'viides',      # 50
        'kuudes',      # 60
        'seitsemäs',   # 70
        'kahdeksas',   # 80
        'yhdeksäs',    # 90
    );

    if ($number >= 20 && $number < 100) {
        my $ten_idx = int($number / 10);
        my $remain  = $number % 10;

        if ($remain == 0) {
            return $tens_prefix[$ten_idx] . 'kymmenes';
        }

        # Compound: tens-ordinal + ones-ordinal
        return $tens_prefix[$ten_idx] . 'kymmenes' . $ones_ord[$remain];
    }

    # 100-999
    if ($number >= 100 && $number < 1000) {
        my $hundreds = int($number / 100);
        my $remain   = $number % 100;

        if ($remain == 0) {
            return 'sadas' if $hundreds == 1;
            return $ones_ord[$hundreds] . 'sadas';
        }

        # Non-terminal hundreds use cardinal prefix form + "sata"
        my $prefix = $hundreds == 1 ? 'sata' : _fin_cardinal_prefix($hundreds) . 'sata';

        return $prefix . num2fin_ordinal($remain);
    }

    # 1000-999_999
    if ($number >= 1000 && $number < 1_000_000) {
        my $thousands = int($number / 1000);
        my $remain    = $number % 1000;

        if ($remain == 0) {
            return 'tuhannes' if $thousands == 1;
            return _fin_cardinal_prefix($thousands) . 'tuhannes';
        }

        # Non-terminal thousands use cardinal form
        my $prefix = $thousands == 1 ? 'tuhat' : num2fin_cardinal($thousands) . 'tuhatta';

        return $prefix . num2fin_ordinal($remain);
    }

    # 1_000_000-999_999_999
    if ($number >= 1_000_000 && $number < 1_000_000_000) {
        my $millions = int($number / 1_000_000);
        my $remain   = $number % 1_000_000;

        if ($remain == 0) {
            return 'miljoonas' if $millions == 1;
            return _fin_cardinal_prefix($millions) . 'miljoonas';
        }

        my $prefix;
        if ($millions == 1) {
            $prefix = 'miljoona';
        }
        else {
            $prefix = num2fin_cardinal($millions) . ' miljoonaa';
        }

        return $prefix . ' ' . num2fin_ordinal($remain);
    }

    return;
}

# }}}
# {{{ _fin_cardinal_prefix       cardinal form for non-terminal compound prefix

sub _fin_cardinal_prefix {
    my $n = shift;

    # For small numbers used as prefixes in ordinal compounds
    my @card = qw(nolla yksi kaksi kolme neljä viisi kuusi seitsemän kahdeksan yhdeksän);

    return $card[$n] if $n >= 1 && $n <= 9;

    return num2fin_cardinal($n);
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

Lingua::FIN::Num2Word - Number to word conversion in Finnish


=head1 VERSION

version 0.2603300

Lingua::FIN::Num2Word is module for converting numbers into their written
representation in Finnish. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FIN::Num2Word;

 my $text = Lingua::FIN::Num2Word::num2fin_cardinal( 123 );

 print $text || "sorry, can't convert this number into Finnish.";

 my $ord = Lingua::FIN::Num2Word::num2fin_ordinal( 3 );
 print $ord;    # "kolmas"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2fin_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2fin_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to ordinal text representation in Finnish.
Only numbers from interval [1, 999_999_999] will be converted.
Uses Finnish ordinal morphology where all components are transformed.


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

=item num2fin_cardinal

=item num2fin_ordinal

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
