# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::HUN::Word2Num;
# ABSTRACT: Word to number conversion in Hungarian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = hun_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s{-}{}gxms;    # remove hyphens used in million compounds

    return $parser->numeral($input);
}

# }}}
# {{{ hun_numerals              create parser for hungarian numerals

sub hun_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'tíz'           { 10 }
                  | 'tizenegy'      { 11 }
                  | /tizen(kettő|két)/ { 12 }
                  | 'tizenhárom'    { 13 }
                  | 'tizennégy'     { 14 }
                  | 'tizenöt'       { 15 }
                  | 'tizenhat'      { 16 }
                  | 'tizenhét'      { 17 }
                  | 'tizennyolc'    { 18 }
                  | 'tizenkilenc'   { 19 }
                  | 'nulla'         {  0 }
                  | 'egy'           {  1 }
                  | /kett(ő|ö)/    {  2 }
                  | 'két'           {  2 }
                  | 'három'         {  3 }
                  | 'négy'          {  4 }
                  | /öt/            {  5 }
                  | 'hat'           {  6 }
                  | 'hét'           {  7 }
                  | 'nyolc'         {  8 }
                  | 'kilenc'        {  9 }

      tens:         'húsz'          { 20 }
                  | /huszon/  number  { 20 + $item[2] }
                  | 'harminc'       { 30 }
                  | 'negyven'       { 40 }
                  | 'ötven'         { 50 }
                  | 'hatvan'        { 60 }
                  | 'hetven'        { 70 }
                  | 'nyolcvan'      { 80 }
                  | 'kilencven'     { 90 }

      deca:         tens number     { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'száz' deca  { $item[1] * 100 + $item[3] }
                  | number 'száz'       { $item[1] * 100            }
                  | 'száz' deca         { 100 + $item[2]            }
                  | 'száz'              { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'ezer' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'ezer'        { $item[1] * 1000            }
                | 'ezer' hOd        { 1000 + $item[2]            }
                | 'ezer'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /milli(ó|o)/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /milli(ó|o)/       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::HUN::Word2Num - Word to number conversion in Hungarian


=head1 VERSION

version 0.2603260

Lingua::HUN::Word2Num is a module for converting Hungarian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HUN::Word2Num;

 my $num = Lingua::HUN::Word2Num::w2n( 'tizenhárom' );

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

=item B<hun_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
