# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::DAN::Word2Num;
# ABSTRACT: Word to number conversion in Danish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = dan_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ dan_numerals              create parser for danish numerals

sub dan_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega /\Z/     { $item[1] }
                  | kOhOd /\Z/  { $item[1] }
                  | 'nul' /\Z/  { 0 }
                  | { }

      number:       'tretten'   { 13 }
                  | 'fjorten'   { 14 }
                  | 'femten'    { 15 }
                  | 'seksten'   { 16 }
                  | 'sytten'    { 17 }
                  | 'atten'     { 18 }
                  | 'nitten'    { 19 }
                  | 'elleve'    { 11 }
                  | 'tolv'      { 12 }
                  | 'ti'        { 10 }
                  | /e[nt]/     {  1 }
                  | 'to'        {  2 }
                  | 'tre'       {  3 }
                  | 'fire'      {  4 }
                  | 'fem'       {  5 }
                  | 'seks'      {  6 }
                  | 'syv'       {  7 }
                  | 'otte'      {  8 }
                  | 'ni'        {  9 }

      tens:         'tyve'      { 20 }
                  | 'tredive'   { 30 }
                  | 'fyrre'     { 40 }
                  | 'halvtreds' { 50 }
                  | 'tres'      { 60 }
                  | 'halvfjerds' { 70 }
                  | 'firs'      { 80 }
                  | 'halvfems'  { 90 }

      deca:         number 'og' tens   { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number /hundrede?/ deca    { $item[1] * 100 + $item[3] }
                  | /hundrede?/ deca            { 100 + $item[2]            }
                  | number /hundrede?/          { $item[1] * 100            }
                  | /hundrede?/                 { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tusind' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'tusind'        { $item[1] * 1000            }
                | 'tusind' hOd        { 1000 + $item[2]            }
                | 'tusind'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /million(er)?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /million(er)?/       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::DAN::Word2Num - Word to number conversion in Danish


=head1 VERSION

version 0.2603260

Lingua::DAN::Word2Num is module for converting danish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DAN::Word2Num;

 my $num = Lingua::DAN::Word2Num::w2n( 'sytten' );

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

=item B<dan_numerals> (void)

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
