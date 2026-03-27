# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::THA::Word2Num;
# ABSTRACT: Word to number conversion in Thai

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = tha_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ tha_numerals              create parser for thai numerals

sub tha_numerals {
    return Parse::RecDescent->new(q{
      numeral:      mega
                  | saen_group
                  | { }

      # --- units ---
      unit:         'เก้า'     { 9 }
                  | 'แปด'     { 8 }
                  | 'เจ็ด'     { 7 }
                  | 'หก'      { 6 }
                  | 'ห้า'     { 5 }
                  | 'สี่'      { 4 }
                  | 'สาม'     { 3 }
                  | 'สอง'     { 2 }
                  | 'หนึ่ง'    { 1 }

      # --- zero (standalone only) ---
      zero:         'ศูนย์'    { 0 }

      # --- ones in compound (เอ็ด replaces หนึ่ง) ---
      compound_one: 'เอ็ด'     { 1 }
                  | unit

      # --- tens digit (ยี่ replaces สอง for 20s) ---
      tens_digit:   'ยี่'      { 2 }
                  | unit

      # --- สิบ (ten) constructs ---
      deca:         tens_digit 'สิบ' compound_one  { $item[1] * 10 + $item[3] }
                  | tens_digit 'สิบ'               { $item[1] * 10            }
                  | 'สิบ' compound_one              { 10 + $item[2]            }
                  | 'สิบ'                           { 10                       }

      deca_or_unit: deca
                  | compound_one
                  | zero

      # --- ร้อย (hundred) ---
      roi:          unit 'ร้อย' deca_or_unit  { $item[1] * 100 + $item[3] }
                  | unit 'ร้อย'              { $item[1] * 100            }

      roi_group:    roi
                  | deca_or_unit

      # --- พัน (thousand) ---
      phan:         unit 'พัน' roi_group  { $item[1] * 1000 + $item[3] }
                  | unit 'พัน'           { $item[1] * 1000            }

      phan_group:   phan
                  | roi_group

      # --- หมื่น (ten thousand) ---
      muen:         unit 'หมื่น' phan_group  { $item[1] * 10_000 + $item[3] }
                  | unit 'หมื่น'            { $item[1] * 10_000            }

      muen_group:   muen
                  | phan_group

      # --- แสน (hundred thousand) ---
      saen:         unit 'แสน' muen_group  { $item[1] * 100_000 + $item[3] }
                  | unit 'แสน'            { $item[1] * 100_000            }

      saen_group:   saen
                  | muen_group

      # --- ล้าน (million) ---
      mega:         saen_group 'ล้าน' saen_group  { $item[1] * 1_000_000 + $item[3] }
                  | saen_group 'ล้าน'              { $item[1] * 1_000_000            }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::THA::Word2Num - Word to number conversion in Thai


=head1 VERSION

version 0.2603260

Lingua::THA::Word2Num is module for converting Thai numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::THA::Word2Num;

 my $num = Lingua::THA::Word2Num::w2n( 'สิบเจ็ด' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (Thai UTF-8 text)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

Handles Thai special forms:

=over 4

=item *

B<เอ็ด> (et) for 1 in units position of compound numbers

=item *

B<ยี่> (yi) for 2 in tens position (20-29)

=back

=item B<tha_numerals> (void)

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
