# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SPA::Word2Num;
# ABSTRACT: Word 2 number conversion in SPA.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Parse::RecDescent;
use Perl6::Export::Attrs;

# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
my $parser   = spa_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/,//g;
    $input =~ s/ //g;
    $input =~ s/millones/lones/g; # grant unique word identifier

    return $parser->numeral($input);
}
# }}}
# {{{ spa_numerals                                 create parser for numerals

sub spa_numerals {
    return Parse::RecDescent->new(q{
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'cero'         { $return = 0; }                          # try to find a word from 0 to 29
        |     'un'           { $return = 1; }
        |     'dos'          { $return = 2; }
        |     'tres'         { $return = 3; }
        |     'cuatro'       { $return = 4; }
        |     'cinco'        { $return = 5; }
        |     'seis'         { $return = 6; }
        |     'siete'        { $return = 7; }
        |     'ocho'         { $return = 8; }
        |     'nueve'        { $return = 9; }
        |     'diez'         { $return = 10; }
        |     'once'         { $return = 11; }
        |     'doce'         { $return = 12; }
        |     'trece'        { $return = 13; }
        |     'catorce'      { $return = 14; }
        |     'quince'       { $return = 15; }
        |     'dieciséis'    { $return = 16; }
        |     'diecisiete'   { $return = 17; }
        |     'dieciocho'    { $return = 18; }
        |     'diecinueve'   { $return = 19; }
        |     'veinte'       { $return = 20; }
        |     'veintiun'     { $return = 21; }
        |     'veintidós'    { $return = 22; }
        |     'veintitrés'   { $return = 23; }
        |     'veinticuatro' { $return = 24; }
        |     'veinticinco'  { $return = 25; }
        |     'veintiséis'   { $return = 26; }
        |     'veintisiete'  { $return = 27; }
        |     'veintiocho'   { $return = 28; }
        |     'veintinueve'  { $return = 29; }

      tens: 'treinta'   { $return = 30; }                             # try to find a word that representates
        |   'cuarenta'  { $return = 40; }                             # values 20,30,..,90
        |   'cincuenta' { $return = 50; }
        |   'sesenta'   { $return = 60; }
        |   'setenta'   { $return = 70; }
        |   'ochenta'   { $return = 80; }
        |   'noventa'   { $return = 90; }
        |   'cien'      { $return = 100; }

      hundreds: 'ciento'        { $return = 100; }
        |       'doscientos'    { $return = 200; }
        |       'trescientos'   { $return = 300; }
        |       'cuatrocientos' { $return = 400; }
        |       'quinientos'    { $return = 500; }
        |       'seiscientos'   { $return = 600; }
        |       'setecientos'   { $return = 700; }
        |       'ochocientos'   { $return = 800; }
        |       'novecientos'   { $return = 900; }

      decade: tens(?) 'y' number(?)                                   # try to find words that represents values
              { $return = 0;                                          # from 0 to 100
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);             # -1 if the non-zero identifier, since
                    $return  = $$_[0] if ($return == -1);             # zero is a valid result
                  }
                }
                $return = undef if ($return == -1);
              }
        |     tens(?) number(?)
              { $return = -1;
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);             # -1 if the non-zero identifier, since
                    $return  = $$_[0] if ($return == -1);             # zero is a valid result
                  }
                }
                $return = undef if ($return == -1);
              }

      century: hundreds(?) decade(?)                                  # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   next if (!ref $_ || !defined $$_[0]);

                   $return += $$_[0];
                 }
                 $return = undef if (!$return);
               }

    millenium: century(?) 'mil' century(?)                            # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "mil") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return = undef if (!$return);
               }

      million: millenium(?) century(?)                                # try to find words that represents values
               'lones'                                                # from 1.000.000 to 999.999.999.999
               millenium(?) century(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "lones") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
                 $return = undef if (!$return);
               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=head1 NAME

Lingua::SPA::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Sspanish.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::SPA::Word2Num;

 my $num = Lingua::SPA::Word2Num::w2n( 'veintisiete' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in SPA.

Lingua::SPA::Word2Num is module for converting text containing number
representation in dutch back into number. Converts whole numbers from 0 up
to 999 999 999 999.

# }}}
# {{{ Functions Reference

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item spa_numerals

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
