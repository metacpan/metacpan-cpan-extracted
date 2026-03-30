# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::LIT::Word2Num;
# ABSTRACT: Word to number conversion in Lithuanian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = lit_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s{\s\z}{}xms;

    return $parser->numeral($input);
}

# }}}
# {{{ lit_numerals                  create parser for Lithuanian numerals

sub lit_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'nulis'            {  0 }
             |                    {    }

       number:  'vienuolika'      { 11 }
             |  'dvylika'         { 12 }
             |  'trylika'         { 13 }
             |  'keturiolika'     { 14 }
             |  'penkiolika'      { 15 }
             |  'šešiolika'       { 16 }
             |  'septyniolika'    { 17 }
             |  'aštuoniolika'    { 18 }
             |  'devyniolika'     { 19 }
             |  'vienas'          {  1 }
             |  'du'              {  2 }
             |  'trys'            {  3 }
             |  'keturi'          {  4 }
             |  'penki'           {  5 }
             |  'šeši'            {  6 }
             |  'septyni'         {  7 }
             |  'aštuoni'         {  8 }
             |  'devyni'          {  9 }
             |  'dešimt'          { 10 }

         tens:  'dvidešimt'         { 20 }
             |  'trisdešimt'        { 30 }
             |  'keturiasdešimt'    { 40 }
             |  'penkiasdešimt'     { 50 }
             |  'šešiasdešimt'      { 60 }
             |  'septyniasdešimt'   { 70 }
             |  'aštuoniasdešimt'   { 80 }
             |  'devyniasdešimt'    { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /šimt(as|ai|ų)/ deca  { $item[1] * 100 + $item[3] }
             |  number /šimt(as|ai|ų)/       { $item[1] * 100            }

          hOd:  hecto
             |  deca

         kilo:  hOd /tūkstanči(ai|ų)|tūkstantis/ hOd  { $item[1] * 1000 + $item[3] }
             |  hOd /tūkstanči(ai|ų)|tūkstantis/       { $item[1] * 1000            }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd  { $item[1] * 1_000_000 + $item[3] }
             |  hOd megas        { $item[1] * 1_000_000             }

        megas:  /milijon(as|ai|ų)/
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Lithuanian ordinals are adjectival with -as/-a (masc/fem) endings.
    # Most have unique stems that must be mapped to cardinal forms.
    # Compounds: space-separated, only last element is ordinal.

    my %ordinal_to_cardinal = (
        'pirmas'      => 'vienas',
        'pirma'       => 'vienas',
        'antras'      => 'du',
        'antra'       => 'du',
        'trečias'     => 'trys',
        'trečia'      => 'trys',
        'ketvirtas'   => 'keturi',
        'ketvirta'    => 'keturi',
        'penktas'     => 'penki',
        'penkta'      => 'penki',
        'šeštas'      => 'šeši',
        'šešta'       => 'šeši',
        'septintas'   => 'septyni',
        'septinta'    => 'septyni',
        'aštuntas'    => 'aštuoni',
        'aštunta'     => 'aštuoni',
        'devintas'    => 'devyni',
        'devinta'     => 'devyni',
        'dešimtas'    => 'dešimt',
        'dešimta'     => 'dešimt',
        # Teens
        'vienuoliktas'   => 'vienuolika',
        'vienuolikta'    => 'vienuolika',
        'dvyliktas'      => 'dvylika',
        'dvylikta'       => 'dvylika',
        'tryliktas'      => 'trylika',
        'trylikta'       => 'trylika',
        'keturioliktas'  => 'keturiolika',
        'keturiolikta'   => 'keturiolika',
        'penkioliktas'   => 'penkiolika',
        'penkiolikta'    => 'penkiolika',
        'šešioliktas'    => 'šešiolika',
        'šešiolikta'     => 'šešiolika',
        'septynioliktas' => 'septyniolika',
        'septyniolikta'  => 'septyniolika',
        'aštuonioliktas' => 'aštuoniolika',
        'aštuoniolikta'  => 'aštuoniolika',
        'devynioliktas'  => 'devyniolika',
        'devyniolikta'   => 'devyniolika',
    );

    # Hundreds/thousands ordinals with special stems:
    # Standalone: "šimtasis" → "vienas šimtas", "tūkstantasis" → "vienas tūkstantis"
    # Compound: "du šimtasis" → "du šimtai", "penki tūkstantasis" → "penki tūkstantis"
    if ($input =~ m{šimtasis\z}xms || $input =~ m{tūkstantasis\z}xms) {
        if ($input eq 'šimtasis')      { return 'vienas šimtas' }
        if ($input eq 'tūkstantasis')  { return 'vienas tūkstantis' }
        $input =~ s{šimtasis\z}{šimtai}xms         and return $input;
        $input =~ s{tūkstantasis\z}{tūkstantis}xms and return $input;
    }

    # Compound: "dvidešimt trečias" → convert last part only
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;
        my $last  = pop @words;
        my $cardinal = ordinal2cardinal($last) // return;
        push @words, $cardinal;
        return join ' ', @words;
    }

    return $ordinal_to_cardinal{$input} if exists $ordinal_to_cardinal{$input};

    # Tens ordinals: strip -as/-a ending
    # dvidešimtas → dvidešimt, trisdešimtas → trisdešimt, etc.
    if ($input =~ s{(?:as|a)\z}{}xms) {
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

Lingua::LIT::Word2Num - Word to number conversion in Lithuanian


=head1 VERSION

version 0.2603300

Lingua::LIT::Word2Num is module for converting Lithuanian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LIT::Word2Num;

 my $num = Lingua::LIT::Word2Num::w2n( 'dvidešimt trys' );

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
You can specify a numeral from interval [0, 999_999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'pirmas', 'trečias', 'dešimtas')
  =>  str    cardinal text (e.g. 'vienas', 'trys', 'dešimt')
      undef  if input is not recognised as an ordinal

Convert Lithuanian ordinal text to cardinal text (morphological reversal).
Handles both masculine (-as) and feminine (-a) endings.
Compounds are split on whitespace and the last part is converted.

=item B<lit_numerals> (void)

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
