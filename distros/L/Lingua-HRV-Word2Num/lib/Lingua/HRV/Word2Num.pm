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
our $VERSION = '0.2603300';
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
# {{{ ordinal2cardinal             convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Croatian ordinals: strip gender/case suffixes, then map stems.
    # Inflection: -i/-a/-o/-og(a)/-om(u)/-im (masc/fem/neut/oblique).

    my %irregular = (
        'nulti'       => 'nula',
        'prvi'        => 'jedan',
        'drugi'       => 'dva',
        'treći'       => 'tri',
        'četvrti'     => 'četiri',
        'peti'        => 'pet',
        'šesti'       => 'šest',
        'sedmi'       => 'sedam',
        'osmi'        => 'osam',
        'deveti'      => 'devet',
        'deseti'      => 'deset',
        'jedanaesti'  => 'jedanaest',
        'dvanaesti'   => 'dvanaest',
        'trinaesti'   => 'trinaest',
        'četrnaesti'  => 'četrnaest',
        'petnaesti'   => 'petnaest',
        'šesnaesti'   => 'šesnaest',
        'sedamnaesti' => 'sedamnaest',
        'osamnaesti'  => 'osamnaest',
        'devetnaesti' => 'devetnaest',
        'dvadeseti'   => 'dvadeset',
        'trideseti'   => 'trideset',
        'četrdeseti'  => 'četrdeset',
        'pedeseti'    => 'pedeset',
        'šezdeseti'   => 'šezdeset',
        'sedamdeseti' => 'sedamdeset',
        'osamdeseti'  => 'osamdeset',
        'devedeseti'  => 'devedeset',
        'dvjestoti'   => 'dvjesto',
        'tristoti'    => 'tristo',
        'četiristoti' => 'četiristo',
        'petstoti'    => 'petsto',
        'šeststoti'   => 'šeststo',
        'sedamstoti'  => 'sedamsto',
        'osamstoti'   => 'osamsto',
        'devetstoti'  => 'devetsto',
        'stoti'       => 'sto',
        'tisućiti'    => 'tisuća',
        'milijunti'   => 'milijun',
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Strip gender/case suffixes to masculine nominative (-i)
        my $norm = $word;
        $norm =~ s{oga\z}{i}xms
            or $norm =~ s{og\z}{i}xms
            or $norm =~ s{omu\z}{i}xms
            or $norm =~ s{om\z}{i}xms
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

Lingua::HRV::Word2Num - Word to number conversion in Croatian


=head1 VERSION

version 0.2603300

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

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'peti', 'deseti', 'treći')
  =>  str    cardinal text (e.g. 'pet', 'deset', 'tri')
      undef  if input is not a recognized ordinal

Convert Croatian ordinal text to cardinal text via morphological reversal.
Handles all gender/case inflections.

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
