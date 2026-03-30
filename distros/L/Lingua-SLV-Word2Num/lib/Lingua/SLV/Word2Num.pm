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
our $VERSION = '0.2603300';
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
# {{{ ordinal2cardinal             convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Slovenian ordinals: strip gender/case suffixes, then map stems.
    # Inflection: -i/-a/-o/-ega/-emu/-em/-im (masc/fem/neut/oblique).

    my %irregular = (
        'ničti'        => 'nič',
        'prvi'         => 'ena',
        'drugi'        => 'dva',
        'tretji'       => 'tri',
        'četrti'       => 'štiri',
        'peti'         => 'pet',
        'šesti'        => 'šest',
        'sedmi'        => 'sedem',
        'osmi'         => 'osem',
        'deveti'       => 'devet',
        'deseti'       => 'deset',
        'enajsti'      => 'enajst',
        'dvanajsti'    => 'dvanajst',
        'trinajsti'    => 'trinajst',
        'štirinajsti'  => 'štirinajst',
        'petnajsti'    => 'petnajst',
        'šestnajsti'   => 'šestnajst',
        'sedemnajsti'  => 'sedemnajst',
        'osemnajsti'   => 'osemnajst',
        'devetnajsti'  => 'devetnajst',
        'dvajseti'     => 'dvajset',
        'trideseti'    => 'trideset',
        'štirideseti'  => 'štirideset',
        'petdeseti'    => 'petdeset',
        'šestdeseti'   => 'šestdeset',
        'sedemdeseti'  => 'sedemdeset',
        'osemdeseti'   => 'osemdeset',
        'devetdeseti'  => 'devetdeset',
        'dvestoti'     => 'dvesto',
        'tristoti'     => 'tristo',
        'štiristoti'   => 'štiristo',
        'petstoti'     => 'petsto',
        'šeststoti'    => 'šeststo',
        'sedemstoti'   => 'sedemsto',
        'osemstoti'    => 'osemsto',
        'devetstoti'   => 'devetsto',
        'stoti'        => 'sto',
        'tisočti'      => 'tisoč',
        'tisoči'       => 'tisoč',
        'milijonti'    => 'milijon',
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Strip gender/case suffixes to masculine nominative (-i)
        my $norm = $word;
        $norm =~ s{ega\z}{i}xms
            or $norm =~ s{emu\z}{i}xms
            or $norm =~ s{em\z}{i}xms
            or $norm =~ s{im\z}{i}xms
            or $norm =~ s{a\z}{i}xms      # fem: prva → prvi
            or $norm =~ s{o\z}{i}xms;     # neut: prvo → prvi

        if (exists $irregular{$norm}) {
            push @result, $irregular{$norm};
            $matched = 1;
        }
        else {
            push @result, $word;  # pass through unchanged (connectors, etc.)
        }
    }

    return $matched ? join(' ', @result) : undef;
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

version 0.2603300

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

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'peti', 'deseti', 'tretji')
  =>  str    cardinal text (e.g. 'pet', 'deset', 'tri')
      undef  if input is not a recognized ordinal

Convert Slovenian ordinal text to cardinal text via morphological reversal.
Handles all gender/case inflections.

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

=item ordinal2cardinal

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
