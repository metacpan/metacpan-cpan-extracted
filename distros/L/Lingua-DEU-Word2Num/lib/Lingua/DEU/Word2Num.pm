# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::DEU::Word2Num;
# ABSTRACT: Word 2 Number conversion in DEU.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Encode                    qw(decode_utf8);
use Parse::RecDescent;
use Perl6::Export::Attrs;

# }}}
# {{{ variables

our $VERSION = 0.1106;
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
    return Parse::RecDescent->new(decode_utf8(q{
      numeral:      <rulevar: local $number = 0>
      numeral:        scrap
                    { return undef; }
                  |   millenium
                    { return $item[1]; }
                  |  century
                    { return $item[1]; }
                  |  decade
                    { return $item[1]; }

      number:       'dreizehn'  { $return = 13; }
                  | 'vierzehn'  { $return = 14; }
                  | 'fünfzehn'  { $return = 15; }
                  | 'sechzehn'  { $return = 16; }
                  | 'siebzehn'  { $return = 17; }
                  | 'achtzehn'  { $return = 18; }
                  | 'neunzehn'  { $return = 19; }
                  | 'null'      { $return =  0; }
                  | 'ein'       { $return =  1; }
                  | 'zwei'      { $return =  2; }
                  | 'drei'      { $return =  3; }
                  | 'vier'      { $return =  4; }
                  | 'fünf'      { $return =  5; }
                  | 'sechs'     { $return =  6; }
                  | 'sieben'    { $return =  7; }
                  | 'acht'      { $return =  8; }
                  | 'neun'      { $return =  9; }
                  | 'zehn'      { $return = 10; }
                  | 'elf'       { $return = 11; }
                  | 'zwölf'     { $return = 12; }

      tens:       'zwanzig'  { $return = 20; }
                | 'dreissig' { $return = 30; }
                | 'vierzig'  { $return = 40; }
                | 'fünfzig'  { $return = 50; }
                | 'sechzig'  { $return = 60; }
                | 'siebzig'  { $return = 70; }
                | 'achtzig'  { $return = 80; }
                | 'neunzig'  { $return = 90; }

      decade:      'und' decade
                   { $return = $item[2]; }
                 |  number 'und' tens
                    { $return = $item[1] + $item[3]; }
                 | tens
                   { $return = $item[1]; }
                 | number
                   { $return = $item[1]; }

      century:  number 'hundert' decade
                { $return = $item[1] * 100 + $item[3]; }
                | number 'hundert'
                { $return = $item[1] * 100; }
                | 'hundert'
                { $return = 100; }

    millenium:    century 'tausend' century
                { $return = $item[1] * 1000 + $item[3]; }
                | century 'tausend' decade
                { $return = $item[1] * 1000 + $item[3]; }
                | decade  'tausend' century
                { $return = $item[1] * 1000 + $item[3]; }
                | decade  'tausend' decade
                { $return = $item[1] * 1000 + $item[3]; }
                | decade  'tausend'
                { $return = $item[1] * 1000; }
                | century 'tausend'
                { $return = $item[1] * 1000; }

      scrap:    millenium(?) century(?) decade(?)
                /(.+)/
                millenium(?) century(?) decade(?)
                {
                  carp("unknown numeral '$1' !\n");
                }
    }));
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::DEU::Word2Num  

=head1 VERSION

version 0.1106

Word 2 Number conversion in DEU.

Lingua::DEU::Word2Num is module for converting text containing number
representation in German back into number. Converts whole numbers from 0 up
to 999 999 999.

Text must be encoded in UTF-8.

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

Copyright (C) PetaMem, s.r.o. 2004-present

=cut

# }}}
