# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::HRV::Word2Num;
# ABSTRACT: Word to number conversion in Croatian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = hrv_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ hrv_numerals                 create parser for numerals

sub hrv_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'nula'          {  0 }
             |                 {    }

       number:  'jedanaest'    { 11 }
             |  'dvanaest'     { 12 }
             |  'trinaest'     { 13 }
             |  "četrnaest"   { 14 }
             |  'petnaest'     { 15 }
             |  "šesnaest"    { 16 }
             |  'sedamnaest'   { 17 }
             |  'osamnaest'    { 18 }
             |  'devetnaest'   { 19 }
             |  'jedan'        {  1 }
             |  'jedna'        {  1 }
             |  'dvije'        {  2 }
             |  'dva'          {  2 }
             |  'tri'          {  3 }
             |  "četiri"      {  4 }
             |  'pet'          {  5 }
             |  "šest"        {  6 }
             |  'sedam'        {  7 }
             |  'osam'         {  8 }
             |  'devet'        {  9 }
             |  'deset'        { 10 }

         tens:  'dvadeset'     { 20 }
             |  'trideset'     { 30 }
             |  "četrdeset"   { 40 }
             |  'pedeset'      { 50 }
             |  "šezdeset"    { 60 }
             |  'sedamdeset'   { 70 }
             |  'osamdeset'    { 80 }
             |  'devedeset'    { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /sto/  deca     { $item[1] * 100 + $item[3] }
             |  number /sto/           { $item[1] * 100            }
             |  'dvjesto' deca         { 200 + $item[2]            }
             |  'dvjesto'              { 200                       }
             |  'tristo' deca          { 300 + $item[2]            }
             |  'tristo'               { 300                       }
             |  "četiristo" deca  { 400 + $item[2]            }
             |  "četiristo"       { 400                       }
             |  'petsto' deca          { 500 + $item[2]            }
             |  'petsto'               { 500                       }
             |  "šeststo" deca    { 600 + $item[2]            }
             |  "šeststo"         { 600                       }
             |  'sedamsto' deca        { 700 + $item[2]            }
             |  'sedamsto'             { 700                       }
             |  'osamsto' deca         { 800 + $item[2]            }
             |  'osamsto'              { 800                       }
             |  'devetsto' deca        { 900 + $item[2]            }
             |  'devetsto'             { 900                       }
             |  'sto' deca             { 100 + $item[2]            }
             |  'sto'                  { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd /tisuć[ae]?/ hOd   { $item[1] * 1000 + $item[3]       }
             |  hOd /tisuć[ae]?/        { $item[1] * 1000                  }
             |  number /tisuć[ae]?/ hOd { $item[1] * 1000 + $item[3]       }
             |  number /tisuć[ae]?/     { $item[1] * 1000                  }
             |  /tisuća/ hOd            { 1000 + $item[2]                  }
             |  /tisuća/                { 1000                             }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }
             |  'jedan' 'milijun' kOhOd     { 1_000_000 + $item[3]                  }
             |  'jedan' 'milijun'           { 1_000_000                              }
             |  'milijun' kOhOd             { 1_000_000 + $item[2]                  }
             |  'milijun'                   { 1_000_000                              }

        megas:  'milijuna'
             |  'milijun'
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::HRV::Word2Num - Word to number conversion in Croatian


=head1 VERSION

version 0.2603270

Lingua::HRV::Word2Num is module for converting Croatian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HRV::Word2Num;

 my $num = Lingua::HRV::Word2Num::w2n( 'dvadeset' );

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

=item B<hrv_numerals> (void)

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
