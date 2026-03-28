# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::RUS::Word2Num;
# ABSTRACT: Word to number conversion in Russian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Carp;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603270';
my  $parser  = ru_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input .= " ";                             # Grant end space before normalizing

    $input =~ s/тысячи /тысяч /g;              # Thousand variations. Normalize to тысяч
    $input =~ s/тысячa /тысяч /g;
    $input =~ s/тысяча /тысяч /g;

    $input =~ s/миллиона /миллион /g;          # Million variations. Normalize to миллион
    $input =~ s/миллионов /миллион /g;

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

      tens:   'двадцать '    { $return = 20; }                        # try to find a word that represents
        |     'тридцать '    { $return = 30; }                        # values 20,30,..,90
        |     'сорок '       { $return = 40; }
        |     'пятьдесят '   { $return = 50; }
        |     'шестьдесят '  { $return = 60; }
        |     'семьдесят '   { $return = 70; }
        |     'восемьдесят ' { $return = 80; }
        |     'девяносто '   { $return = 90; }

     hundreds: 'сто '       { $return = 100; }                        # try to find a word that represents
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

=encoding utf-8

=head1 NAME

Lingua::RUS::Word2Num - Word to number conversion in Russian


=head1 VERSION

version 0.2603270

Lingua::RUS::Word2Num is module for converting text containing number
representation in Russian back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::RUS::Word2Num;

 my $num = Lingua::RUS::Word2Num::w2n( 'пять' );

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

=item B<ru_numerals> (void)

  =>  obj  new parser object

Internal parser.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=over 2

=item w2n

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
