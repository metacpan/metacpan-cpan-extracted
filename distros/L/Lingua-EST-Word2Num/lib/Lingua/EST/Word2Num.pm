# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::EST::Word2Num;
# ABSTRACT: Word to number conversion in Estonian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = est_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ est_numerals              create parser for estonian numerals

sub est_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'üksteist'            { 11 }
                  | 'kaksteist'           { 12 }
                  | 'kolmteist'           { 13 }
                  | 'neliteist'           { 14 }
                  | 'viisteist'           { 15 }
                  | 'kuusteist'           { 16 }
                  | 'seitseteist'         { 17 }
                  | 'kaheksateist'        { 18 }
                  | 'üheksateist'         { 19 }
                  | 'kümme'              { 10 }
                  | 'null'                {  0 }
                  | 'üks'                {  1 }
                  | 'kaks'                {  2 }
                  | 'kolm'                {  3 }
                  | 'neli'                {  4 }
                  | 'viis'                {  5 }
                  | 'kuus'                {  6 }
                  | 'seitse'              {  7 }
                  | 'kaheksa'             {  8 }
                  | 'üheksa'             {  9 }

      tens:         'kakskümmend'        { 20 }
                  | 'kolmkümmend'        { 30 }
                  | 'nelikümmend'        { 40 }
                  | 'viiskümmend'        { 50 }
                  | 'kuuskümmend'        { 60 }
                  | 'seitsekümmend'      { 70 }
                  | 'kaheksakümmend'     { 80 }
                  | 'üheksakümmend'      { 90 }

      deca:         tens number           { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'sada' deca    { $item[1] * 100 + $item[3] }
                  | number 'sada'         { $item[1] * 100            }
                  | 'sada' deca           { 100 + $item[2]            }
                  | 'sada'                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tuhat' hOd         { $item[1] * 1000 + $item[3] }
                | hOd 'tuhat'             { $item[1] * 1000            }
                | 'tuhat' hOd             { 1000 + $item[2]            }
                | 'tuhat'                 { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /miljonit?/ kOhOd   { $item[1] * 1_000_000 + $item[3] }
                | hOd /miljonit?/         { $item[1] * 1_000_000 }
                | 'miljon' kOhOd          { 1_000_000 + $item[2] }
                | 'miljon'                { 1_000_000             }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::EST::Word2Num - Word to number conversion in Estonian


=head1 VERSION

version 0.2603260

Lingua::EST::Word2Num is module for converting Estonian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::EST::Word2Num;

 my $num = Lingua::EST::Word2Num::w2n( 'seitseteist' );

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

=item B<est_numerals> (void)

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
