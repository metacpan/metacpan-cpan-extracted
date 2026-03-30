# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::HYE::Word2Num;
# ABSTRACT: Word to number conversion in Armenian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = hye_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ hye_numerals              create parser for Armenian numerals

sub hye_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'տասնմեկ'    { 11 }
                  | 'տասներկու'   { 12 }
                  | 'տասներեք'   { 13 }
                  | 'տասնչորս'  { 14 }
                  | 'տասնհինգ'   { 15 }
                  | 'տասնվեց'   { 16 }
                  | 'տասնյոթ'    { 17 }
                  | 'տասնութ'     { 18 }
                  | 'տասնինը'    { 19 }
                  | 'զրո'         {  0 }
                  | 'մեկ'         {  1 }
                  | 'երկու'        {  2 }
                  | 'երեք'        {  3 }
                  | 'չորս'       {  4 }
                  | 'հինգ'        {  5 }
                  | 'վեց'        {  6 }
                  | 'յոթ'         {  7 }
                  | 'ութ'          {  8 }
                  | 'ինը'         {  9 }
                  | 'տաս'         { 10 }

      tens:         'քսան'        { 20 }
                  | 'երեսուն'      { 30 }
                  | 'քառասուն'     { 40 }
                  | 'հիսուն'       { 50 }
                  | 'վաթսուն'      { 60 }
                  | 'յոթանասուն'   { 70 }
                  | 'ութսուն'       { 80 }
                  | 'իննսուն'      { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'հարյուր' deca  { $item[1] * 100 + $item[3] }
                  | number 'հարյուր'       { $item[1] * 100            }
                  | 'հարյուր' deca         { 100 + $item[2]            }
                  | 'հարյուր'              { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'հազար' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'հազար'        { $item[1] * 1000            }
                | 'հազար' hOd        { 1000 + $item[2]            }
                | 'հազար'            { 1000                        }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'միլիոն' kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd 'միլիոն'       { $item[1] * 1_000_000 }
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

Lingua::HYE::Word2Num - Word to number conversion in Armenian

=head1 VERSION

version 0.2603300

Lingua::HYE::Word2Num is module for converting Armenian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HYE::Word2Num;

 my $num = Lingua::HYE::Word2Num::w2n( 'քսան հինգ' );

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
You can specify a numeral from interval [0, 999_999_999].

=item B<hye_numerals> (void)

  =>  obj  new parser object

Internal parser.

=item B<capabilities> (void)

  =>  hashref  supported features

Returns a hashref indicating which conversion types are supported.

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
