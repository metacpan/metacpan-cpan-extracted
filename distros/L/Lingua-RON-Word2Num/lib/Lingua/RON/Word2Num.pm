# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::RON::Word2Num;
# ABSTRACT: Word to number conversion in Romanian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = ron_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ ron_numerals              create parser for romanian numerals

sub ron_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | 'zero'        {  0 }
                  |               {    }

      number:       'unsprezece'          { 11 }
                  | 'doisprezece'         { 12 }
                  | 'treisprezece'        { 13 }
                  | 'paisprezece'         { 14 }
                  | 'cincisprezece'       { 15 }
                  | /[sș]aisprezece/      { 16 }
                  | /[sș]aptesprezece/    { 17 }
                  | 'optsprezece'         { 18 }
                  | /nou[aă]sprezece/     { 19 }
                  | 'zece'                { 10 }
                  | /un[ua]?/             {  1 }
                  | /dou[aă]/             {  2 }
                  | 'doi'                 {  2 }
                  | 'trei'                {  3 }
                  | 'patru'               {  4 }
                  | 'cinci'               {  5 }
                  | /[sș]ase/             {  6 }
                  | /[sș]apte/            {  7 }
                  | 'opt'                 {  8 }
                  | /nou[aă]/             {  9 }

      tens:         /dou[aă]zeci/         { 20 }
                  | 'treizeci'            { 30 }
                  | 'patruzeci'           { 40 }
                  | 'cincizeci'           { 50 }
                  | /[sș]aizeci/          { 60 }
                  | /[sș]aptezeci/        { 70 }
                  | 'optzeci'             { 80 }
                  | /nou[aă]zeci/         { 90 }

      deca:         tens /[sș]i/ number   { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        'o' /sut[aă]/ deca    { 100 + $item[3]            }
                  | 'o' /sut[aă]/         { 100                       }
                  | /dou[aă]/ 'sute' deca { 200 + $item[3]            }
                  | /dou[aă]/ 'sute'      { 200                       }
                  | number 'sute' deca    { $item[1] * 100 + $item[3] }
                  | number 'sute'         { $item[1] * 100            }

      hOd:        hecto
                | deca

      kilo:       'o' 'mie' hOd          { 1000 + $item[3]           }
                | 'o' 'mie'              { 1000                      }
                | /dou[aă]/ 'mii' hOd    { 2000 + $item[3]           }
                | /dou[aă]/ 'mii'        { 2000                      }
                | hOd 'mii' hOd          { $item[1] * 1000 + $item[3] }
                | hOd 'mii'             { $item[1] * 1000            }

      kOhOd:      kilo
                | hOd

      mega:       'un' 'milion' kOhOd    { 1_000_000 + $item[3]               }
                | 'un' 'milion'          { 1_000_000                           }
                | /dou[aă]/ 'milioane' kOhOd { 2_000_000 + $item[3]           }
                | /dou[aă]/ 'milioane'       { 2_000_000                      }
                | hOd 'milioane' kOhOd   { $item[1] * 1_000_000 + $item[3]   }
                | hOd 'milioane'         { $item[1] * 1_000_000              }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::RON::Word2Num - Word to number conversion in Romanian


=head1 VERSION

version 0.2603270

Lingua::RON::Word2Num is module for converting Romanian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::RON::Word2Num;

 my $num = Lingua::RON::Word2Num::w2n( 'douăzeci și trei' );

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

=item B<ron_numerals> (void)

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
