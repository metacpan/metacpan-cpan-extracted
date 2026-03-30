# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::ELL::Word2Num;
# ABSTRACT: Word to number conversion in Greek

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = ell_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ ell_numerals              create parser for greek numerals

sub ell_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       /δεκατ[εέ]σσερα/   { 14 }
                  | 'δεκατρία'          { 13 }
                  | 'δεκαπέντε'         { 15 }
                  | /δεκα[εέ]ξι/        { 16 }
                  | 'δεκαεπτά'          { 17 }
                  | 'δεκαεφτά'          { 17 }
                  | 'δεκαοκτώ'          { 18 }
                  | 'δεκαοχτώ'          { 18 }
                  | /δεκαενν[εέ]α/      { 19 }
                  | 'δεκαεννιά'         { 19 }
                  | 'μηδέν'             {  0 }
                  | /[εέ]να[ςσ]?/       {  1 }
                  | /μ[ίι]α/            {  1 }
                  | 'δύο'               {  2 }
                  | /τρ[εί][ιί]?[αςσ]/ {  3 }
                  | /τ[εέ]σσερ[αι]ς?/  {  4 }
                  | 'πέντε'             {  5 }
                  | 'έξι'               {  6 }
                  | /ε[πφ]τά/           {  7 }
                  | /ο[κχ]τώ/           {  8 }
                  | /ενν[εέ]α/          {  9 }
                  | 'εννιά'             {  9 }
                  | 'δέκα'              { 10 }
                  | 'έντεκα'            { 11 }
                  | 'δώδεκα'            { 12 }

      tens:         'είκοσι'            { 20 }
                  | 'τριάντα'           { 30 }
                  | 'σαράντα'           { 40 }
                  | 'πενήντα'           { 50 }
                  | 'εξήντα'            { 60 }
                  | 'εβδομήντα'         { 70 }
                  | 'ογδόντα'           { 80 }
                  | 'ενενήντα'          { 90 }

      deca:         tens number             { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        'εννιακόσια' deca       { 900 + $item[2] }
                  | 'εννιακόσια'            { 900            }
                  | 'οκτακόσια' deca         { 800 + $item[2] }
                  | 'οκτακόσια'             { 800            }
                  | 'επτακόσια' deca         { 700 + $item[2] }
                  | 'επτακόσια'             { 700            }
                  | 'εξακόσια' deca          { 600 + $item[2] }
                  | 'εξακόσια'              { 600            }
                  | 'πεντακόσια' deca        { 500 + $item[2] }
                  | 'πεντακόσια'            { 500            }
                  | 'τετρακόσια' deca        { 400 + $item[2] }
                  | 'τετρακόσια'            { 400            }
                  | 'τριακόσια' deca         { 300 + $item[2] }
                  | 'τριακόσια'             { 300            }
                  | 'διακόσια' deca          { 200 + $item[2] }
                  | 'διακόσια'              { 200            }
                  | /εκατόν?/ deca           { 100 + $item[2] }
                  | 'εκατό'                 { 100            }

      hOd:        hecto
                | deca

      kilo:       hOd /χιλι[αά]δες/ hOd  { $item[1] * 1000 + $item[3] }
                | hOd /χιλι[αά]δες/       { $item[1] * 1000            }
                | 'χίλια' hOd             { 1000 + $item[2]            }
                | 'χίλια'                 { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /εκατομμ[υύ]ρι[οα]/ kOhOd  { $item[1] * 1_000_000 + $item[3] }
                | hOd /εκατομμ[υύ]ρι[οα]/         { $item[1] * 1_000_000 }
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Greek ordinals are adjectival, ending in -ος/-η/-ο (masc/fem/neut).
    # Strip grammatical endings first, then map stems to cardinal text.
    # Compounds (11+): "δέκατος τρίτος" → split on space, convert each part.

    # Full-form lookups for special compound ordinals (11th, 12th)
    # that don't decompose into stem + adjectival ending cleanly.
    my %full_form = (
        'ενδέκατος'  => 'έντεκα',
        'ενδέκατη'   => 'έντεκα',
        'ενδέκατο'   => 'έντεκα',
        'δωδέκατος'  => 'δώδεκα',
        'δωδέκατη'   => 'δώδεκα',
        'δωδέκατο'   => 'δώδεκα',
    );

    return $full_form{$input} if exists $full_form{$input};

    # Greek cardinals 13-19 are fused single words (δεκατρία, δεκατέσσερα, etc.)
    # but ordinals are two words (δέκατος τρίτος). The generic compound handler
    # would produce "δέκα τρία" (two words) which the parser cannot handle.
    # Map these directly to the fused cardinal forms.
    my %teen_ordinal_unit = (
        'τρίτος'    => 'δεκατρία',       'τρίτη'    => 'δεκατρία',       'τρίτο'    => 'δεκατρία',
        'τέταρτος'  => 'δεκατέσσερα',    'τέταρτη'  => 'δεκατέσσερα',    'τέταρτο'  => 'δεκατέσσερα',
        'πέμπτος'   => 'δεκαπέντε',      'πέμπτη'   => 'δεκαπέντε',      'πέμπτο'   => 'δεκαπέντε',
        'έκτος'     => 'δεκαέξι',        'έκτη'     => 'δεκαέξι',        'έκτο'     => 'δεκαέξι',
        'έβδομος'   => 'δεκαεφτά',       'έβδομη'   => 'δεκαεφτά',       'έβδομο'   => 'δεκαεφτά',
        'όγδοος'    => 'δεκαοχτώ',       'όγδοη'    => 'δεκαοχτώ',       'όγδοο'    => 'δεκαοχτώ',
        'ένατος'    => 'δεκαεννιά',      'ένατη'    => 'δεκαεννιά',      'ένατο'    => 'δεκαεννιά',
    );

    if ($input =~ m{\A (δέκατος|δέκατη|δέκατο) \s+ (.+) \z}xms) {
        my $unit = $2;
        return $teen_ordinal_unit{$unit} if exists $teen_ordinal_unit{$unit};
    }

    my %ordinal_to_cardinal = (
        'πρώτ'     => 'ένα',
        'δεύτερ'   => 'δύο',
        'τρίτ'     => 'τρία',
        'τέταρτ'   => 'τέσσερα',
        'πέμπτ'    => 'πέντε',
        'έκτ'      => 'έξι',
        'έβδομ'    => 'εφτά',
        'όγδο'     => 'οχτώ',
        'ένατ'     => 'εννιά',
        'δέκατ'    => 'δέκα',
        'εικοστ'   => 'είκοσι',
        'τριακοστ' => 'τριάντα',
        'τεσσαρακοστ' => 'σαράντα',
        'πεντηκοστ'   => 'πενήντα',
        'εξηκοστ'     => 'εξήντα',
        'εβδομηκοστ'  => 'εβδομήντα',
        'ογδοηκοστ'   => 'ογδόντα',
        'ενενηκοστ'   => 'ενενήντα',
        'εκατοστ'         => 'εκατό',
        'διακοσιοστ'      => 'διακόσια',
        'τριακοσιοστ'     => 'τριακόσια',
        'τετρακοσιοστ'    => 'τετρακόσια',
        'πεντακοσιοστ'    => 'πεντακόσια',
        'εξακοσιοστ'      => 'εξακόσια',
        'επτακοσιοστ'     => 'επτακόσια',
        'οκτακοσιοστ'     => 'οκτακόσια',
        'εννεακοσιοστ'    => 'εννιακόσια',
        'χιλιοστ'         => 'χίλια',
        'εκατομμυριοστ'   => 'ένα εκατομμύριο',
    );

    # Compound ordinals: "εκατοστός δέκατος τρίτος" → convert with teen fusion.
    # Adjacent "δέκατος/η/ο + unit" pairs must fuse into teen cardinals.
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;
        my @cardinals;
        my $i = 0;
        while ($i < @words) {
            # Check for teen pair: δέκατος/η/ο followed by a unit ordinal
            if ($i + 1 < @words && $words[$i] =~ m{\A δέκατ(?:ος|η|ο) \z}xms) {
                my $teen_try = $words[$i] . ' ' . $words[$i + 1];
                my $teen_card = ordinal2cardinal($teen_try);
                if (defined $teen_card) {
                    push @cardinals, $teen_card;
                    $i += 2;
                    next;
                }
            }
            my $card = ordinal2cardinal($words[$i]) // return;
            push @cardinals, $card;
            $i++;
        }
        return join ' ', @cardinals;
    }

    # Strip adjectival ending: -ος, -η, -ο (with possible final ς)
    my $stem = $input;
    $stem =~ s{(?:ος|ός|η|ή|ο|ό)\z}{}xms;

    return $ordinal_to_cardinal{$stem} if exists $ordinal_to_cardinal{$stem};

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::ELL::Word2Num - Word to number conversion in Greek


=head1 VERSION

version 0.2603300

Lingua::ELL::Word2Num is a module for converting Modern Greek numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

Follows Modern Standard Greek orthography (Triantafyllidis / single-ν forms).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ELL::Word2Num;

 my $num = Lingua::ELL::Word2Num::w2n( 'δεκαεπτά' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'πρώτος', 'δέκατος τρίτος')
  =>  str    cardinal text (e.g. 'ένα', 'δέκα τρία')
      undef  if input is not recognised as an ordinal

Convert Greek ordinal text to cardinal text (morphological reversal).
Handles masculine (-ος), feminine (-η), and neuter (-ο) endings.
Compounds are split on whitespace and each part is converted.

=item B<ell_numerals> (void)

  =>  obj  new parser object

Internal parser.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item w2n

=item ordinal2cardinal

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
