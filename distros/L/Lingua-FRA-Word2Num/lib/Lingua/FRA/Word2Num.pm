# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::FRA::Word2Num;
# ABSTRACT: Word to number conversion in French

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser      = fra_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ fra_numerals                                create parser for numerals

sub fra_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'zéro'       {  0 }
             |              {    }

       number:  'un'        {  1 }
             |  'deux'      {  2 }
             |  'trois'     {  3 }
             |  'quatre'    {  4 }
             |  'cinq'      {  5 }
             |  'six'       {  6 }
             |  'sept'      {  7 }
             |  'huit'      {  8 }
             |  'neuf'      {  9 }
             |  'dix-sept'  { 17 }
             |  'dix-huit'  { 18 }
             |  'dix-neuf'  { 19 }
             |  'dix'       { 10 }
             |  'onze'      { 11 }
             |  'douze'     { 12 }
             |  'treize'    { 13 }
             |  'quatorze'  { 14 }
             |  'quinze'    { 15 }
             |  'seize'     { 16 }

         tens:  'vingt'             { 20 }
             |  'trente'            { 30 }
             |  'quarante'          { 40 }
             |  'cinquante'         { 50 }
             |  'soixante-dix'      { 70 }
             |  'soixante'          { 60 }
             |  /quatre-vingts?/    { 80 }

         deca:  tens /-?/ number    { $item[1] + $item[3] }
             |  tens 'et' number    { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  number /cents?/ deca    {  $item[1] * 100 + $item[3] }
             |  number /cents?/         {  $item[1] * 100 }
             |         /cents?/ deca    {  100 + $item[2] }
             |         'cent'           { 100 }

          hOd:  hecto
             |  deca

         kilo:  hOd  /milles?/ hOd  { $item[1] * 1000 + $item[3] }
             |  hOd  /milles?/      { $item[1] * 1000 }
             |       /milles?/ hOd  { 1000 + $item[2] }
             |       'mille'        { 1000 }

        kOhOd:  kilo
             |  hOd

         mega:  kOhOd /millions?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
    });
}
# }}}
# {{{ ordinal2cardinal                              convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # French ordinals:
    #   "premier" / "première" → "un" (fully suppletive for 1st)
    #   All others: cardinal stem + "ième"
    #   Reverse stem changes: cinqu→cinq, neuv→neuf

    return 'un' if $input =~ m{\A premi(?:er|ère) \z}xms;

    # Must end with "ième" to be an ordinal
    $input =~ s{ième\z}{}xms or return;

    # Reverse stem changes
    $input =~ s{cinqu\z}{cinq}xms;
    $input =~ s{neuv\z}{neuf}xms;

    # French drops final -e before -ième (quatre→quatrième, onze→onzième).
    # Restore it unless the stem already ends in a vowel.
    $input .= 'e' if $input =~ m{[^aeiouyâêîôûéèëïü]\z}xms;

    return $input;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::FRA::Word2Num - Word to number conversion in French


=head1 VERSION

version 0.2603300

Lingua::FRA::Word2Num is module for converting text containing number
representation in French back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FRA::Word2Num;

 my $num = Lingua::FRA::Word2Num::w2n( 'cent vingt-trois' );

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
  =>  undef  if input string is not known

Convert text representation to number.

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'premier', 'deuxième', 'cinquième')
  =>  str    cardinal text (e.g. 'un', 'deux', 'cinq')
      undef  if input is not recognised as an ordinal

Convert French ordinal text to cardinal text (morphological reversal).

=item B<fra_numerals> (void)

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
