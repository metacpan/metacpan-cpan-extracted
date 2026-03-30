# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::ISL::Num2Word;
# ABSTRACT: Number to word conversion in Icelandic

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

# {{{ num2isl_cardinal                 convert number to text

sub num2isl_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # 0 .. 19: unique words
    my @tokens1 = qw(núll einn tveir þrír fjórir fimm sex sjö átta níu
                      tíu ellefu tólf);
    my @teens   = qw(þrettán fjórtán fimmtán sextán sautján átján nítján);

    # tens
    my @tokens2 = qw(tuttugu þrjátíu fjörutíu fimmtíu sextíu sjötíu áttatíu níutíu);

    # neuter forms for use with hundrað/þúsund (both neuter nouns)
    my @neuter  = qw(núll eitt tvö þrjú fjögur fimm sex sjö átta níu);

    return $tokens1[$positive]              if ($positive >= 0 && $positive < 13); # 0 .. 12
    return $teens[$positive - 13]           if ($positive > 12 && $positive < 20); # 13 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens arrays
    my $remain;       # remainder

    if ($positive > 19 && $positive < 100) {              # 20 .. 99
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = $tokens2[$one_idx - 2];
        $out .= " og $tokens1[$remain]" if ($remain);
    }
    elsif ($positive > 99 && $positive < 1000) {         # 100 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        # hundrað is neuter: eitt hundrað, tvö hundruð, ...
        if ($one_idx == 1) {
            $out = 'hundrað';
        }
        else {
            $out = "$neuter[$one_idx] hundruð";
        }
        $out .= $remain ? ' og ' . num2isl_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {   # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        # þúsund is neuter and invariable
        if ($one_idx == 1) {
            $out = 'þúsund';
        }
        elsif ($one_idx < 5) {
            $out = num2isl_neuter($one_idx) . ' þúsund';
        }
        else {
            $out = num2isl_cardinal($one_idx) . ' þúsund';
        }
        $out .= $remain ? ' og ' . num2isl_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        if ($one_idx == 1) {
            $out = 'ein milljón';
        }
        else {
            $out = num2isl_cardinal($one_idx) . ' milljónir';
        }
        $out .= $remain ? ' og ' . num2isl_cardinal($remain) : '';
    }

    return $out;
}

# }}}
# {{{ num2isl_neuter                   neuter form for small numbers

sub num2isl_neuter {
    my $n = shift;
    my @neuter = qw(núll eitt tvö þrjú fjögur);
    return $neuter[$n] if ($n >= 0 && $n <= 4);
    return num2isl_cardinal($n);
}

# }}}


# {{{ num2isl_ordinal                  convert number to ordinal text

sub num2isl_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular forms (masculine nominative)
    my %irregular = (
        1  => 'fyrsti',
        2  => 'annar',
        3  => 'þriðji',
        4  => 'fjórði',
        5  => 'fimmti',
        6  => 'sjötti',
        7  => 'sjöundi',
        8  => 'áttundi',
        9  => 'níundi',
        10 => 'tíundi',
        11 => 'ellefti',
        12 => 'tólfti',
    );

    return $irregular{$number} if exists $irregular{$number};

    # 13-19: cardinal stem + "di"
    if ($number >= 13 && $number <= 19) {
        my %teens = (
            13 => 'þrettándi',
            14 => 'fjórtándi',
            15 => 'fimmtándi',
            16 => 'sextándi',
            17 => 'sautjándi',
            18 => 'átjándi',
            19 => 'nítjándi',
        );
        return $teens{$number};
    }

    # Compound numbers: ordinal applies to last component
    # For round tens (20,30,...), use specific ordinal tens
    my %ordinal_tens = (
        20 => 'tuttugasti',
        30 => 'þrítugasti',
        40 => 'fertugasti',
        50 => 'fimmtugasti',
        60 => 'sextugasti',
        70 => 'sjötugasti',
        80 => 'áttugasti',
        90 => 'nítugasti',
    );

    return $ordinal_tens{$number} if exists $ordinal_tens{$number};

    # 21-99 (non-round): cardinal tens + "og" + ordinal unit
    if ($number > 20 && $number < 100) {
        my @tens = qw(tuttugu þrjátíu fjörutíu fimmtíu sextíu sjötíu áttatíu níutíu);
        my $ten_idx = int($number / 10);
        my $remain  = $number % 10;
        return $tens[$ten_idx - 2] . ' og ' . num2isl_ordinal($remain);
    }

    # 100+: cardinal prefix + ordinal of the last part
    # Round hundreds/thousands/millions get suffix "asti"
    if ($number == 100)       { return 'hundraðasti' }
    if ($number == 1000)      { return 'þúsundasti' }
    if ($number == 1_000_000) { return 'milljónasti' }

    # For compound numbers above 100, build cardinal prefix + ordinal tail
    my $cardinal = num2isl_cardinal($number);

    # Numbers 20+ get "asti", under 20 get "di" (but those are handled above)
    return $cardinal . 'asti';
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

Lingua::ISL::Num2Word - Number to word conversion in Icelandic


=head1 VERSION

version 0.2603300

Lingua::ISL::Num2Word is module for converting numbers into their written
representation in Icelandic. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ISL::Num2Word;

 my $text = Lingua::ISL::Num2Word::num2isl_cardinal( 123 );

 print $text || "sorry, can't convert this number into icelandic language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2isl_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2isl_neuter> (positional)

  1   num    small number (0-4) to convert to neuter form
  =>  str    neuter form string

Internal helper for neuter number forms used with hundrað/þúsund.

=item B<num2isl_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to its Icelandic ordinal text representation (masculine nominative).
Only numbers from interval [1, 999_999_999] will be converted.
Handles irregular forms (fyrsti, annar, þriðji, etc.)
and applies correct suffixes.


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

=item num2isl_cardinal

=item num2isl_ordinal

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
