# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::CES::Word2Num;
# ABSTRACT: Word 2 number conversion in CES.

# {{{ use block

use v5.32;
use warnings;
use utf8;

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603230';
my $parser   = ces_numerals();

# }}}

# {{{ w2n                          convert number to text

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

=head2 Lingua::CES::Word2Num 

=head1 VERSION

version 0.2603230

Word 2 number conversion in CES.

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

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=cut

# }}}
