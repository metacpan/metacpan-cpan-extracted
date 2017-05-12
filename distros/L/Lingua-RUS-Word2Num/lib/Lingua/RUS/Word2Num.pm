# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::RUS::Word2Num;
# ABSTRACT: Word 2 number conversion in RUS.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use utf8;
use Perl6::Export::Attrs;
use Carp;
use Parse::RecDescent;

# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
my  $parser  = ru_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/^\s+одна тысяча / тысяч /g;    # Thousand variations. We just want one
    $input =~ s/ тысячи / тысяч /g;
    $input =~ s/ тысячa / тысяч /g;
    $input =~ s/ тысяча / тысяч /g;

    $input =~ s/^\s+один миллион / миллион /g; # Million variations. We just want one
    $input =~ s/ миллиона / миллион /g;
    $input =~ s/ миллионов / миллион /g;

    $input .= " ";                             # Grant end space

    return $parser->numeral($input);
}

# }}}
# {{{ ru_numerals                                 create parser for numerals

sub ru_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'девятнадцать ' { $return = 19; }                       # try to find a word from 0 to 19
        |     'восемнадцать ' { $return = 18; }
        |     'семнадцать '   { $return = 17; }
        |     'шестнадцать '  { $return = 16; }
        |     'пятнадцать '   { $return = 15; }
        |     'четырнадцать ' { $return = 14; }
        |     'тринадцать '   { $return = 13; }
        |     'двенадцать '   { $return = 12; }
        |     'одинадцать '   { $return = 11; }
        |     'десять '       { $return = 10; }
        |     'девять '       { $return = 9; }
        |     'восемь '       { $return = 8; }
        |     'семь '         { $return = 7; }
        |     'шесть '        { $return = 6; }
        |     'пять '         { $return = 5; }
        |     'четыре '       { $return = 4; }
        |     'три '          { $return = 3; }
        |     'два '          { $return = 2; }
        |     'две '          { $return = 2; }
        |     'одна '         { $return = 1; }
        |     'один '         { $return = 1; }
        |     'ноль '         { $return = 0; }

      tens:   'двадцать '    { $return = 20; }                        # try to find a word that representates
        |     'тридцать '    { $return = 30; }                        # values 20,30,..,90
        |     'сорок '       { $return = 40; }
        |     'пятьдесят '   { $return = 50; }
        |     'шестьдесят '  { $return = 60; }
        |     'семьдесят '   { $return = 70; }
        |     'восемьдесят ' { $return = 80; }
        |     'девяносто '   { $return = 90; }

     hundreds: 'сто '       { $return = 100; }                        # try to find a word that representates
        |      'сотня '     { $return = 100; }                        # values 200,300,..,900
        |      'двести '    { $return = 200; }
        |      'триста '    { $return = 300; }
        |      'четыреста ' { $return = 400; }
        |      'пятьсот '   { $return = 500; }
        |      'шестьсот '  { $return = 600; }
        |      'семьсот '   { $return = 700; }
        |      'восемьсот ' { $return = 800; }
        |      'девятьсот ' { $return = 900; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = -1;                                         # from 0 to 99
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);
                    $return  = $$_[0] if ($return == -1);
                  }
                }
                $return = undef if ($return == -1);
              }

      century: hundreds(?) decade(?)                                  # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   $return += $$_[0] if (ref $_ && defined $$_[0]);
                 }
                 $return ||= undef;
               }

    millenium: century(?) decade(?) 'тысяч ' century(?) decade(?)      # try to find words that represents values
               { $return = 0;                                          # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "тысяч ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: century(?) decade(?)                                   # try to find words that represents values
              'миллион '                                              # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "миллион ") {
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

Lingua::RUS::Word2Num

=head1 VERSION

version 0.0682

Text to positive number convertor for Russian.

Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::RUS::Word2Num;

 my $num = Lingua::RUS::Word2Num::w2n( 'пять' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in RUS.

Lingua::RUS::Word2Num is module for converting text containing number
representation in Russian back into number. Converts whole numbers
from 0 up to 999 999 999.

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

=item ru_numerals

Internal parser.

=back

=cut

# }}}
# {{{ POD FOOTER

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
