# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::ARA::Word2Num;
# ABSTRACT: Word to number conversion in Arabic

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = ara_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    # Normalize whitespace and strip diacritics (tashkeel)
    $input =~ s/[ً-ْٰ]//g;    # remove tashkeel
    $input =~ s/\A\s+//;
    $input =~ s/\s+\z//;
    $input =~ s/\s+/ /g;

    return $parser->numeral($input);
}

# }}}
# {{{ ara_numerals              create parser for arabic numerals

sub ara_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      # --- Units ---
      number:       "صفر"                                 {  0 }
                  | "واحد"                          {  1 }
                  | "اثنان"                   {  2 }
                  | "اثنين"                   {  2 }
                  | "ثلاثة"                   {  3 }
                  | "أربعة"                   {  4 }
                  | "خمسة"                          {  5 }
                  | "ستة"                                  {  6 }
                  | "سبعة"                          {  7 }
                  | "ثمانية"            {  8 }
                  | "تسعة"                          {  9 }

      ten:          "عشرة"                          { 10 }

      # --- Teens (11-19) ---
      # 11: أحد عشر
      teen:         "أحد عشر"           { 11 }
                  | "اثنا عشر"    { 12 }
                  | "ثلاثة عشر" { 13 }
                  | "أربعة عشر" { 14 }
                  | "خمسة عشر"    { 15 }
                  | "ستة عشر"           { 16 }
                  | "سبعة عشر"    { 17 }
                  | "ثمانية عشر" { 18 }
                  | "تسعة عشر"    { 19 }

      # --- Tens (20-90) ---
      tens:         "عشرون"                   { 20 }
                  | "ثلاثون"            { 30 }
                  | "أربعون"            { 40 }
                  | "خمسون"                   { 50 }
                  | "ستون"                          { 60 }
                  | "سبعون"                   { 70 }
                  | "ثمانون"            { 80 }
                  | "تسعون"                   { 90 }

      # --- Connector (wa = and) ---
      wa:           "و"

      # --- Deca: units + wa + tens (Arabic order) or standalone ---
      deca:         number wa tens     { $item[1] + $item[3] }
                  | wa deca            { $item[2]            }
                  | teen
                  | tens
                  | ten
                  | number

      # --- Hundreds ---
      # مئتان = 200 (dual)
      mi_atan:      "مئتان"                  { 200 }

      # Compound hundreds: ثلاثمئة etc. (no space)
      hund_pfx:     "ثلاث"                          { 3 }
                  | "أربع"                          { 4 }
                  | "خمس"                                  { 5 }
                  | "ست"                                         { 6 }
                  | "سبع"                                  { 7 }
                  | "ثمان"                          { 8 }
                  | "تسع"                                  { 9 }

      # مئة (mi'a) or مائة (maa'a) - both spellings
      mi_a:         "مئة"
                  | "مائة"

      hecto:        mi_atan wa deca          { 200 + $item[3]              }
                  | mi_atan                   { 200                         }
                  | hund_pfx mi_a wa deca     { $item[1] * 100 + $item[4]  }
                  | hund_pfx mi_a             { $item[1] * 100             }
                  | mi_a wa deca              { 100 + $item[3]             }
                  | mi_a                      { 100                        }

      hOd:        hecto
                | deca

      # --- Thousands ---
      # ألفان = 2000 (dual)
      alfan:        "ألفان"                   { 2000 }

      # ألف (alf) - singular
      alf:          "ألف"

      # آلاف (alaf) - plural (3-10)
      alaf:         "آلاف"

      # alf_or_alaf: singular or plural thousand marker
      alf_any:      alaf | alf

      kilo:         alfan wa hOd            { 2000 + $item[3]             }
                  | alfan                    { 2000                        }
                  | hOd alf_any wa hOd      { $item[1] * 1000 + $item[4] }
                  | hOd alf_any             { $item[1] * 1000            }
                  | alf wa hOd              { 1000 + $item[3]             }
                  | alf                     { 1000                        }

      kOhOd:      kilo
                | hOd

      # --- Millions ---
      # مليونان = 2_000_000 (dual)
      milyunan:     "مليونان"    { 2_000_000 }

      # مليون (milyun) - singular
      milyun:       "مليون"

      # ملايين (malayin) - plural (3-10)
      malayin:      "ملايين"

      # milyun_or_malayin: singular or plural million marker
      mily_any:     malayin | milyun

      mega:         milyunan wa kOhOd       { 2_000_000 + $item[3]                   }
                  | milyunan                 { 2_000_000                               }
                  | hOd mily_any wa kOhOd   { $item[1] * 1_000_000 + $item[4]        }
                  | hOd mily_any            { $item[1] * 1_000_000                   }
                  | milyun wa kOhOd         { 1_000_000 + $item[3]                    }
                  | milyun                   { 1_000_000                               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::ARA::Word2Num - Word to number conversion in Arabic


=head1 VERSION

version 0.2603260

Lingua::ARA::Word2Num is module for converting Arabic numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8 (Modern Standard Arabic, masculine counting forms).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ARA::Word2Num;

 my $num = Lingua::ARA::Word2Num::w2n( "سبعة عشر" );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (UTF-8 Arabic)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<ara_numerals> (void)

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
