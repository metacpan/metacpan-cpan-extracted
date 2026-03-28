# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SLV::Word2Num;
# ABSTRACT: Word to number conversion in Slovenian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = slv_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ slv_numerals                 create parser for numerals

sub slv_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | "nič"           {  0 }
             |                 {    }

       number:  'enajst'       { 11 }
             |  'dvanajst'     { 12 }
             |  'trinajst'     { 13 }
             |  "štirinajst"  { 14 }
             |  'petnajst'     { 15 }
             |  "šestnajst"   { 16 }
             |  'sedemnajst'   { 17 }
             |  'osemnajst'    { 18 }
             |  'devetnajst'   { 19 }
             |  'ena'          {  1 }
             |  'en'           {  1 }
             |  'eno'          {  1 }
             |  'dve'          {  2 }
             |  'dva'          {  2 }
             |  'tri'          {  3 }
             |  "štiri"       {  4 }
             |  'pet'          {  5 }
             |  "šest"        {  6 }
             |  'sedem'        {  7 }
             |  'osem'         {  8 }
             |  'devet'        {  9 }
             |  'deset'        { 10 }

         tens:  'dvajset'      { 20 }
             |  'trideset'     { 30 }
             |  "štirideset"  { 40 }
             |  'petdeset'     { 50 }
             |  "šestdeset"   { 60 }
             |  'sedemdeset'   { 70 }
             |  'osemdeset'    { 80 }
             |  'devetdeset'   { 90 }

         deca:  number 'in' tens  { $item[1] + $item[3] }
             |  tens number       { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /sto/  deca     { $item[1] * 100 + $item[3] }
             |  number /sto/           { $item[1] * 100            }
             |  'dvesto' deca          { 200 + $item[2]            }
             |  'dvesto'               { 200                       }
             |  'tristo' deca          { 300 + $item[2]            }
             |  'tristo'               { 300                       }
             |  "štiristo" deca   { 400 + $item[2]            }
             |  "štiristo"        { 400                       }
             |  'petsto' deca          { 500 + $item[2]            }
             |  'petsto'               { 500                       }
             |  "šeststo" deca    { 600 + $item[2]            }
             |  "šeststo"         { 600                       }
             |  'sedemsto' deca        { 700 + $item[2]            }
             |  'sedemsto'             { 700                       }
             |  'osemsto' deca         { 800 + $item[2]            }
             |  'osemsto'              { 800                       }
             |  'devetsto' deca        { 900 + $item[2]            }
             |  'devetsto'             { 900                       }
             |  'sto' deca             { 100 + $item[2]            }
             |  'sto'                  { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd "tisoč" hOd       { $item[1] * 1000 + $item[3]       }
             |  hOd "tisoč"            { $item[1] * 1000                  }
             |  number "tisoč" hOd     { $item[1] * 1000 + $item[3]       }
             |  number "tisoč"         { $item[1] * 1000                  }
             |  "tisoč" hOd            { 1000 + $item[2]                  }
             |  "tisoč"                { 1000                             }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }
             |  'en' 'milijon' kOhOd        { 1_000_000 + $item[3]                  }
             |  'en' 'milijon'              { 1_000_000                              }
             |  'milijon' kOhOd             { 1_000_000 + $item[2]                  }
             |  'milijon'                   { 1_000_000                              }

        megas:  'milijonov'
             |  'milijone'
             |  'milijona'
             |  'milijon'
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SLV::Word2Num - Word to number conversion in Slovenian


=head1 VERSION

version 0.2603270

Lingua::SLV::Word2Num is module for converting Slovenian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SLV::Word2Num;

 my $num = Lingua::SLV::Word2Num::w2n( 'dvajset' );

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

=item B<slv_numerals> (void)

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
