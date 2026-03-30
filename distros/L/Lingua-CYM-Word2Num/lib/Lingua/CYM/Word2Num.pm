# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::CYM::Word2Num;
# ABSTRACT: Word to number conversion in Welsh (Cymraeg)

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = cym_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ cym_numerals              create parser for Welsh numerals

sub cym_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      # Basic digits
      number:       'dim'       {  0 }
                  | 'sero'      {  0 }
                  | 'un'        {  1 }
                  | 'dau'       {  2 }
                  | 'dwy'       {  2 }
                  | 'tri'       {  3 }
                  | 'tair'      {  3 }
                  | 'pedwar'    {  4 }
                  | 'pedair'    {  4 }
                  | 'pump'      {  5 }
                  | 'pum'       {  5 }
                  | 'chwech'    {  6 }
                  | 'chwe'      {  6 }
                  | 'saith'     {  7 }
                  | 'wyth'      {  8 }
                  | 'naw'       {  9 }
                  | 'deg'       { 10 }

      # Tens: "dau ddeg", "tri deg", "pedwar deg", "pum deg", etc.
      tens:         'dau' 'ddeg'     { 20 }
                  | 'tri' 'deg'      { 30 }
                  | 'pedwar' 'deg'   { 40 }
                  | 'pum' 'deg'      { 50 }
                  | 'chwe' 'deg'     { 60 }
                  | 'saith' 'deg'    { 70 }
                  | 'wyth' 'deg'     { 80 }
                  | 'naw' 'deg'      { 90 }

      # Teens: "un deg un" = 11, "un deg dau" = 12, etc.
      teens:        'un' 'deg' number   { 10 + $item[3] }

      deca:         teens
                  | tens number    { $item[1] + $item[2] }
                  | tens
                  | number

      # Hundreds: cant, dau gant, tri chant, pedwar cant, pum cant, etc.
      hecto:        'naw' 'cant' deca       { 900 + $item[3] }
                  | 'naw' 'cant'             { 900 }
                  | 'wyth' 'cant' deca       { 800 + $item[3] }
                  | 'wyth' 'cant'            { 800 }
                  | 'saith' 'cant' deca      { 700 + $item[3] }
                  | 'saith' 'cant'           { 700 }
                  | 'chwe' 'chant' deca      { 600 + $item[3] }
                  | 'chwe' 'chant'           { 600 }
                  | 'pum' 'cant' deca        { 500 + $item[3] }
                  | 'pum' 'cant'             { 500 }
                  | 'pedwar' 'cant' deca     { 400 + $item[3] }
                  | 'pedwar' 'cant'          { 400 }
                  | 'tri' 'chant' deca       { 300 + $item[3] }
                  | 'tri' 'chant'            { 300 }
                  | 'dau' 'gant' deca        { 200 + $item[3] }
                  | 'dau' 'gant'             { 200 }
                  | 'cant' deca              { 100 + $item[2] }
                  | 'cant'                   { 100 }

      hOd:        hecto
                | deca

      # Thousands: mil, dau mil, tri mil, etc.
      kilo:       hOd 'mil' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'mil'        { $item[1] * 1000            }
                | 'mil' hOd        { 1000 + $item[2]            }
                | 'mil'            { 1000                        }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'miliwn' kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd 'miliwn'       { $item[1] * 1_000_000 }
    });
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
    };
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::CYM::Word2Num - Word to number conversion in Welsh (Cymraeg)


=head1 VERSION

version 0.2603300

Lingua::CYM::Word2Num is a module for converting Welsh numerals into
numbers, using the modern decimal counting system. Converts whole numbers
from 0 up to 999 999 999. Input is expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CYM::Word2Num;

 my $num = Lingua::CYM::Word2Num::w2n( 'tri deg pedwar' );

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

Convert Welsh text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<cym_numerals> (void)

  =>  obj  new parser object

Internal parser.

=item B<capabilities> (void)

  =>  hashref   hash of supported features

Returns a hashref indicating which conversion types are supported.
Currently: cardinal => 1, ordinal => 0.

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
 coding (2026-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
