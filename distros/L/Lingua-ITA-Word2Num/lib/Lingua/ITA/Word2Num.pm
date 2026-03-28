# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::ITA::Word2Num;
# ABSTRACT: Word to number conversion in Italian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
our @EXPORT_OK  = qw(cardinal2num w2n);
my $parser      = ita_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}
# }}}
# {{{ ita_numerals                                create parser for numerals

sub ita_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:   mega
               | kOhOd
               | 'zero'   { 0 }
               | { }

      number:
              'undici'      { 11 }
        |     'tredici'     { 13 }
        |     'un'          {  1 }
        |     'due'         {  2 }
        |     'tre'         {  3 }
        |     'quattro'     {  4 }
        |     'cinque'      {  5 }
        |     'sei'         {  6 }
        |     'sette'       {  7 }
        |     'otto'        {  8 }
        |     'nove'        {  9 }
        |     'dieci'       { 10 }
        |     'dodici'      { 12 }
        |     'quattordici' { 14 }
        |     'quindici'    { 15 }
        |     'sedici'      { 16 }
        |     'diciassette' { 17 }
        |     'diciotto'    { 18 }
        |     'diciannove'  { 19 }

      tens:   'venti'     { 20 }
        |     /ventuno?/  { 21 }
        |     'ventotto'  { 28 }
        |     'trenta'    { 30 }
        |     'trent'     { 30 }
        |     'quaranta'  { 40 }
        |     'quarant'   { 40 }
        |     'cinquanta' { 50 }
        |     'cinquant'  { 50 }
        |     'sessanta'  { 60 }
        |     'sessant'   { 60 }
        |     'settanta'  { 70 }
        |     'settant'   { 70 }
        |     'ottanta'   { 80 }
        |     'ottant'    { 80 }
        |     'novanta'   { 90 }
        |     'novant'    { 90 }

      deca:   tens number          { $item[1] + $item[2] }
            | tens
            | number

      hecto:  number /cento/ deca    {  $item[1] * 100 + $item[3] }
            | number /cento/         {  $item[1] * 100 }
            |        /cento/ deca    {  100 + $item[2] }
            |        'cento'         { 100 }

      hOd:   hecto
           | deca

    kilo:    hOd  /mill?[ae]/ hOd  { $item[1] * 1000 + $item[3] }
           | hOd  /mill?[ae]/      { $item[1] * 1000 }
           |      /mill?[ae]/ hOd  { 1000 + $item[2] }
           |      /mill?[ae]/      { 1000 }

    kOhOd:   kilo
           | hOd

      mega: kOhOd /mill?ion[ei]/ kOhOd { $item[1] * 1_000_000 + $item[3] }

    });
}
# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::ITA::Word2Num - Word to number conversion in Italian


=head1 VERSION

version 0.2603270

Lingua::ITA::Word2Num is module for converting text containing number
representation in italian back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ITA::Word2Num;

 my $num = Lingua::ITA::Word2Num::w2n( 'trecentoquindici' );

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

=item B<ita_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2003-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
