# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::TUR::Word2Num;
# ABSTRACT: Word to number conversion in Turkish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = tur_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ tur_numerals              create parser for turkish numerals

sub tur_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'sıfır'   {  0 }
                  | 'bir'     {  1 }
                  | 'iki'     {  2 }
                  | 'üç'      {  3 }
                  | 'dört'    {  4 }
                  | 'beş'     {  5 }
                  | 'altı'    {  6 }
                  | 'yedi'    {  7 }
                  | 'sekiz'   {  8 }
                  | 'dokuz'   {  9 }

      tens:         'on'      { 10 }
                  | 'yirmi'   { 20 }
                  | 'otuz'    { 30 }
                  | 'kırk'    { 40 }
                  | 'elli'    { 50 }
                  | 'altmış'  { 60 }
                  | 'yetmiş'  { 70 }
                  | 'seksen'  { 80 }
                  | 'doksan'  { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'yüz' deca    { $item[1] * 100 + $item[3] }
                  | number 'yüz'         { $item[1] * 100            }
                  | 'yüz' deca           { 100 + $item[2]            }
                  | 'yüz'               { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'bin' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'bin'        { $item[1] * 1000            }
                | 'bin' hOd        { 1000 + $item[2]            }
                | 'bin'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'milyon' kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd 'milyon'       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::TUR::Word2Num - Word to number conversion in Turkish


=head1 VERSION

version 0.2603270

Lingua::TUR::Word2Num is module for converting Turkish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::TUR::Word2Num;

 my $num = Lingua::TUR::Word2Num::w2n( 'yüz yirmi üç' );

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

=item B<tur_numerals> (void)

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
