# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::DEU::Word2Num;
# ABSTRACT: Word 2 Number conversion in DEU.

# {{{ use block

use 5.16.0;
use utf8;

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603231';
my $parser   = deu_numerals();

# }}}

# {{{ w2n                       convert number to text

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ deu_numerals              create parser for german numerals

sub deu_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'dreizehn'  { 13 }
                  | 'vierzehn'  { 14 }
                  | 'fünfzehn'  { 15 }
                  | 'sechzehn'  { 16 }
                  | 'siebzehn'  { 17 }
                  | 'achtzehn'  { 18 }
                  | 'neunzehn'  { 19 }
                  | 'null'      {  0 }
                  | /eine?/     {  1 }
                  | 'zwei'      {  2 }
                  | 'drei'      {  3 }
                  | 'vier'      {  4 }
                  | 'fünf'      {  5 }
                  | 'sechs'     {  6 }
                  | 'sieben'    {  7 }
                  | 'acht'      {  8 }
                  | 'neun'      {  9 }
                  | 'zehn'      { 10 }
                  | 'elf'       { 11 }
                  | 'zwölf'     { 12 }

      tens:         'zwanzig'   { 20 }
                  | 'dreissig'  { 30 }
                  | 'vierzig'   { 40 }
                  | 'fünfzig'   { 50 }
                  | 'sechzig'   { 60 }
                  | 'siebzig'   { 70 }
                  | 'achtzig'   { 80 }
                  | 'neunzig'   { 90 }

      deca:         'und' deca          { $item[2]            }
                  | number 'und' tens   { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number 'hundert' deca    { $item[1] * 100 + $item[3] }
                  | number 'hundert'         { $item[1] * 100            }
                  | 'hundert'                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tausend' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'tausend'        { $item[1] * 1000            }

      kOhOd:      kilo
                | hOd

      mega:       hOd /million(en)?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /million(en)?/       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::DEU::Word2Num  

=head1 VERSION

version 0.2603231

Word 2 Number conversion in DEU.

Lingua::DEU::Word2Num is module for converting german numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DEU::Word2Num;

 my $num = Lingua::DEU::Word2Num::w2n( 'siebzehn' );

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
You can specify a numeral from interval [0,999_999].


=item B<deu_numerals> (void)

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

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=cut

# }}}
