# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::EUS::Word2Num;
# ABSTRACT: Word 2 number conversion in EUS.

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

my $parser = eu_numerals();

# }}}

# {{{ w2n                                         convert number to text
#
sub w2n :Export {
    my $input = shift // return;

    $input =~ s/eta / /g;             # Remove word that represents tone in speaking, but nothing for the language
    $input =~ s/ta / /g;              # *the same
    $input =~ s/milioi bat/milioi/g;  # *the same
    $input =~ s/,//g;                 # Remove trick chars

    return $parser->numeral($input);
}
# }}}
# {{{ eu_numerals                                 create parser for numerals
#
sub eu_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: millions  { return $item[1]; }                        # root parse. go from maximum to minimum valeu
        |      million   { return $item[1]; }
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'zero'          { $return = 0; }                       # try to find a word from 0 to 19
        |     'bat'           { $return = 1; }
        |     'bi'            { $return = 2; }
        |     'hiru'          { $return = 3; }
        |     'lau'           { $return = 4; }
        |     'bost'          { $return = 5; }
        |     'sei'           { $return = 6; }
        |     'zazpi'         { $return = 7; }
        |     'zortzi'        { $return = 8; }
        |     'bederatzi'     { $return = 9; }
        |     'hamar'         { $return = 10; }
        |     'hamaika'       { $return = 11; }
        |     'hamabi'        { $return = 12; }
        |     'hamahiru'      { $return = 13; }
        |     'hamalau'       { $return = 14; }
        |     'hamabost'      { $return = 15; }
        |     'hamasei'       { $return = 16; }
        |     'hamazazpi'     { $return = 17; }
        |     'hemezortzi'    { $return = 18; }
        |     'hemeretzi'     { $return = 19; }


       base20: 'hogei'         { $return = 20; }                     # Base20: 20,40,60 and 80. All
        |      'berrogei'      { $return = 40; }                     # other numbers are an composition
        |      'hirurogei'     { $return = 60; }                     # of number and base 20.
        |      'laurogei'      { $return = 80; }

     centuries: 'ehun'          { $return = 100; }                   # try to find a word that representates
        |       'berrehun'      { $return = 200; }                   # values 100,200,300,...900
        |       'hirurehun'     { $return = 300; }
        |       'laurehun'      { $return = 400; }
        |       'bostehun'      { $return = 500; }
        |       'seiehun'       { $return = 600; }
        |       'zazpiehun'     { $return = 700; }
        |       'zortziehun'    { $return = 800; }
        |       'bederatziehun' { $return = 900; }

      decade: base20(?) number(?)                                     # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }

      century: centuries(1) decade(?)                                 # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                 }
               }

    millenium: century(?) decade(?) 'mila' century(?) decade(?)      # try to find words that represents values
               { $return = 0;                                        # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "mila") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
               }

      million: century(?) decade(?)                                   # try to find words that represents values
               'milioi'                                               # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "milioi") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
               }

      millions: century(?) decade(?)                                  # try to find words that represents values
               'mila milioi'                                          # from 1.000.000.000 to 999.999.999.999
               million(?) millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "mila milioi") {
                     $return = ($return>0) ? $return * 1000000000 : 1000000000;
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

Lingua::EUS::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Basque (Euskara).
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

We use ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::EUS::Word2Num;

 my $num = Lingua::EUS::Word2Num::w2n( 'ehun eta hogeita hiru' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in EUS.

Lingua::EUS::Word2Num is module for converting text containing number
representation in Basque (Euskara) back into number. Converts whole numbers
from 0 up to 999 999 999 999.

=cut

# }}}
# {{{ Functions Reference

=pod

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if the input string is not known

Convert text representation to number.

=item eu_numerals

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

Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
