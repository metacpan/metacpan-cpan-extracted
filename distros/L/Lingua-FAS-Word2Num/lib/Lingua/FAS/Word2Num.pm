# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::FAS::Word2Num;
# ABSTRACT: Word to number conversion in Persian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = fas_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ fas_numerals              create parser for persian numerals

sub fas_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       "صفر"          {  0 }
                  | "یک"                   {  1 }
                  | "دو"                   {  2 }
                  | "سه"                   {  3 }
                  | "چهار"   {  4 }
                  | "پنج"           {  5 }
                  | "شش"                   {  6 }
                  | "هفت"           {  7 }
                  | "هشت"           {  8 }
                  | "نه"                   {  9 }

      teens:        "ده"                                           { 10 }
                  | "یازده"                   { 11 }
                  | "دوازده"           { 12 }
                  | "سیزده"                   { 13 }
                  | "چهارده"           { 14 }
                  | "پانزده"           { 15 }
                  | "شانزده"           { 16 }
                  | "هفده"                           { 17 }
                  | "هجده"                           { 18 }
                  | "نوزده"                   { 19 }

      tens:         "بیست"                           { 20 }
                  | "سی"                                           { 30 }
                  | "چهل"                                   { 40 }
                  | "پنجاه"                   { 50 }
                  | "شصت"                                   { 60 }
                  | "هفتاد"                   { 70 }
                  | "هشتاد"                   { 80 }
                  | "نود"                                   { 90 }

      deca:         teens
                  | tens "و" number          { $item[1] + $item[3] }
                  | tens
                  | number

      hundreds:     "نهصد"                                                   { 900 }
                  | "هشتصد"                                           { 800 }
                  | "هفتصد"                                           { 700 }
                  | "ششصد"                                                   { 600 }
                  | "پانصد"                                           { 500 }
                  | "چهارصد"                                   { 400 }
                  | "سیصد"                                                   { 300 }
                  | "دویست"                                           { 200 }
                  | "صد"                                                                   { 100 }

      hecto:        hundreds "و" deca    { $item[1] + $item[3] }
                  | hundreds

      hOd:        hecto
                | deca

      kilo:       hOd "هزار" "و" hOd    { $item[1] * 1000 + $item[4] }
                | hOd "هزار"                    { $item[1] * 1000            }
                | "هزار" "و" hOd         { 1000 + $item[3]            }
                | "هزار"                        { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd "میلیون" "و" kOhOd { $item[1] * 1_000_000 + $item[4] }
                | hOd "میلیون"                  { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::FAS::Word2Num - Word to number conversion in Persian


=head1 VERSION

version 0.2603270

Lingua::FAS::Word2Num is module for converting Persian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8 using Arabic script.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FAS::Word2Num;

 my $num = Lingua::FAS::Word2Num::w2n( 'صد و بیست و سه' );

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
You can specify a numeral from interval [0,999_999_999].

=item B<fas_numerals> (void)

  =>  obj  new parser object

Internal parser.

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
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
