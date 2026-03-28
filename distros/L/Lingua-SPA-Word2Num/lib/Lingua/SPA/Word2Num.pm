# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::SPA::Word2Num;
# ABSTRACT: Word to number conversion in Spanish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = spa_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}
# }}}
# {{{ spa_numerals                                 create parser for numerals

sub spa_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >
      <nocheck>

      numeral:  mega
             |  kOhOd
             |  'cero'   { 0 }
             |           {   }

       number:  'un'           {  1 }
             |  'dos'          {  2 }
             |  'tres'         {  3 }
             |  'cuatro'       {  4 }
             |  'cinco'        {  5 }
             |  'seis'         {  6 }
             |  'siete'        {  7 }
             |  'ocho'         {  8 }
             |  'nueve'        {  9 }
             |  'diez'         { 10 }
             |  'once'         { 11 }
             |  'doce'         { 12 }
             |  'trece'        { 13 }
             |  'catorce'      { 14 }
             |  'quince'       { 15 }
             |  'dieciséis'    { 16 }
             |  'diecisiete'   { 17 }
             |  'dieciocho'    { 18 }
             |  'diecinueve'   { 19 }
             |  'veinte'       { 20 }
             |  'veintiun'     { 21 }
             |  'veintidós'    { 22 }
             |  'veintitrés'   { 23 }
             |  'veinticuatro' { 24 }
             |  'veinticinco'  { 25 }
             |  'veintiséis'   { 26 }
             |  'veintisiete'  { 27 }
             |  'veintiocho'   { 28 }
             |  'veintinueve'  { 29 }

         tens:  'treinta'      { 30 }
             |  'cuarenta'     { 40 }
             |  'cincuenta'    { 50 }
             |  'sesenta'      { 60 }
             |  'setenta'      { 70 }
             |  'ochenta'      { 80 }
             |  'noventa'      { 90 }

     hundreds:  'quinientos'        { 500 }
             |  'setecientos'       { 700 }
             |  'novecientos'       { 900 }
             |  number /cientos?/   { $item[1] * 100 }
             |  /cien(to)?/         { 100 }

         deca:  tens 'y' number     { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  hundreds  deca      { $item[1] + $item[2] }
             |  hundreds

          hOd:  hecto
             |  deca

         kilo:  hOd  milnotmeg hOd        { $item[1] * 1000 + $item[3] }
             |  hOd  milnotmeg            { $item[1] * 1000 }
             |       milnotmeg hOd        { 1000 + $item[2] }
             |       milnotmeg            { 1000 }

    milnotmeg:   ...!'mill' 'mil'

        kOhOd:  kilo
             |  hOd

         mega:  hOd /mill(ones|ón)/ kOhOd     { $item[1] * 1_000_000 + $item[3] }
             |  hOd /mill(ones|ón)/           { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::SPA::Word2Num - Word to number conversion in Spanish


=head1 VERSION

version 0.2603270

Lingua::SPA::Word2Num is module for converting text containing number
representation in dutch back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SPA::Word2Num;

 my $num = Lingua::SPA::Word2Num::w2n( 'veintisiete' );

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

=item B<spa_numerals> (void)

  =>  obj  new parser object

Internal parser.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

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
