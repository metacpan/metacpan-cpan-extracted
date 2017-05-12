# For Emacs: -*- mode:cperl; mode:folding -*-

package Lingua::POL::Word2Num;
# ABSTRACT: Word 2 number conversion in POL.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Encode                    qw(decode_utf8);
use Perl6::Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block

our $VERSION = 0.0682;
my $COPY     = 'Copyright (C) PetaMem, s.r.o. 2003-present';
my $parser   = pl_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
  my $input = shift // return;

  $input =~ s/tysišce/tysišc/g;  # Remove trick chars that don't affect the parsing (gender related)

  $input .= " ";                 # Grant end space, since we identify similar words by specifying the space

  return $parser->numeral($input);
}

# }}}
# {{{ pl_numerals                                 create parser for numerals

sub pl_numerals {
    return Parse::RecDescent->new(decode_utf8(q[
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: "dziewiętnaście " { $return = 19; }               # try to find a word from 0 to 19
        |     "osiemnaście "    { $return = 18; }
        |     "siedemnaście "   { $return = 17; }
        |     "szesnaście "     { $return = 16; }
        |     "piętnaście "      { $return = 15; }
        |     "czternaście "    { $return = 14; }
        |     "trzynaście "     { $return = 13; }
        |     "dwanaście "      { $return = 12; }
        |     "jedenaście "     { $return = 11; }
        |     "dziesięć "       { $return = 10; }
        |     "dziewięć "       { $return = 9; }
        |     "osiem "          { $return = 8; }
        |     "siedem "         { $return = 7; }
        |     "sześć "          { $return = 6; }
        |     "pięć "           { $return = 5; }
        |     "cztery "         { $return = 4; }
        |     "trzy "           { $return = 3; }
        |     "dwa "            { $return = 2; }
        |     "jeden "          { $return = 1; }
        |     "zero "           { $return = 0; }

      tens:   "dwadzieścia"      { $return = 20; }                    # try to find a word that representates
        |     "trzydzieści"      { $return = 30; }                    # values 20,30,..,90
        |     "czerdzieści"      { $return = 40; }
        |     "pięćdziesiąt"     { $return = 50; }
        |     "sześćdziesiąt"    { $return = 60; }
        |     "siedemdziesiąt"   { $return = 70; }
        |     "osiemdziesiąt"    { $return = 80; }
        |     "dziewięćdziesiąt" { $return = 90; }

    hundreds: "sto"         { $return = 100; }
        |     "dwieśccie"   { $return = 200; }
        |     "trzysta"     { $return = 300; }
        |     "czterysta"   { $return = 400; }
        |     "pięćset"     { $return = 500; }
        |     "sześćset"    { $return = 600; }
        |     "siedemset"   { $return = 700; }
        |     "osiemset"    { $return = 800; }
        |     "dziewięćset" { $return = 900; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }

      century: number(?) hundreds(?) decade(?)                        # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                 }
               }

    millenium: century(?) decade(?) 'tysiąc' century(?) decade(?)     # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "tysiąc") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'milion'                                               # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "milion") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
               }
    ]));
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::POL::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Polish.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::POL::Word2Num;

 my $num = Lingua::POL::Word2Num::w2n( 'sto dwadzieścia trzy' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in POL.

Lingua::POL::Word2Num is module for converting text containing number
representation in polish back into number. Converts whole numbers from 0 up
to 999 999 999.

=cut

# }}}
# {{{ Function reference

=head2 Functions Reference

=over

=item  w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item pl_numerals

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

Copyright (C) PetaMem, s.r.o. 2003-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
