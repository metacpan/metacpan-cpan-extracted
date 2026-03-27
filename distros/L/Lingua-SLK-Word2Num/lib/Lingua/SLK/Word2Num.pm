# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SLK::Word2Num;
# ABSTRACT: Word to number conversion in Slovak

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = slk_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ slk_numerals                 create parser for numerals

sub slk_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'nula'          {  0 }
             |                 {    }

       number:  'dvanásť'      { 12 }
             |  'trinásť'      { 13 }
             |  'štrnásť'      { 14 }
             |  'pätnásť'      { 15 }
             |  'šestnásť'     { 16 }
             |  'sedemnásť'    { 17 }
             |  'osemnásť'     { 18 }
             |  'devätnásť'    { 19 }
             |  'jedenásť'     { 11 }
             |  'jedna'        {  1 }
             |  'jeden'        {  1 }
             |  'dva'          {  2 }
             |  'dve'          {  2 }
             |  'tri'          {  3 }
             |  'štyri'        {  4 }
             |  'päť'          {  5 }
             |  'šesť'         {  6 }
             |  'sedem'        {  7 }
             |  'osem'         {  8 }
             |  'deväť'        {  9 }
             |  'desať'        { 10 }

         tens:  'dvadsať'      { 20 }
             |  'tridsať'      { 30 }
             |  'štyridsať'    { 40 }
             |  'päťdesiat'    { 50 }
             |  'šesťdesiat'   { 60 }
             |  'sedemdesiat'  { 70 }
             |  'osemdesiat'   { 80 }
             |  'deväťdesiat'  { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  'deväťsto' deca   { 900 + $item[2] }
             |  'deväťsto'        { 900             }
             |  'osemsto' deca    { 800 + $item[2]  }
             |  'osemsto'         { 800             }
             |  'sedemsto' deca   { 700 + $item[2]  }
             |  'sedemsto'        { 700             }
             |  'šesťsto' deca    { 600 + $item[2]  }
             |  'šesťsto'         { 600             }
             |  'päťsto' deca     { 500 + $item[2]  }
             |  'päťsto'          { 500             }
             |  'štyristo' deca   { 400 + $item[2]  }
             |  'štyristo'        { 400             }
             |  'tristo' deca     { 300 + $item[2]  }
             |  'tristo'          { 300             }
             |  'dvesto' deca     { 200 + $item[2]  }
             |  'dvesto'          { 200             }
             |  'sto' deca        { 100 + $item[2]  }
             |  'sto'             { 100             }

          hOd:  hecto
             |  deca

         kilo:  hOd /tisíce?/ hOd        { $item[1] * 1000 + $item[3]       }
             |  hOd /tisíce?/            { $item[1] * 1000                  }
             |  number /tisíce?/ hOd     { $item[1] * 1000 + $item[3]       }
             |  number /tisíce?/         { $item[1] * 1000                  }
             |  'tisíc' hOd              { 1000 + $item[2]                  }
             |  'tisíc'                  { 1000                             }
             |  hOd 'jeden' 'tisíc' hOd  { ($item[1] + 1) * 1000 + $item[4] }
             |  hOd 'jeden' 'tisíc'      { ($item[1] + 1) * 1000            }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }
             |  'milión' kOhOd              { 1_000_000 + $item[2]                  }
             |  'milión'                    { 1_000_000                             }
             |  hOd 'jeden' 'milión' kOhOd  { ($item[1] + 1) * 1_000_000 + $item[4] }

        megas:  /milión(y|ov)/
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SLK::Word2Num - Word to number conversion in Slovak


=head1 VERSION

version 0.2603260

Lingua::SLK::Word2Num is module for converting Slovak numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SLK::Word2Num;

 my $num = Lingua::SLK::Word2Num::w2n( 'dvadsať' );

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

=item B<slk_numerals> (void)

  =>  obj  object of the parser

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
