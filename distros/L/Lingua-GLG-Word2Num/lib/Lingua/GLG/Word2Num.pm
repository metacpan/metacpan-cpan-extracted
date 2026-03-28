# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::GLG::Word2Num;
# ABSTRACT: Word to number conversion in Galician

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = glg_numerals();

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
# {{{ glg_numerals                                 create parser for numerals

sub glg_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >
      <nocheck>

      numeral:  mega
             |  kOhOd
             |  'cero'   { 0 }
             |           {   }

       number:  'un'           {  1 }
             |  'dous'         {  2 }
             |  'tres'         {  3 }
             |  'catro'        {  4 }
             |  'cinco'        {  5 }
             |  'seis'         {  6 }
             |  'sete'         {  7 }
             |  'oito'         {  8 }
             |  'nove'         {  9 }
             |  'dezaseis'     { 16 }
             |  'dezasete'     { 17 }
             |  'dezaoito'     { 18 }
             |  'dezanove'     { 19 }
             |  'dez'          { 10 }
             |  'once'         { 11 }
             |  'doce'         { 12 }
             |  'trece'        { 13 }
             |  'catorce'      { 14 }
             |  'quince'       { 15 }

         tens:  'vinte'        { 20 }
             |  'trinta'       { 30 }
             |  'corenta'      { 40 }
             |  'cincuenta'    { 50 }
             |  'sesenta'      { 60 }
             |  'setenta'      { 70 }
             |  'oitenta'      { 80 }
             |  'noventa'      { 90 }

     hundreds:  'cincocentos'        { 500 }
             |  'setecentos'         { 700 }
             |  'novecentos'         { 900 }
             |  'oitocentos'         { 800 }
             |  'seiscentos'         { 600 }
             |  'catrocentos'        { 400 }
             |  'trescentos'         { 300 }
             |  'douscentos'         { 200 }
             |  /cen(to)?/           { 100 }

         deca:  tens 'e' number      { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  hundreds 'e' deca     { $item[1] + $item[3] }
             |  hundreds deca        { $item[1] + $item[2] }
             |  hundreds

          hOd:  hecto
             |  deca

         kilo:  hOd milnotmeg 'e' hOd { $item[1] * 1000 + $item[4] }
             |  hOd milnotmeg hOd    { $item[1] * 1000 + $item[3] }
             |  hOd milnotmeg        { $item[1] * 1000 }
             |      milnotmeg 'e' hOd { 1000 + $item[3] }
             |      milnotmeg hOd    { 1000 + $item[2] }
             |      milnotmeg        { 1000 }

    milnotmeg:   ...!/mill(ón|óns)/ 'mil'

        kOhOd:  kilo
             |  hOd

         mega:  hOd /mill(óns|ón)/ 'e' kOhOd  { $item[1] * 1_000_000 + $item[4] }
             |  hOd /mill(óns|ón)/ kOhOd     { $item[1] * 1_000_000 + $item[3] }
             |  hOd /mill(óns|ón)/            { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::GLG::Word2Num - Word to number conversion in Galician


=head1 VERSION

version 0.2603270

Lingua::GLG::Word2Num is a module for converting text containing number
representation in Galician back into number. Converts whole numbers from 0 up
to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::GLG::Word2Num;

 my $num = Lingua::GLG::Word2Num::w2n( 'vinte e sete' );

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

=item B<glg_numerals> (void)

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
