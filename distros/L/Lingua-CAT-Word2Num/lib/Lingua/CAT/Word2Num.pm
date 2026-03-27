# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::CAT::Word2Num;
# ABSTRACT: Word to number conversion in Catalan

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = cat_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input = lc $input;
    $input =~ s/\s+/ /g;
    $input =~ s/^\s+|\s+$//g;

    return $parser->numeral($input);
}
# }}}
# {{{ cat_numerals                                 create parser for numerals

sub cat_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >
      <nocheck>

      numeral:  mega
             |  kOhOd
             |  'zero'   { 0 }
             |           {   }

       number:  'un'           {  1 }
             |  'una'          {  1 }
             |  'dos'          {  2 }
             |  'dues'         {  2 }
             |  'tres'         {  3 }
             |  'quatre'       {  4 }
             |  'cinc'         {  5 }
             |  'sis'          {  6 }
             |  'vuit'         {  8 }
             |  'nou'          {  9 }
             |  'deu'          { 10 }
             |  'onze'         { 11 }
             |  'dotze'        { 12 }
             |  'tretze'       { 13 }
             |  'catorze'      { 14 }
             |  'quinze'       { 15 }
             |  'setze'        { 16 }
             |  'disset'       { 17 }
             |  'divuit'       { 18 }
             |  'dinou'        { 19 }
             |  'set'          {  7 }
             |  'vint-i-un'    { 21 }
             |  'vint-i-una'   { 21 }
             |  'vint-i-dos'   { 22 }
             |  'vint-i-dues'  { 22 }
             |  'vint-i-tres'  { 23 }
             |  'vint-i-quatre' { 24 }
             |  'vint-i-cinc'  { 25 }
             |  'vint-i-sis'   { 26 }
             |  'vint-i-set'   { 27 }
             |  'vint-i-vuit'  { 28 }
             |  'vint-i-nou'   { 29 }
             |  'vint'         { 20 }

         tens:  'trenta'       { 30 }
             |  'quaranta'     { 40 }
             |  'cinquanta'    { 50 }
             |  'seixanta'     { 60 }
             |  'setanta'      { 70 }
             |  'vuitanta'     { 80 }
             |  'noranta'      { 90 }

     hundreds:  number /\-?cents?/      { $item[1] * 100 }
             |  /cents?/                { 100 }

         deca:  tens /-/ number         { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  hundreds deca           { $item[1] + $item[2] }
             |  hundreds

          hOd:  hecto
             |  deca

         kilo:  hOd milnotmeg hOd      { $item[1] * 1000 + $item[3] }
             |  hOd milnotmeg          { $item[1] * 1000 }
             |      milnotmeg hOd      { 1000 + $item[2] }
             |      milnotmeg          { 1000 }

    milnotmeg:   ...!'mili' 'mil'

        kOhOd:  kilo
             |  hOd

         mega:  hOd /mili(ons|ó)/ kOhOd    { $item[1] * 1_000_000 + $item[3] }
             |  hOd /mili(ons|ó)/           { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::CAT::Word2Num - Word to number conversion in Catalan


=head1 VERSION

version 0.2603260

Lingua::CAT::Word2Num is a module for converting text containing number
representation in Catalan back into number. Converts whole numbers from 0 up
to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CAT::Word2Num;

 my $num = Lingua::CAT::Word2Num::w2n( 'cent vint-i-tres' );

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

=item B<cat_numerals> (void)

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
