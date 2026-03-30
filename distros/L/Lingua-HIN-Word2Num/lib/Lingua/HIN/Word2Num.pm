# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::HIN::Word2Num;
# ABSTRACT: Word to number conversion in Hindi

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = hin_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ hin_numerals              create parser for hindi numerals

sub hin_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      crore
                  | lOkOhOd
                  | { }

      number:       'शून्य'      {  0 }
                  | 'एक'        {  1 }
                  | 'दो'        {  2 }
                  | 'तीन'       {  3 }
                  | 'चार'       {  4 }
                  | 'पाँच'      {  5 }
                  | 'छह'        {  6 }
                  | 'सात'       {  7 }
                  | 'आठ'        {  8 }
                  | 'नौ'        {  9 }
                  | 'दस'        { 10 }
                  | 'ग्यारह'     { 11 }
                  | 'बारह'      { 12 }
                  | 'तेरह'      { 13 }
                  | 'चौदह'      { 14 }
                  | 'पंद्रह'     { 15 }
                  | 'सोलह'      { 16 }
                  | 'सत्रह'      { 17 }
                  | 'अट्ठारह'    { 18 }
                  | 'उन्नीस'     { 19 }
                  | 'बीस'       { 20 }
                  | 'इक्कीस'     { 21 }
                  | 'बाईस'      { 22 }
                  | 'तेईस'      { 23 }
                  | 'चौबिस'     { 24 }
                  | 'पच्चीस'     { 25 }
                  | 'छब्बीस'     { 26 }
                  | 'सत्ताईस'    { 27 }
                  | 'अट्ठाईस'    { 28 }
                  | 'उनतीस'     { 29 }
                  | 'तीस'       { 30 }
                  | 'इकतीस'     { 31 }
                  | 'बत्तीस'     { 32 }
                  | 'तैंतीस'     { 33 }
                  | 'चौंतीस'     { 34 }
                  | 'पैंतीस'     { 35 }
                  | 'छत्तीस'     { 36 }
                  | 'सैंतीस'     { 37 }
                  | 'अड़तीस'     { 38 }
                  | 'उनतालीस'    { 39 }
                  | 'चालीस'     { 40 }
                  | 'इकतालीस'    { 41 }
                  | 'बयालीस'     { 42 }
                  | 'तैंतालीस'    { 43 }
                  | 'चौंतालीस'    { 44 }
                  | 'पैंतालीस'    { 45 }
                  | 'छयालीस'     { 46 }
                  | 'सैंतालीस'    { 47 }
                  | 'अड़तालीस'    { 48 }
                  | 'उनचास'     { 49 }
                  | 'पचासी'      { 85 }
                  | 'पचास'      { 50 }
                  | 'इक्यावन'    { 51 }
                  | 'बावन'      { 52 }
                  | 'तिरेपन'     { 53 }
                  | 'चौवन'      { 54 }
                  | 'पचपन'      { 55 }
                  | 'छप्पन'      { 56 }
                  | 'सत्तावन'    { 57 }
                  | 'अट्ठावन'    { 58 }
                  | 'उनसठ'      { 59 }
                  | 'साठ'       { 60 }
                  | 'इकसठ'      { 61 }
                  | 'बासठ'      { 62 }
                  | 'तिरेसठ'     { 63 }
                  | 'चौंसठ'      { 64 }
                  | 'पैंसठ'      { 65 }
                  | 'छयासठ'     { 66 }
                  | 'सरसठ'      { 67 }
                  | 'अड़सठ'      { 68 }
                  | 'उनहत्तर'    { 69 }
                  | 'सत्तर'      { 70 }
                  | 'इकहत्तर'    { 71 }
                  | 'बहत्तर'     { 72 }
                  | 'तिहत्तर'    { 73 }
                  | 'चौहत्तर'    { 74 }
                  | 'पचहत्तर'    { 75 }
                  | 'छिहत्तर'    { 76 }
                  | 'सतहत्तर'    { 77 }
                  | 'अठहत्तर'    { 78 }
                  | 'उन्यासी'    { 79 }
                  | 'अस्सी'      { 80 }
                  | 'इक्यासी'    { 81 }
                  | 'बयासी'      { 82 }
                  | 'तिरासी'     { 83 }
                  | 'चौरासी'     { 84 }
                  | 'छियासी'     { 86 }
                  | 'सत्तासी'    { 87 }
                  | 'अठासी'      { 88 }
                  | 'नवासी'      { 89 }
                  | 'नब्बे'      { 90 }
                  | 'इक्यानवे'   { 91 }
                  | 'बानवे'      { 92 }
                  | 'तिरानवे'    { 93 }
                  | 'चौरानवे'    { 94 }
                  | 'पचानवे'     { 95 }
                  | 'छियानवे'    { 96 }
                  | 'सत्तानवे'   { 97 }
                  | 'अट्ठानवे'   { 98 }
                  | 'निन्यानवे'   { 99 }

      hecto:        number 'सौ' number  { $item[1] * 100 + $item[3] }
                  | number 'सौ'         { $item[1] * 100            }
                  | 'सौ'                { 100                       }

      hOd:          hecto
                  | number

      kilo:         hOd 'हज़ार' hOd     { $item[1] * 1000 + $item[3] }
                  | hOd 'हज़ार'         { $item[1] * 1000            }
                  | 'हज़ार'             { 1000                       }

      kOhOd:        kilo
                  | hOd

      lakh:         hOd 'लाख' kOhOd    { $item[1] * 100_000 + $item[3] }
                  | hOd 'लाख'           { $item[1] * 100_000            }
                  | 'लाख'               { 100_000                       }

      lOkOhOd:      lakh
                  | kOhOd

      crore:        hOd 'करोड़' lOkOhOd { $item[1] * 10_000_000 + $item[3] }
                  | hOd 'करोड़'          { $item[1] * 10_000_000            }
                  | 'करोड़'              { 10_000_000                       }
    });
}

# }}}
# {{{ capabilities              declare supported features

sub capabilities {
    return {
        w2n => 1,
    };
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding UTF-8

=head1 NAME

Lingua::HIN::Word2Num - Word to number conversion in Hindi

=head1 VERSION

version 0.2603300

Lingua::HIN::Word2Num is a module for converting Hindi numerals
(in Devanagari script) into numbers. Converts whole numbers from
0 up to 99,99,99,999 (99 crore). Input is expected to be in UTF-8.

Uses the Indian numbering system with लाख (lakh, 10^5) and
करोड़ (crore, 10^7).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HIN::Word2Num;

 my $num = Lingua::HIN::Word2Num::w2n( 'पच्चीस' );
 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (UTF-8 Devanagari)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0, 99_99_99_999].

=item B<hin_numerals> (void)

  =>  obj  new parser object

Internal parser.

=item B<capabilities> (void)

  =>  hashref  supported conversion types

Returns a hashref indicating which conversions are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

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
 coding:
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
