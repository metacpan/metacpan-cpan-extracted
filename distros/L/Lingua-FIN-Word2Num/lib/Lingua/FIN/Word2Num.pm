# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::FIN::Word2Num;
# ABSTRACT: Word to number conversion in Finnish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = fin_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ fin_numerals              create parser for finnish numerals

sub fin_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'yksitoista'          { 11 }
                  | 'kaksitoista'         { 12 }
                  | 'kolmetoista'         { 13 }
                  | 'neljätoista'        { 14 }
                  | 'viisitoista'         { 15 }
                  | 'kuusitoista'         { 16 }
                  | 'seitsemäntoista'   { 17 }
                  | 'kahdeksantoista'     { 18 }
                  | 'yhdeksäntoista'    { 19 }
                  | 'kymmenen'            { 10 }
                  | 'nolla'               {  0 }
                  | 'yksi'                {  1 }
                  | 'kaksi'               {  2 }
                  | 'kolme'               {  3 }
                  | 'neljä'              {  4 }
                  | 'viisi'               {  5 }
                  | 'kuusi'               {  6 }
                  | 'seitsemän'         {  7 }
                  | 'kahdeksan'           {  8 }
                  | 'yhdeksän'          {  9 }

      tens:         'kaksikymmentä'      { 20 }
                  | 'kolmekymmentä'      { 30 }
                  | 'neljäkymmentä'    { 40 }
                  | 'viisikymmentä'      { 50 }
                  | 'kuusikymmentä'      { 60 }
                  | 'seitsemänkymmentä' { 70 }
                  | 'kahdeksankymmentä'  { 80 }
                  | 'yhdeksänkymmentä'  { 90 }

      deca:         tens number           { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'sataa' deca   { $item[1] * 100 + $item[3] }
                  | number 'sataa'        { $item[1] * 100            }
                  | 'sata' deca           { 100 + $item[2]            }
                  | 'sata'                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tuhatta' hOd      { $item[1] * 1000 + $item[3] }
                | hOd 'tuhatta'          { $item[1] * 1000            }
                | 'tuhat' hOd            { 1000 + $item[2]            }
                | 'tuhat'                { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /miljoona[a]?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /miljoona[a]?/       { $item[1] * 1_000_000 }
                | 'miljoona' kOhOd         { 1_000_000 + $item[2] }
                | 'miljoona'               { 1_000_000             }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::FIN::Word2Num - Word to number conversion in Finnish


=head1 VERSION

version 0.2603260

Lingua::FIN::Word2Num is module for converting Finnish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FIN::Word2Num;

 my $num = Lingua::FIN::Word2Num::w2n( 'seitsemäntoista' );

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

=item B<fin_numerals> (void)

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
