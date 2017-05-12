# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::NLD::Word2Num;
# ABSTRACT: Word 2 number conversion in NLD.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
my  $parser  = nld_numerals();

# }}}
# {{{ w2n                                         convert number to text

sub w2n :Export {
    my $input = shift // return;

    $input = lc $input;
    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}

# }}}
# {{{ nld_numerals                                 create parser for numerals

sub nld_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'negentien'  { $return = 19; }                          # try to find a word from 0 to 19
        |     'achtien'    { $return = 18; }
        |     'zeventien'  { $return = 17; }
        |     'zestien'    { $return = 16; }
        |     'vijftien'   { $return = 15; }
        |     'veertien'   { $return = 14; }
        |     'dertien'    { $return = 13; }
        |     'twaalf'     { $return = 12; }
        |     'elf'        { $return = 11; }
        |     'tien'       { $return = 10; }
        |     'negen'      { $return = 9; }
        |     'acht'       { $return = 8; }
        |     'zeven'      { $return = 7; }
        |     'zes'        { $return = 6; }
        |     'vijf'       { $return = 5; }
        |     'vier'       { $return = 4; }
        |     'drie'       { $return = 3; }
        |     'twee'       { $return = 2; }
        |     'een'        { $return = 1; }
        |     'nul'        { $return = 0; }

      tens:   'twintig'  { $return = 20; }                            # try to find a word that representates
        |     'dertig'   { $return = 30; }                            # values 20,30,..,90
        |     'veertig'  { $return = 40; }
        |     'vijftig'  { $return = 50; }
        |     'zestig'   { $return = 60; }
        |     'zeventig' { $return = 70; }
        |     'tachtig'  { $return = 80; }
        |     'negentig' { $return = 90; }

      decade: number(?) 'en' tens(?) number(?)                        # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }
        |     tens(?) number(?)
              { $return = -1;
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);
                    $return  = $$_[0] if ($return == -1);
                  }
                }
                $return = undef if ($return == -1);
              }

      century: number(?) 'honderd' decade(?)                          # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "honderd") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
                 $return ||= undef;
               }

    millenium: century(?) decade(?) 'duizend' century(?) decade(?)    # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "duizend") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'miljard'                                              # from 1.000.000 to 999.999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "miljard") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
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

Lingua::NLD::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Dutch.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::NLD::Word2Num;

 my $num = Lingua::NLD::Word2Num::w2n( 'dertien' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in NLD.

Lingua::NLD::Word2Num is module for converting text containing number
representation in Dutch back into number. Converts whole numbers from 0 up
to 999 999 999 999.

=cut

# }}}
# {{{ Functions reference

=pod

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to be converted
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item nld_numerals

Internal pareser.

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
   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2003-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
