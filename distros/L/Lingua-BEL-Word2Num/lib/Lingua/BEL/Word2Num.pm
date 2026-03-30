# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::BEL::Word2Num;
# ABSTRACT: Word to number conversion in Belarusian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Carp;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603300';
my  $parser  = bel_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input .= " ";                             # Grant end space before normalizing

    $input =~ s/тысячы /тысяч /g;             # Thousand variations. Normalize to тысяч
    $input =~ s/тысяча /тысяч /g;

    $input =~ s/мільёны /мільён /g;           # Million variations. Normalize to мільён
    $input =~ s/мільёнаў /мільён /g;

    return $parser->numeral($input);
}

# }}}
# {{{ bel_numerals                                 create parser for numerals

sub bel_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'дзевятнаццаць '  { $return = 19; }                    # try to find a word from 0 to 19
        |     'васямнаццаць '   { $return = 18; }
        |     'сямнаццаць '     { $return = 17; }
        |     'шаснаццаць '     { $return = 16; }
        |     'пятнаццаць '     { $return = 15; }
        |     'чатырнаццаць '   { $return = 14; }
        |     'трынаццаць '     { $return = 13; }
        |     'дванаццаць '     { $return = 12; }
        |     'адзінаццаць '    { $return = 11; }
        |     'дзесяць '        { $return = 10; }
        |     'дзевяць '        { $return = 9; }
        |     'восем '          { $return = 8; }
        |     'сем '            { $return = 7; }
        |     'шэсць '          { $return = 6; }
        |     'пяць '           { $return = 5; }
        |     'чатыры '         { $return = 4; }
        |     'тры '            { $return = 3; }
        |     'два '            { $return = 2; }
        |     'дзве '           { $return = 2; }
        |     'адна '           { $return = 1; }
        |     'адзін '          { $return = 1; }
        |     'нуль '           { $return = 0; }

      tens:   'дваццаць '       { $return = 20; }                    # try to find a word that represents
        |     'трыццаць '       { $return = 30; }                    # values 20,30,..,90
        |     'сорак '          { $return = 40; }
        |     'пяцьдзясят '    { $return = 50; }
        |     'шасцьдзясят '   { $return = 60; }
        |     'семдзесят '      { $return = 70; }
        |     'васемдзесят '    { $return = 80; }
        |     'дзевяноста '     { $return = 90; }

     hundreds: 'сто '           { $return = 100; }                   # try to find a word that represents
        |      'дзвесце '       { $return = 200; }                   # values 100,200,..,900
        |      'трыста '        { $return = 300; }
        |      'чатырыста '     { $return = 400; }
        |      'пяцьсот '       { $return = 500; }
        |      'шасцьсот '      { $return = 600; }
        |      'семсот '        { $return = 700; }
        |      'васемсот '      { $return = 800; }
        |      'дзевяцьсот '    { $return = 900; }

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

    millenium: century(?) decade(?) 'тысяч ' century(?) decade(?)     # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
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
              'мільён '                                               # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "мільён ") {
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

Lingua::BEL::Word2Num - Word to number conversion in Belarusian


=head1 VERSION

version 0.2603300

Lingua::BEL::Word2Num is module for converting text containing number
representation in Belarusian back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::BEL::Word2Num;

 my $num = Lingua::BEL::Word2Num::w2n( 'пяць' );

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

=item B<bel_numerals> (void)

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
