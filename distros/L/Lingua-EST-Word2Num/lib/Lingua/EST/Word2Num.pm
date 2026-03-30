# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::EST::Word2Num;
# ABSTRACT: Word to number conversion in Estonian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = est_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ est_numerals              create parser for estonian numerals

sub est_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'üksteist'            { 11 }
                  | 'kaksteist'           { 12 }
                  | 'kolmteist'           { 13 }
                  | 'neliteist'           { 14 }
                  | 'viisteist'           { 15 }
                  | 'kuusteist'           { 16 }
                  | 'seitseteist'         { 17 }
                  | 'kaheksateist'        { 18 }
                  | 'üheksateist'         { 19 }
                  | 'kümme'              { 10 }
                  | 'null'                {  0 }
                  | 'üks'                {  1 }
                  | 'kaks'                {  2 }
                  | 'kolm'                {  3 }
                  | 'neli'                {  4 }
                  | 'viis'                {  5 }
                  | 'kuus'                {  6 }
                  | 'seitse'              {  7 }
                  | 'kaheksa'             {  8 }
                  | 'üheksa'             {  9 }

      tens:         'kakskümmend'        { 20 }
                  | 'kolmkümmend'        { 30 }
                  | 'nelikümmend'        { 40 }
                  | 'viiskümmend'        { 50 }
                  | 'kuuskümmend'        { 60 }
                  | 'seitsekümmend'      { 70 }
                  | 'kaheksakümmend'     { 80 }
                  | 'üheksakümmend'      { 90 }

      deca:         tens number           { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'sada' deca    { $item[1] * 100 + $item[3] }
                  | number 'sada'         { $item[1] * 100            }
                  | 'sada' deca           { 100 + $item[2]            }
                  | 'sada'                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tuhat' hOd         { $item[1] * 1000 + $item[3] }
                | hOd 'tuhat'             { $item[1] * 1000            }
                | 'tuhat' hOd             { 1000 + $item[2]            }
                | 'tuhat'                 { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /miljonit?/ kOhOd   { $item[1] * 1_000_000 + $item[3] }
                | hOd /miljonit?/         { $item[1] * 1_000_000 }
                | 'miljon' kOhOd          { 1_000_000 + $item[2] }
                | 'miljon'                { 1_000_000             }
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Estonian ordinals:
    #   esimene → üks (1st, suppletive)
    #   teine   → kaks (2nd, suppletive)
    #   Regular: stem + -s (kolmas→kolm, neljas→neli, etc.)
    #   -ne ending: kümnes→kümme (10th)
    # Compounds: only last element is ordinal, parts separated by space.

    my %irregular = (
        'esimene'  => 'üks',
        'teine'    => 'kaks',
    );

    # Compound: "kakskümmend kolmas" → split, convert last part
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;
        my $last  = pop @words;
        my $cardinal = ordinal2cardinal($last) // return;
        push @words, $cardinal;
        return join ' ', @words;
    }

    return $irregular{$input} if exists $irregular{$input};

    # Teens compound ordinals: e.g. "üheteistkümnes" → "üksteist"
    # The ordinal marker -kümnes is at the end for teens.
    # The teen ordinal stems differ from cardinal stems:
    #   ühe→üks, kahe→kaks, kolme→kolm, nelja→neli, viie→viis,
    #   kuue→kuus, seitse→seitse, kaheksa→kaheksa, üheksa→üheksa
    if ($input =~ m{\A (?<stem>.+) teistkümnes \z}xms) {
        my $stem = $+{stem};
        my %teen_ord_to_card = (
            'ühe'     => 'üks',
            'kahe'    => 'kaks',
            'kolme'   => 'kolm',
            'nelja'   => 'neli',
            'viie'    => 'viis',
            'kuue'    => 'kuus',
            'seitse'  => 'seitse',
            'kaheksa' => 'kaheksa',
            'üheksa'  => 'üheksa',
        );
        my $card_stem = $teen_ord_to_card{$stem} // $stem;
        return $card_stem . 'teist';
    }

    # Round tens ordinals: e.g. "kahekümnes" (20th) → "kakskümmend"
    # Stems: kahe→kaks, kolme→kolm, nelja→neli, viie→viis,
    #   kuue→kuus, seitse→seitse, kaheksa→kaheksa, üheksa→üheksa
    if ($input =~ m{\A (?<stem>.+) kümnes \z}xms) {
        my $stem = $+{stem};
        # Plain "kümnes" (10th) → "kümme"
        return 'kümme' if $stem eq '';

        my %tens_ord_to_card = (
            'kahe'    => 'kaks',
            'kolme'   => 'kolm',
            'nelja'   => 'neli',
            'viie'    => 'viis',
            'kuue'    => 'kuus',
            'seitse'  => 'seitse',
            'kaheksa' => 'kaheksa',
            'üheksa'  => 'üheksa',
        );
        my $card_stem = $tens_ord_to_card{$stem} // return;
        return $card_stem . 'kümmend';
    }

    # Standalone "kümnes" (10th)
    return 'kümme' if $input eq 'kümnes';

    # Thousands ordinals: "tuhandes" (1000th) → "tuhat"
    # In compounds: "viis tuhandes" → space-separated, handled by compound splitter above
    return 'tuhat' if $input eq 'tuhandes';

    # Hundreds ordinals: "sajas" (100th) → "sada", compounds: "kakssajas" → "kakssada"
    # The parser expects "sada" as the hundred token.
    if ($input =~ m{\A (?<pfx>.+?) sajas \z}xms) {
        my $pfx = $+{pfx};
        return 'sada' if $pfx eq '';
        # Compound: prefix is the cardinal multiplier (kaks, kolm, etc.)
        return $pfx . 'sada';
    }
    return 'sada' if $input eq 'sajas';

    # Regular: strip -s
    # Map known stems to cardinals the parser expects
    my %stem_to_cardinal = (
        'kolma'    => 'kolm',
        'nelja'    => 'neli',
        'viie'     => 'viis',
        'kuue'     => 'kuus',
        'seitsme'  => 'seitse',
        'kaheksa'  => 'kaheksa',
        'üheksa'   => 'üheksa',
    );

    if ($input =~ s{s\z}{}xms) {
        return $stem_to_cardinal{$input} if exists $stem_to_cardinal{$input};
        return $input;
    }

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::EST::Word2Num - Word to number conversion in Estonian


=head1 VERSION

version 0.2603300

Lingua::EST::Word2Num is module for converting Estonian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::EST::Word2Num;

 my $num = Lingua::EST::Word2Num::w2n( 'seitseteist' );

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

  1   str    ordinal text (e.g. 'esimene', 'kolmas', 'kümnes')
  =>  str    cardinal text (e.g. 'üks', 'kolm', 'kümme')
      undef  if input is not recognised as an ordinal

Convert Estonian ordinal text to cardinal text (morphological reversal).
Handles suppletive forms (esimene, teine), regular -s ordinals,
and compound forms.

=item B<est_numerals> (void)

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
