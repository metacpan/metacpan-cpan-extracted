# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::CES::Word2Num;
# ABSTRACT: Word 2 number conversion in CES.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Encode                    qw(decode_utf8);
use Parse::RecDescent;
use Perl6::Export::Attrs;

# }}}
# {{{ variables

our $VERSION = 0.0682;

my $parser   = ces_numerals();

# }}}

# {{{ w2n                       convert number to text

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ ces_numerals               create parser for numerals

sub ces_numerals {
    return Parse::RecDescent->new(decode_utf8(q{
      numeral:      <rulevar: local $number = 0>
      numeral:       million
                    { return $item[1]; }
                  |  thousand
                    { return $item[1]; }
                  |  century
                    { return $item[1]; }
                  |  decade
                    { return $item[1]; }
                  | { return undef; }

      number:       'dvanáct'      { $return = 12; }
                  | 'třináct'      { $return = 13; }
                  | 'čtrnáct'      { $return = 14; }
                  | 'patnáct'      { $return = 15; }
                  | 'šestnáct'     { $return = 16; }
                  | 'sedmnáct'     { $return = 17; }
                  | 'osmnáct'      { $return = 18; }
                  | 'devatenáct'   { $return = 19; }
                  | 'nula'         { $return =  0; }
                  | 'jedna'        { $return =  1; }
                  | 'dva'          { $return =  2; }
                  | 'tři'          { $return =  3; }
                  | 'čtyři'        { $return =  4; }
                  | 'pět'          { $return =  5; }
                  | 'šest'         { $return =  6; }
                  | 'sedm'         { $return =  7; }
                  | 'osm'          { $return =  8; }
                  | 'devět'        { $return =  9; }
                  | 'deset'        { $return = 10; }
                  | 'jedenáct'     { $return = 11; }

      tens:       'dvacet'         { $return = 20; }
                | 'třicet'         { $return = 30; }
                | 'čtyřicet'       { $return = 40; }
                | 'padesát'        { $return = 50; }
                | 'šedesát'        { $return = 60; }
                | 'sedmdesát'      { $return = 70; }
                | 'osmdesát'       { $return = 80; }
                | 'devadesát'      { $return = 90; }

      decade:      tens number
        { $return = $item[1] + $item[2]; }
        | tens
        { $return = $item[1]; }
        | number
        { $return = $item[1]; }

      century:  number 'sta' decade
                { $return = $item[1] * 100  + $item[3]; }
                | number 'sta'
                { $return = $item[1] * 100 }
                | number 'set' decade
                { $return = $item[1] * 100 + $item[3]; }
                | number 'set'
                { $return = $item[1] * 100 }
                | 'dvě' 'stě' decade
                { $return = 2 * 100 + $item[3]; }
                | 'dvě' 'stě'
                { $return = 2 * 100; }
                | 'sto' decade
                { $return = 100 + $item[2]; }
                | 'sto'
                { $return = 100; }

    thousand:     century thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | century thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | century thousands
                { $return = $item[1] * 1000; }

                | decade thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | decade thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | decade thousands
                { $return = $item[1] * 1000; }

                | number thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | number thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | number thousands
                { $return = $item[1] * 1000; }

                | 'tisíc' century
                { $return = 1000 + $item[2]; }
                | 'tisíc' decade
                { $return = 1000 + $item[2]; }
                | 'tisíc'
                { $return = 1000; }

                | century 'jeden' 'tisíc' century
                { $return = ($item[1] + 1) * 1000 + $item[4]; }
                | century 'jeden' 'tisíc' decade
                { $return = ($item[1] + 1) * 1000 + $item[4]; }

                | decade 'jeden' 'tisíc' century
                { $return = ($item[1] + 1) * 1000 + $item[4]; }
                | decade 'jeden' 'tisíc' decade
                { $return = ($item[1] + 1) * 1000 + $item[4]; }

                | century 'jeden' 'tisíc'
                { $return = ($item[1] + 1) * 1000; }
                | decade 'jeden' 'tisíc'
                { $return = ($item[1] + 1) * 1000; }

    thousands:    'tisíce'
                | 'tisíc'

    million:      century millions thousand
                { $return = $item[1] * 1_000_000 + $item[3]; }
                |  century millions century
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | century millions decade
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | century millions
                { $return = $item[1] * 1_000_000; }

                | decade millions thousand
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions century
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions decade
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions
                { $return = $item[1] * 1_000_000; }

                | 'milion' thousand
                { $return = 1_000_000 + $item[2]; }
                | 'milion' century
                { $return = 1_000_000 + $item[2]; }
                | 'milion' decade
                { $return = 1_000_000 + $item[2]; }
                | 'milion'
                { $return = 1_000_000; }

                | century 'jeden' 'milion' thousand
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | century 'jeden' 'milion' century
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | century 'jeden' 'milion' decade
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }

                | decade 'jeden' 'milion' thousand
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | decade 'jeden' 'milion' century
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | decade 'jeden' 'milion' decade
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }

    millions:     'miliony'
                | 'milionů'

    }));
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::CES::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Czech.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::CES::Word2Num;

 my $num = Lingua::CES::Word2Num::w2n( 'dvacet' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in CES.

Lingua::CES::Word2Num is module for converting text containing number
representation in czech back into number. Converts whole numbers from 0 up
to 999 999 999.

=cut

# }}}
# {{{ Functions Reference

=pod

=head2 Functions Reference

=over 2

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item ces_numerals

Internal parser.

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 EXPORT_OK

w2n

=head1 KNOWN BUGS

None.

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek <info@petamem.com>
 initial coding after specifications by R. Jelinek:
   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
