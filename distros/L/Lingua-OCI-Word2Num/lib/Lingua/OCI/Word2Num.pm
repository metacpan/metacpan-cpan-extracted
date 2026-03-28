# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::OCI::Word2Num;
# ABSTRACT: Word to number conversion in Occitan

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = oci_numerals();

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
# {{{ oci_numerals                                 create parser for numerals

sub oci_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >
      <nocheck>

      numeral:  mega
             |  kOhOd
             |  /z(?:e|è)ro/   { 0 }
             |                 {   }

       number:  'un'                  {  1 }
             |  'dos'                 {  2 }
             |  'tres'               {  3 }
             |  'quatre'             {  4 }
             |  'cinc'               {  5 }
             |  /si(?:e|è)is/        {  6 }
             |  /u(?:e|è)ch/         {  8 }
             |  /n(?:o|ò)u/          {  9 }
             |  /d(?:e|è)tz-e-s(?:e|è)t/   { 17 }
             |  /d(?:e|è)tz-e-u(?:e|è)ch/  { 18 }
             |  /d(?:e|è)tz-e-n(?:o|ò)u/   { 19 }
             |  /d(?:e|è)tz/         { 10 }
             |  'onze'               { 11 }
             |  'dotze'              { 12 }
             |  'tretze'             { 13 }
             |  /cat(?:o|ò)rze/      { 14 }
             |  'quinze'             { 15 }
             |  'setze'              { 16 }
             |  /s(?:e|è)t/          {  7 }
             |  'vint-e-un'          { 21 }
             |  'vint-e-dos'         { 22 }
             |  'vint-e-tres'        { 23 }
             |  'vint-e-quatre'      { 24 }
             |  'vint-e-cinc'        { 25 }
             |  /vint-e-si(?:e|è)is/ { 26 }
             |  /vint-e-s(?:e|è)t/   { 27 }
             |  /vint-e-u(?:e|è)ch/  { 28 }
             |  /vint-e-n(?:o|ò)u/   { 29 }
             |  'vint'               { 20 }

         tens:  'trenta'             { 30 }
             |  'quaranta'           { 40 }
             |  'cinquanta'          { 50 }
             |  'seissanta'          { 60 }
             |  'setanta'            { 70 }
             |  'ochanta'            { 80 }
             |  'nonanta'            { 90 }

     hundreds:  number /\-?\s?cents?/ { $item[1] * 100 }
             |  /cents?/              { 100 }

         deca:  tens /-e-/ number     { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  hundreds deca         { $item[1] + $item[2] }
             |  hundreds

          hOd:  hecto
             |  deca

         kilo:  hOd milnotmeg hOd    { $item[1] * 1000 + $item[3] }
             |  hOd milnotmeg        { $item[1] * 1000 }
             |      milnotmeg hOd    { 1000 + $item[2] }
             |      milnotmeg        { 1000 }

    milnotmeg:   ...!'milion' 'mila'

        kOhOd:  kilo
             |  hOd

         mega:  hOd /milions?/ kOhOd  { $item[1] * 1_000_000 + $item[3] }
             |  hOd /milions?/         { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::OCI::Word2Num - Word to number conversion in Occitan

=head1 VERSION

version 0.2603270

Lingua::OCI::Word2Num is a module for converting text containing number
representation in Occitan (Languedocien standard) back into number. Converts
whole numbers from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::OCI::Word2Num;

 my $num = Lingua::OCI::Word2Num::w2n( 'cent vint-e-tres' );

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

=item B<oci_numerals> (void)

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
