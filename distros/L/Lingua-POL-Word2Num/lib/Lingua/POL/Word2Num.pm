# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::POL::Word2Num;
# ABSTRACT: Word to number conversion in Polish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $COPY     = 'Copyright (c) PetaMem, s.r.o. 2003-present';
my $parser   = pol_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
  my $input = shift // return;

#  print "INPUT: '$input'\n";
  $input =~ s{\s\z}{}xms;
#  print "INPUT: '$input'\n";

  return $parser->numeral($input);
}

# }}}
# {{{ pol_numerals                                 create parser for numerals

sub pol_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'zero'            {  0 }
             |                   {    }

       number:  'dziewiętnaście' { 19 }
             |  'osiemnaście'    { 18 }
             |  'siedemnaście'   { 17 }
             |  'szesnaście'     { 16 }
             |  'piętnaście'     { 15 }
             |  'czternaście'    { 14 }
             |  'trzynaście'     { 13 }
             |  'dwanaście'      { 12 }
             |  'jedenaście'     { 11 }
             |  'dziesięć'       { 10 }
             |  'dziewięć'       {  9 }
             |  'osiem'          {  8 }
             |  'siedem'         {  7 }
             |  'sześć'          {  6 }
             |  'pięć'           {  5 }
             |  'cztery'         {  4 }
             |  'trzy'           {  3 }
             |  'dwa'            {  2 }
             |  'jeden'          {  1 }

         tens:  'dwadzieścia'      { 20 }
             |  'trzydzieści'      { 30 }
             |  'czterdzieści'     { 40 }
             |  'pięćdziesiąt'     { 50 }
             |  'sześćdziesiąt'    { 60 }
             |  'siedemdziesiąt'   { 70 }
             |  'osiemdziesiąt'    { 80 }
             |  'dziewięćdziesiąt' { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /(sta|set)/ deca  { $item[1] * 100 + $item[3] }
             |  number /(sta|set)/       { $item[1] * 100            }
             |  'dwieście' deca          { 2 * 100 + $item[2]        }
             |  'dwieście'               { 200                       }
             |  'sto' deca               { 100 + $item[2]            }
             |  'sto'                    { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd      /(tysiąc[ae]?|tysięcy)/ hOd   { $item[1] * 1000 + $item[3]       }
             |  hOd      /(tysiąc[ae]?|tysięcy)/       { $item[1] * 1000                  }
             |  number   /(tysiąc[ae]?|tysięcy)/ hOd   { $item[1] * 1000 + $item[3]       }
             |  number   /(tysiąc[ae]?|tysięcy)/       { $item[1] * 1000                  }
             |  'tysiąc' hOd                           { 1000 + $item[2]                  }
             |  'tysiąc'                               { 1000                             }
             |  hOd 'jeden' 'tysiąc' hOd               { ($item[1] + 1) * 1000 + $item[4] }
             |  hOd 'jeden' 'tysiąc'                   { ($item[1] + 1) * 1000            }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }

        megas:  /milion(y|ów)?/
    });
}

# }}}
# {{{ ordinal2cardinal             convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Polish ordinals: strip gender/case suffixes, then map stems.
    # Inflection: -y/-a/-e/-ego/-emu/-ym (masc/fem/neut/oblique).
    # Special: -i forms for 3rd (trzeci).

    my %irregular = (
        'zerowy'          => 'zero',
        'pierwszy'        => 'jeden',
        'drugi'           => 'dwa',
        'trzeci'          => 'trzy',
        'czwarty'         => 'cztery',
        'piąty'           => 'pięć',
        'szósty'          => 'sześć',
        'siódmy'          => 'siedem',
        'ósmy'            => 'osiem',
        'dziewiąty'       => 'dziewięć',
        'dziesiąty'       => 'dziesięć',
        'jedenasty'       => 'jedenaście',
        'dwunasty'        => 'dwanaście',
        'trzynasty'       => 'trzynaście',
        'czternasty'      => 'czternaście',
        'piętnasty'       => 'piętnaście',
        'szesnasty'       => 'szesnaście',
        'siedemnasty'     => 'siedemnaście',
        'osiemnasty'      => 'osiemnaście',
        'dziewiętnasty'   => 'dziewiętnaście',
        'dwudziesty'      => 'dwadzieścia',
        'trzydziesty'     => 'trzydzieści',
        'czterdziesty'    => 'czterdzieści',
        'pięćdziesiąty'   => 'pięćdziesiąt',
        'sześćdziesiąty'  => 'sześćdziesiąt',
        'siedemdziesiąty' => 'siedemdziesiąt',
        'osiemdziesiąty'  => 'osiemdziesiąt',
        'dziewięćdziesiąty' => 'dziewięćdziesiąt',
        'dwusetny'        => 'dwieście',
        'trzechsetny'     => 'trzy sta',
        'czterechsetny'   => 'cztery sta',
        'pięćsetny'       => 'pięć set',
        'sześćsetny'      => 'sześć set',
        'siedemsetny'     => 'siedem set',
        'osiemsetny'      => 'osiem set',
        'dziewięćsetny'   => 'dziewięć set',
        'setny'           => 'sto',
        'tysięczny'       => 'tysiąc',
        'milionowy'       => 'milion',
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Strip gender/case suffixes to masculine nominative
        my $norm = $word;
        $norm =~ s{(i)ego\z}{$1}xms         # trzeciego → trzeci
            or $norm =~ s{ego\z}{y}xms       # czwartego → czwarty
            or $norm =~ s{emu\z}{y}xms       # czwartemu → czwarty
            or $norm =~ s{ym\z}{y}xms        # czwartym  → czwarty
            or $norm =~ s{a\z}{y}xms         # czwarta   → czwarty
            or $norm =~ s{(i)ej\z}{$1}xms    # trzeciej  → trzeci
            or $norm =~ s{ej\z}{y}xms;       # czwartej  → czwarty

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

Lingua::POL::Word2Num - Word to number conversion in Polish


=head1 VERSION

version 0.2603300

Lingua::POL::Word2Num is module for converting text containing number
representation in polish back into number. Converts whole numbers from 0 up
to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::POL::Word2Num;

 my $num = Lingua::POL::Word2Num::w2n( 'sto dwadzieścia trzy' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item  B<w2n> (positional)

  1   str    string to convert
  =>  num    converted number
  =>  undef  if input string is not known

Convert text representation to number.

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'piąty', 'dwudziesty', 'trzeci')
  =>  str    cardinal text (e.g. 'pięć', 'dwadzieścia', 'trzy')
      undef  if input is not a recognized ordinal

Convert Polish ordinal text to cardinal text via morphological reversal.
Handles all gender/case inflections.

=item B<pol_numerals> (void)

  =>  obj  returns new parser object

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

Copyright (c) PetaMem, s.r.o. 2003-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
