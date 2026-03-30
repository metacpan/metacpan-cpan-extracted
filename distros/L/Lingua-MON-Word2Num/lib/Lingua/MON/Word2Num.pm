# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::MON::Word2Num;
# ABSTRACT: Word to number conversion in Mongolian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = mon_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ mon_numerals              create parser for mongolian numerals

sub mon_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       /тэг/              {  0 }
                  | /нэг/              {  1 }
                  | /хоёр/             {  2 }
                  | /гурав/            {  3 }
                  | /дөрөв/            {  4 }
                  | /тав/              {  5 }
                  | /зургаа/           {  6 }
                  | /долоо/            {  7 }
                  | /найм/             {  8 }
                  | /ес/               {  9 }
                  | /арав/             { 10 }

      tens:         /арван/            { 10 }
                  | /хорин/            { 20 }
                  | /хорь/             { 20 }
                  | /гучин/            { 30 }
                  | /гуч(?!и)/         { 30 }
                  | /дөчин/            { 40 }
                  | /дөч(?!и)/         { 40 }
                  | /тавин/            { 50 }
                  | /тави(?!н)/        { 50 }
                  | /жаран/            { 60 }
                  | /жар(?!а)/         { 60 }
                  | /далан/            { 70 }
                  | /дал(?!а)/         { 70 }
                  | /наян/             { 80 }
                  | /ная(?!н)/         { 80 }
                  | /ерэн/             { 90 }
                  | /ер(?!э)/          { 90 }

      deca:         tens number        { $item[1] + $item[2] }
                  | tens
                  | number

      cnum:         /нэг/              {  1 }
                  | /хоёр/             {  2 }
                  | /гурван/           {  3 }
                  | /дөрвөн/           {  4 }
                  | /таван/            {  5 }
                  | /зургаан/          {  6 }
                  | /долоон/           {  7 }
                  | /найман/           {  8 }
                  | /есөн/             {  9 }

      hecto:        cnum /зуун/ deca         { $item[1] * 100 + $item[3] }
                  | cnum /зуун?/             { $item[1] * 100            }
                  | /зуун/ deca              { 100 + $item[2]            }
                  | /зуун?/                  { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd /мянга(н)?/ hOd    { $item[1] * 1000 + $item[3] }
                | hOd /мянга(н)?/        { $item[1] * 1000            }
                | /мянга(н)?/ hOd        { 1000 + $item[2]            }
                | /мянга(н)?/            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /сая/ kOhOd       { $item[1] * 1_000_000 + $item[3] }
                | hOd /сая/             { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::MON::Word2Num - Word to number conversion in Mongolian

=head1 VERSION

version 0.2603300

Lingua::MON::Word2Num is a module for converting Mongolian numerals (Cyrillic
script) into numbers. Converts whole numbers from 0 up to 999 999 999.
Input is expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::MON::Word2Num;

 my $num = Lingua::MON::Word2Num::w2n( 'арван долоо' );
 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (Mongolian, Cyrillic script)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<mon_numerals> (void)

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
