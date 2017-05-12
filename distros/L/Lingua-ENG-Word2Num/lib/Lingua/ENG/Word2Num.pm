# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::ENG::Word2Num;
# ABSTRACT: Word 2 number conversion in ENG.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Encode                    qw(decode_utf8);
use Parse::RecDescent;
use Perl6::Export::Attrs;

# }}}
# {{{ variables

our $VERSION = 0.0682;

my $parser   = eng_numerals();

# }}}

# {{{ w2n                     convert number to text

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}

# {{{ eng_numerals            create parser for numerals

sub eng_numerals {
    return Parse::RecDescent->new(decode_utf8(q{
      numeral:      <rulevar: local $number = 0>
      numeral:       million
                    { return $item[1]; }
                  |  thousand
                    { return $item[1]; }
                  |  century
                    { return $item[1]; }
                  |  decade
                    { return $item[1]; }
                  | { return undef; }

      number:       'twelve'     { $return = 12; }
                  | 'thirteen'   { $return = 13; }
                  | 'fourteen'   { $return = 14; }
                  | 'fifteen'    { $return = 15; }
                  | 'sixteen'    { $return = 16; }
                  | 'seventeen'  { $return = 17; }
                  | 'eighteen'   { $return = 18; }
                  | 'nineteen'   { $return = 19; }
                  | 'zero'       { $return =  0; }
                  | 'one'        { $return =  1; }
                  | 'two'        { $return =  2; }
                  | 'three'      { $return =  3; }
                  | 'four'       { $return =  4; }
                  | 'five'       { $return =  5; }
                  | 'six'        { $return =  6; }
                  | 'seven'      { $return =  7; }
                  | 'eight'      { $return =  8; }
                  | 'nine'       { $return =  9; }
                  | 'ten'        { $return = 10; }
                  | 'eleven'     { $return = 11; }

      tens:       'twenty'       { $return = 20; }
                | 'thirty'       { $return = 30; }
                | 'forty'        { $return = 40; }
                | 'fifty'        { $return = 50; }
                | 'sixty'        { $return = 60; }
                | 'seventy'      { $return = 70; }
                | 'eighty'       { $return = 80; }
                | 'ninety'       { $return = 90; }

      decade:    tens '-' number  { $return = $item[1] + $item[2]; }
               | tens number      { $return = $item[1] + $item[2]; }
               | tens             { $return = $item[1]; }
               | number           { $return = $item[1]; }

      century:  number 'hundred' decade
                { $return = $item[1] * 100  + $item[3]; }
                | number 'hundred'
                { $return = $item[1] * 100 }

    thousand:     century thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | century thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | century thousands
                { $return = $item[1] * 1000; }

                | decade thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | decade thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | decade thousands
                { $return = $item[1] * 1000; }

                | number thousands century
                { $return = $item[1] * 1000 + $item[3]; }
                | number thousands decade
                { $return = $item[1] * 1000 + $item[3]; }
                | number thousands
                { $return = $item[1] * 1000; }

                | 'thousand' century
                { $return = 1000 + $item[2]; }
                | 'thousand' decade
                { $return = 1000 + $item[2]; }
                | 'thousand'
                { $return = 1000; }

                | century 'one' 'thousand' century
                { $return = ($item[1] + 1) * 1000 + $item[4]; }
                | century 'one' 'thousand' decade
                { $return = ($item[1] + 1) * 1000 + $item[4]; }

                | decade 'one' 'tisíc' century
                { $return = ($item[1] + 1) * 1000 + $item[4]; }
                | decade 'one' 'tisíc' decade
                { $return = ($item[1] + 1) * 1000 + $item[4]; }

                | century 'one' 'thousand'
                { $return = ($item[1] + 1) * 1000; }
                | decade 'one' 'thousand'
                { $return = ($item[1] + 1) * 1000; }

    thousands:    'thousand'

    million:      century millions thousand
                { $return = $item[1] * 1_000_000 + $item[3]; }
                |  century millions century
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | century millions decade
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | century millions
                { $return = $item[1] * 1_000_000; }

                | decade millions thousand
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions century
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions decade
                { $return = $item[1] * 1_000_000 + $item[3]; }
                | decade millions
                { $return = $item[1] * 1_000_000; }

                | 'million' thousand
                { $return = 1_000_000 + $item[2]; }
                | 'million' century
                { $return = 1_000_000 + $item[2]; }
                | 'million' decade
                { $return = 1_000_000 + $item[2]; }
                | 'million'
                { $return = 1_000_000; }

                | century 'one' 'million' thousand
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | century 'one' 'million' century
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | century 'one' 'million' decade
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }

                | decade 'one' 'million' thousand
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | decade 'one' 'million' century
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }
                | decade 'one' 'million' decade
                { $return = ($item[1] + 1) * 1_000_000 + $item[4]; }

    millions:     'millions'

    }));
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::ENG::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for english. Input text must be in
utf-8 encoding.

=head2 $Rev: 682 $

We use ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::ENG::Word2Num;

 my $num = Lingua::ENG::Word2Num::w2n( 'nineteen' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in ENG.

Lingua::ENG::Word2Num is module for converting text containing number
representation in czech back into number. Converts whole numbers from 0 up
to 999 999 999.

=cut

# }}}
# {{{ functions reference

=pod

=head2 Functions Reference

=over 2

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item eng_numerals

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
   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
