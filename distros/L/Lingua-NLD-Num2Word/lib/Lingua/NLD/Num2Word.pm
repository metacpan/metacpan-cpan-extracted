# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::NLD::Num2Word;
# ABSTRACT: Number to word conversion in Dutch

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Readonly;
use Export::Attrs;

# }}}
# {{{ var block

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2015-present';
our $VERSION = '0.2603300';

# }}}

# {{{ num2nld_cardinal                 convert number to text

sub num2nld_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(nul een twee drie vier vijf zes zeven acht negen tien
                     elf twaalf dertien veertien vijftien zestien zeventien achtien negentien);
    my @tokens2 = qw(twintig dertig veertig vijftig zestig zeventig tachtig negentig honderd);

    return $tokens1[$positive]           if ($positive >= 0 && $positive < 20); # 0 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 101) {              # 20 .. 100
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain]en" if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 100 && $positive < 1000) {       # 101 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = "$tokens1[$one_idx]honderd";
        $out .= $remain ? num2nld_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2nld_cardinal($one_idx) . 'duizend ';
        $out .= $remain ? num2nld_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        $out  = num2nld_cardinal($one_idx) . " miljoen";
        $out .= $remain ? ' ' . num2nld_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ num2nld_ordinal                 convert number to ordinal text

sub num2nld_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals
    return 'nulde'  if $number == 0;
    return 'eerste' if $number == 1;
    return 'tweede' if $number == 2;
    return 'derde'  if $number == 3;

    my $cardinal = num2nld_cardinal($number);

    # Numbers 1-19 and compounds ending in 1-19: add "de"
    # Numbers >= 20 that are round tens/hundreds/etc: add "ste"
    # Rule: 2-19 get "de", 20+ get "ste", compounds follow last element

    # Determine the suffix: "de" for 2-19, "ste" for >= 20
    # For compound numbers, it depends on the last component
    my $last_part = $number;
    if ($number >= 20) {
        $last_part = $number % 10;  # units digit
        if ($last_part == 0) {
            # Round number, use "ste"
            return $cardinal . 'ste';
        }
        # compound: the ordinal is based on the whole cardinal + suffix
        # For compounds with units 1-19: use "ste" (since total >= 20)
        return $cardinal . 'ste';
    }

    # 4-19: cardinal + "de"
    return $cardinal . 'de';
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

Lingua::NLD::Num2Word - Number to word conversion in Dutch


=head1 VERSION

version 0.2603300

Lingua::NLD::Num2Word is module for converting numbers into their written
representation in Dutch. Converts whole numbers from 0 up to 999 999 999.

Text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::NLD::Num2Word;

 my $text = Lingua::NLD::Num2Word::num2nld_cardinal( 123 );

 print $text || "sorry, can't convert this number into dutch.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2nld_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
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

=item num2nld_cardinal

=item num2nld_ordinal

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

Copyright (c) PetaMem, s.r.o. 2015-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
