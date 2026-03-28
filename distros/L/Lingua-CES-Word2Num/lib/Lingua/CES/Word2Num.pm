# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::CES::Word2Num;
# ABSTRACT: Word to number conversion in Czech

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = ces_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ ces_numerals                 create parser for numerals

sub ces_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'nula'          {  0 }
             |                 {    }

       number:  'dvanáct'      { 12 }
             |  'třináct'      { 13 }
             |  'čtrnáct'      { 14 }
             |  'patnáct'      { 15 }
             |  'šestnáct'     { 16 }
             |  'sedmnáct'     { 17 }
             |  'osmnáct'      { 18 }
             |  'devatenáct'   { 19 }
             |  'jedna'        {  1 }
             |  'dva'          {  2 }
             |  'tři'          {  3 }
             |  'čtyři'        {  4 }
             |  'pět'          {  5 }
             |  'šest'         {  6 }
             |  'sedm'         {  7 }
             |  'osm'          {  8 }
             |  'devět'        {  9 }
             |  'deset'        { 10 }
             |  'jedenáct'     { 11 }

         tens:  'dvacet'       { 20 }
             |  'třicet'       { 30 }
             |  'čtyřicet'     { 40 }
             |  'padesát'      { 50 }
             |  'šedesát'      { 60 }
             |  'sedmdesát'    { 70 }
             |  'osmdesát'     { 80 }
             |  'devadesát'    { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /(sta|set)/ deca  { $item[1] * 100 + $item[3] }
             |  number /(sta|set)/       { $item[1] * 100            }
             |  'dvě' 'stě' deca         { 2 * 100 + $item[3]        }
             |  'dvě' 'stě'              { 2 * 100                   }
             |  'sto' deca               { 100 + $item[2]            }
             |  'sto'                    { 100                       }

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
             |  'milion' kOhOd              { 1_000_000 + $item[2]                  }
             |  'milion'                    { 1_000_000                             }
             |  hOd 'jeden' 'milion' kOhOd  { ($item[1] + 1) * 1_000_000 + $item[4] }

        megas:  /milion[yů]/
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::CES::Word2Num - Word to number conversion in Czech


=head1 VERSION

version 0.2603270

Lingua::CES::Word2Num is module for converting czech numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CES::Word2Num;

 my $num = Lingua::CES::Word2Num::w2n( 'dvacet' );

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

=item B<ces_numerals> (void)

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
 coding (until 2005):
   Roman Vasicek E<lt>info@petamem.comE<gt>
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
