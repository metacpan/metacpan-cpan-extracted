# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::NOR::Word2Num;
# ABSTRACT: Word 2 number conversion in NOR.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
our $INFO    = {
    rev  => '$Rev: 682 $',
};

my $parser = no_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/ og / /g;                 # Spoke only relevant keywords
    $input =~ s/ million / millioner /g;  # equal

    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}

# }}}
# {{{ no_numerals                                 create parser for numerals

sub no_numerals {
    return Parse::RecDescent->new (q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'null'    { $return = 0; }                              # try to find a word from 0 to 19
        |     'nitten'  { $return = 19; }
        |     'atten'   { $return = 18; }
        |     'sytten'  { $return = 17; }
        |     'seksten' { $return = 16; }
        |     'femten'  { $return = 15; }
        |     'fjorten' { $return = 14; }
        |     'tretten' { $return = 13; }
        |     'tolv'    { $return = 12; }
        |     'ellve'   { $return = 11; }
        |     'ti'      { $return = 10; }
        |     'ni'      { $return = 9; }
        |     'åtte'    { $return = 8; }
        |     'sju'     { $return = 7; }
        |     'seks'    { $return = 6; }
        |     'fem'     { $return = 5; }
        |     'fire'    { $return = 4; }
        |     'tre'     { $return = 3; }
        |     'to'      { $return = 2; }
        |     'en'      { $return = 1; }
        |     'ett'     { $return = 1; }

      tens:   'tjue'   { $return = 20; }                              # try to find a word that representates
        |     'tretti' { $return = 30; }                              # values 20,30,..,90
        |     'førti'  { $return = 40; }
        |     'femti'  { $return = 50; }
        |     'seksti' { $return = 60; }
        |     'sytti'  { $return = 70; }
        |     'åtti'   { $return = 80; }
        |     'nitti'  { $return = 90; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }

      century: number(?) 'hundre' decade(?)                           # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "hundre") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
               }

    millenium: century(?) decade(?) 'tusen' century(?) decade(?)      # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "tusen") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'millioner'                                            # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "millioner") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::NOR::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Norwegian.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::NOR::Word2Num;

 my $num = Lingua::NOR::Word2Num::w2n( 'fire hundre' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in NOR.

Lingua::NOR::Word2Num is module for converting text containing number
representation in Norwegian back into number. Converts whole numbers
from 0 up to 999 999 999.

=cut

# }}}
# {{{ Functions reference

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to convert
  =>  number  covnerted number
      undef   if input string is not known

Convert text representation to number.

=item no_numerals

Internal parser.

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek <info@petamem.com>
 initial coding after specifications by R. Jelinek:
   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
