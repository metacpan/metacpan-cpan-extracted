# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::ITA::Word2Num;
# ABSTRACT: Word 2 number conversion in ITA.

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

our @EXPORT_OK  = qw(cardinal2num w2n);
my $parser      = it_numerals();

# }}}

# {{{ w2n                                         convert number to text
#
sub w2n :Export {
    my $input = shift // return;

    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}
# }}}
# {{{ it_numerals                                 create parser for numerals
sub it_numerals {
    return Parse::RecDescent->new(q{
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'zero'        { $return = 0; }                          # try to find a word from 0 to 19
        |     'diciannove'  { $return = 19; }
        |     'diciotto'    { $return = 18; }
        |     'diciassette' { $return = 17; }
        |     'sedici'      { $return = 16; }
        |     'quindici'    { $return = 15; }
        |     'quattordici' { $return = 14; }
        |     'tredici'     { $return = 13; }
        |     'dodici'      { $return = 12; }
        |     'undici'      { $return = 11; }
        |     'dieci'       { $return = 10; }
        |     'nove'        { $return = 9; }
        |     'otto'        { $return = 8; }
        |     'sette'       { $return = 7; }
        |     'sei'         { $return = 6; }
        |     'cinque'      { $return = 5; }
        |     'quattro'     { $return = 4; }
        |     'tre'         { $return = 3; }
        |     'due'         { $return = 2; }
        |     'un'          { $return = 1; }

      tens:   'venti'     { $return = 20; }                           # try to find a word that representates
        |     'trenta'    { $return = 30; }                           # values 20,30,..,90
        |     'trent'     { $return = 30; }
        |     'quaranta'  { $return = 40; }
        |     'quarant'   { $return = 40; }
        |     'cinquanta' { $return = 50; }
        |     'cinquant'  { $return = 50; }
        |     'sessanta'  { $return = 60; }
        |     'sessant'   { $return = 60; }
        |     'settanta'  { $return = 70; }
        |     'settant'   { $return = 70; }
        |     'ottanta'   { $return = 80; }
        |     'ottant'    { $return = 80; }
        |     'novanta'   { $return = 90; }
        |     'novant'    { $return = 90; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = -1;                                         # from 0 to 99
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);             # -1 if the non-zero identifier, since
                    $return  = $$_[0] if ($return == -1);             # zero is a valid result
                  }
                }
                $return = undef if ($return == -1);
              }

      century: number(?) 'cento' decade(?)                            # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "cento") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
                 $return ||= undef;
               }

    millenium: century(?) decade(?)                                   # try to find words that represents values
               ('mille' | 'mila')                                     # from 1.000 to 999.999
               century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if  ($_ eq "mille" || $_ eq "mila") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                   next if (!ref $_);
                   $return += $$_[0];
                 }
                 $return ||= undef;
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'milioni'                                              # from 1.000.000 to 999.999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if  ($_ eq "milioni" || $_ eq "milione") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }

                   next if ( ! ref $_);
                   $return += $$_[0];
                 }
                 $return ||= undef;
               }
    });
}
# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::ITA::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Italian.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::ITA::Word2Num;

 my $num = Lingua::ITA::Word2Num::w2n( 'trecentoquindici' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in ITA.

Lingua::ITA::Word2Num is module for converting text containing number
representation in italian back into number. Converts whole numbers from 0 up
to 999 999 999 999.

=cut

# }}}
# {{{ Functions reference

=pod

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item it_numerals

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
 initial coding after specification by R. Jelinek:
   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2003-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
