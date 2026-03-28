# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::MLT::Word2Num;
# ABSTRACT: Word to number conversion in Maltese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my $parser   = mlt_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    # Normalize whitespace
    $input =~ s/\A\s+//;
    $input =~ s/\s+\z//;
    $input =~ s/\s+/ /g;

    # Normalize to lowercase
    $input = lc $input;

    return $parser->numeral($input);
}

# }}}
# {{{ mlt_numerals              create parser for maltese numerals

sub mlt_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      # --- Units ---
      number:       /\bxejn\b/                                {  0 }
                  | /\bżero\b/                          {  0 }
                  | /\bwieħed\b/                        {  1 }
                  | /\bwaħda\b/                         {  1 }
                  | /\btnejn\b/                                {  2 }
                  | /\btlieta\b/                               {  3 }
                  | /\berbgħa\b/                        {  4 }
                  | /\bħamsa\b/                         {  5 }
                  | /\bsitta\b/                                {  6 }
                  | /\bsebgħa\b/                        {  7 }
                  | /\btmienja\b/                              {  8 }
                  | /\bdisgħa\b/                        {  9 }

      ten:          /\bgħaxra\b/                        { 10 }

      # --- Teens (11-19) ---
      teen:         /\bħdax\b/                          { 11 }
                  | /\btnax\b/                                 { 12 }
                  | /\btlettax\b/                              { 13 }
                  | /\berbatax\b/                              { 14 }
                  | /\bħmistax\b/                       { 15 }
                  | /\bsittax\b/                               { 16 }
                  | /\bsbatax\b/                               { 17 }
                  | /\btmintax\b/                              { 18 }
                  | /\bdsatax\b/                               { 19 }

      # --- Tens (20-90) ---
      tens:         /\bgħoxrin\b/                       { 20 }
                  | /\btletin\b/                               { 30 }
                  | /\berbgħin\b/                       { 40 }
                  | /\bħamsin\b/                        { 50 }
                  | /\bsittin\b/                               { 60 }
                  | /\bsebgħin\b/                       { 70 }
                  | /\btmenin\b/                               { 80 }
                  | /\bdisgħin\b/                       { 90 }

      # --- Connector (u = and) ---
      u:            "u"

      # --- Deca: units + u + tens (Maltese order) or standalone ---
      deca:         number u tens     { $item[1] + $item[3] }
                  | u deca            { $item[2]            }
                  | teen
                  | tens
                  | ten
                  | number

      # --- Hundreds ---
      # mitejn = 200 (dual)
      mitejn:       /\bmitejn\b/                              { 200 }

      # Compound hundreds: tliet mija etc.
      # NOTE: erba', seba', disa' end in apostrophe — \b fails after '
      # because ' is non-word. Use (?=\s|$) instead of trailing \b.
      hund_pfx:     /\btliet\b/                               { 3 }
                  | /\berba'(?=\s|$)/                          { 4 }
                  | /\bħames\b/                         { 5 }
                  | /\bsitt\b/                                 { 6 }
                  | /\bseba'(?=\s|$)/                          { 7 }
                  | /\btminn\b/                                { 8 }
                  | /\bdisa'(?=\s|$)/                          { 9 }

      # mija - hundred
      mija:         /\bmija\b/

      hecto:        mitejn u deca          { 200 + $item[3]              }
                  | mitejn                  { 200                         }
                  | hund_pfx mija u deca    { $item[1] * 100 + $item[4]  }
                  | hund_pfx mija          { $item[1] * 100             }
                  | mija u deca            { 100 + $item[3]             }
                  | mija                   { 100                        }

      hOd:        hecto
                | deca

      # --- Thousands ---
      # elfejn = 2000 (dual)
      elfejn:       /\belfejn\b/                              { 2000 }

      # elf - singular thousand
      elf:          /\belf\b/

      # elef - plural thousand (3-10)
      elef:         /\belef\b/

      # Compound thousands: tlitt elef, erbat elef etc.
      thou_pfx:     /\btlitt\b/                               { 3 }
                  | /\berbat\b/                                { 4 }
                  | /\bħamest\b/                        { 5 }
                  | /\bsitt\b/                                 { 6 }
                  | /\bsebat\b/                                { 7 }
                  | /\btmint\b/                                { 8 }
                  | /\bdisat\b/                                { 9 }
                  | /\bgħaxart\b/                       { 10 }

      elf_any:      elef | elf

      kilo:         elfejn u hOd           { 2000 + $item[3]             }
                  | elfejn                  { 2000                        }
                  | thou_pfx elf_any u hOd { $item[1] * 1000 + $item[4] }
                  | thou_pfx elf_any       { $item[1] * 1000            }
                  | hOd elf_any u hOd      { $item[1] * 1000 + $item[4] }
                  | hOd elf_any            { $item[1] * 1000            }
                  | elf u hOd              { 1000 + $item[3]             }
                  | elf                    { 1000                        }

      kOhOd:      kilo
                | hOd

      # --- Millions ---
      miljun:       /\bmiljun\b/
      miljuni:      /\bmiljuni\b/

      # żewġ miljuni = 2 million (dual form)
      zewg:         /\bżewġ\b/

      mega:         hOd miljun u kOhOd    { $item[1] * 1_000_000 + $item[4]  }
                  | hOd miljun            { $item[1] * 1_000_000             }
                  | zewg miljuni u kOhOd  { 2_000_000 + $item[4]             }
                  | zewg miljuni          { 2_000_000                         }
                  | miljun u kOhOd        { 1_000_000 + $item[3]              }
                  | miljun                 { 1_000_000                         }
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

Lingua::MLT::Word2Num - Word to number conversion in Maltese

=head1 VERSION

version 0.2603270

Lingua::MLT::Word2Num is module for converting Maltese numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::MLT::Word2Num;

 my $num = Lingua::MLT::Word2Num::w2n( "sbatax" );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (UTF-8 Maltese)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<mlt_numerals> (void)

  =>  obj  new parser object

Internal parser.

=item B<capabilities> (void)

  =>  hashref  with keys 'cardinal' and 'ordinal'

Returns a hashref describing supported conversion types.
Currently: cardinal => 1, ordinal => 0.

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
