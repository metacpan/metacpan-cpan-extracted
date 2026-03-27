# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::VIE::Word2Num;
# ABSTRACT: Word to number conversion in Vietnamese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = vie_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ vie_numerals              create parser for vietnamese numerals

sub vie_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      # units in isolation (0..9)
      number:       'không'     {  0 }
                  | 'một'       {  1 }
                  | 'hai'       {  2 }
                  | 'ba'        {  3 }
                  | 'bốn'       {  4 }
                  | 'năm'       {  5 }
                  | 'sáu'       {  6 }
                  | 'bảy'       {  7 }
                  | 'tám'       {  8 }
                  | 'chín'      {  9 }

      # compound unit variants (after mươi)
      compound_unit:  'mốt'    {  1 }
                    | 'tư'     {  4 }
                    | 'lăm'    {  5 }
                    | number

      # units after mười (11..19): lăm for 5, bốn for 4, regular otherwise
      muoi_unit:    'lăm'      {  5 }
                  | 'bốn'      {  4 }
                  | number

      # 10..19
      teens:        'mười' muoi_unit   { 10 + $item[2] }
                  | 'mười'             { 10             }

      # 20..99
      tens:         number 'mươi' compound_unit  { $item[1] * 10 + $item[3] }
                  | number 'mươi'                { $item[1] * 10            }

      deca:         tens
                  | teens
                  | number

      # hundreds: lẻ marks a zero-tens placeholder (e.g. 101 = một trăm lẻ một)
      hecto:        number 'trăm' 'lẻ' number   { $item[1] * 100 + $item[4]            }
                  | number 'trăm' deca           { $item[1] * 100 + $item[3]            }
                  | number 'trăm'                { $item[1] * 100                       }

      hOd:        hecto
                | deca

      # thousands: không trăm marks hundreds=0 (e.g. 1005 = một nghìn không trăm lẻ năm)
      kilo:       hOd 'nghìn' 'không' 'trăm' deca  { $item[1] * 1000 + $item[5]            }
                | hOd 'nghìn' hOd                    { $item[1] * 1000 + $item[3]            }
                | hOd 'nghìn'                        { $item[1] * 1000                       }
                | hOd 'ngàn' 'không' 'trăm' deca     { $item[1] * 1000 + $item[5]            }
                | hOd 'ngàn' hOd                      { $item[1] * 1000 + $item[3]            }
                | hOd 'ngàn'                          { $item[1] * 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'triệu' 'không' 'nghìn' hOd  { $item[1] * 1_000_000 + $item[5]     }
                | hOd 'triệu' kOhOd                  { $item[1] * 1_000_000 + $item[3]     }
                | hOd 'triệu'                         { $item[1] * 1_000_000                }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::VIE::Word2Num - Word to number conversion in Vietnamese


=head1 VERSION

version 0.2603260

Lingua::VIE::Word2Num is module for converting Vietnamese numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::VIE::Word2Num;

 my $num = Lingua::VIE::Word2Num::w2n( 'mười bảy' );

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

=item B<vie_numerals> (void)

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
