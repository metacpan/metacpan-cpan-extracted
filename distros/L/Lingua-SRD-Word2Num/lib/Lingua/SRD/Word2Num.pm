# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::SRD::Word2Num;
# ABSTRACT: Word to number conversion in Sardinian (Logudorese)

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = srd_numerals();

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
# {{{ srd_numerals                                 create parser for numerals

sub srd_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >
      <nocheck>

      numeral:  mega
             |  kOhOd
             |  'zeru'   { 0 }
             |           {   }

       number:  'deghesete'    { 17 }
             |  'degheoto'     { 18 }
             |  'deghenoe'     { 19 }
             |  'undighi'      { 11 }
             |  'doighi'       { 12 }
             |  'treighi'      { 13 }
             |  'batordighi'   { 14 }
             |  'bindighi'     { 15 }
             |  'seighi'       { 16 }
             |  'deghe'        { 10 }
             |  'bintunu'      { 21 }
             |  'bintiduos'    { 22 }
             |  'bintitres'    { 23 }
             |  'bintibàtoro'  { 24 }
             |  'bintichimbe'  { 25 }
             |  'bintises'     { 26 }
             |  'bintisete'    { 27 }
             |  'bintioto'     { 28 }
             |  'bintinoe'     { 29 }
             |  'binti'        { 20 }
             |  'trintunu'     { 31 }
             |  'trintatres'   { 33 }
             |  'barantunu'    { 41 }
             |  'barantaduos'  { 42 }
             |  'chinbantunu'  { 51 }
             |  'sessantunu'   { 61 }
             |  'setantunu'    { 71 }
             |  'otantunu'     { 81 }
             |  'nonantunu'    { 91 }
             |  'chimbe'       {  5 }
             |  'sete'         {  7 }
             |  'ses'          {  6 }
             |  'oto'          {  8 }
             |  'noe'          {  9 }
             |  'unu'          {  1 }
             |  'duos'         {  2 }
             |  'tres'         {  3 }
             |  'bàtoro'       {  4 }

         tens:  'trinta'       { 30 }
             |  'baranta'      { 40 }
             |  'chinbanta'    { 50 }
             |  'sessanta'     { 60 }
             |  'setanta'      { 70 }
             |  'otanta'       { 80 }
             |  'nonanta'      { 90 }

     hundreds:  'nobi' /chentos?/       { 900 }
             |  'oto'  /chentos?/       { 800 }
             |  'sete' /chentos?/       { 700 }
             |  'ses'  /chentos?/       { 600 }
             |  'chinbi' /chentos?/     { 500 }
             |  'bator' /chentos?/      { 400 }
             |  'tre'  /chentos?/       { 300 }
             |  'du'   /chentos?/       { 200 }
             |  /chentu/                { 100 }

         deca:  tens number             { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  hundreds deca           { $item[1] + $item[2] }
             |  hundreds

          hOd:  hecto
             |  deca

         kilo:  'duamiza' hOd           { 2000 + $item[2] }
             |  'duamiza'              { 2000 }
             |  hOd 'miza' hOd         { $item[1] * 1000 + $item[3] }
             |  hOd 'miza'             { $item[1] * 1000 }
             |  hOd milnotmeg hOd      { $item[1] * 1000 + $item[3] }
             |  hOd milnotmeg          { $item[1] * 1000 }
             |      milnotmeg hOd      { 1000 + $item[2] }
             |      milnotmeg          { 1000 }

    milnotmeg:   ...!'milione' ...!'miliones' 'milli'

        kOhOd:  kilo
             |  hOd

         mega:  hOd 'miliones' kOhOd   { $item[1] * 1_000_000 + $item[3] }
             |  hOd 'miliones'         { $item[1] * 1_000_000 }
             |  number 'milione' kOhOd { $item[1] * 1_000_000 + $item[3] }
             |  number 'milione'       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SRD::Word2Num - Word to number conversion in Sardinian (Logudorese)


=head1 VERSION

version 0.2603270

Lingua::SRD::Word2Num is a module for converting text containing number
representation in Sardinian (Logudorese variant) back into number. Converts
whole numbers from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SRD::Word2Num qw(w2n);

 my $num = w2n( 'chentu bintitres' );

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

=item B<srd_numerals> (void)

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
