# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-
#
# Copyright (c) PetaMem, s.r.o. 2004-present

package Lingua::JPN::Word2Num;
# ABSTRACT: Word to number conversion in Japanese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block

our $VERSION = '0.2604300';
my $parser   = jpn_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    # Strip ASCII hyphens (didactic romaji forms like "san-zen" or "ichi-man"
    # become "sanzen" / "ichiman"). Also strip leading/trailing whitespace.
    $input =~ s/-/ /g;
    $input =~ s/\A\s+//;
    $input =~ s/\s+\z//;

    return $parser->numeral($input);
}

# }}}
# {{{ jpn_numerals              create parser for Japanese numerals

sub jpn_numerals {
    return Parse::RecDescent->new(<<'GRAMMAR');

      # ── Top-level: try the largest scale first, fall through ─────────────
      numeral:    cho_block      { $item[1] }
                | oku_block      { $item[1] }
                | man_block      { $item[1] }
                | sen_block      { $item[1] }
                | hyaku_block    { $item[1] }
                | ju_block       { $item[1] }
                | digit          { $item[1] }
                | { undef }

      # ── Atomic digits 0..9 in three scripts ───────────────────────────────
      digit:    /(?:零|〇|ぜろ|zero)/i              { 0 }
              | /(?:一|いち|ichi)/i                 { 1 }
              | /(?:二|に|ni)/i                     { 2 }
              | /(?:三|さん|san)/i                  { 3 }
              | /(?:四|よん|よ|yon|shi)/i           { 4 }
              | /(?:五|ご|go)/i                     { 5 }
              | /(?:六|ろく|roku)/i                 { 6 }
              | /(?:七|なな|しち|nana|shichi)/i      { 7 }
              | /(?:八|はち|hachi)/i                { 8 }
              | /(?:九|きゅう|く|kyu|kyuu|ku)/i      { 9 }

      # ── Tens: "十" / "じゅう" / "ju" — bare or digit-prefixed ─────────────
      ju_word:  /(?:十|じゅう|ju)/i

      ju_block:   digit ju_word digit   { $item[1] * 10 + $item[3] }
                | digit ju_word         { $item[1] * 10 }
                | ju_word digit         { 10 + $item[2] }
                | ju_word               { 10 }

      # ── Hundreds — bare 100, irregular 300/600/800, regular 200/400/etc ──
      hyaku_word:  /(?:百|ひゃく|hyaku)/i

      # Irregular hundreds (rendaku/gemination) — kanji form has no
      # phonological irregularity (三百), but hiragana/romaji do.
      hyaku_irregular_3: /(?:さんびゃく|sanbyaku|san\s*byaku)/i        { 300 }
      hyaku_irregular_6: /(?:ろっぴゃく|roppyaku|roku\s*hyaku)/i        { 600 }
      hyaku_irregular_8: /(?:はっぴゃく|happyaku|hachi\s*hyaku)/i       { 800 }

      hyaku_term:   hyaku_irregular_3                       { $item[1] }
                  | hyaku_irregular_6                       { $item[1] }
                  | hyaku_irregular_8                       { $item[1] }
                  | /三/ hyaku_word                          { 300 }
                  | /六/ hyaku_word                          { 600 }
                  | /八/ hyaku_word                          { 800 }
                  | digit hyaku_word                         { $item[1] * 100 }
                  | hyaku_word                               { 100 }

      hyaku_block:  hyaku_term ju_block                      { $item[1] + $item[2] }
                  | hyaku_term digit                         { $item[1] + $item[2] }
                  | hyaku_term

      # ── Thousands — bare 1000, irregular 3000/8000, regular ──────────────
      sen_word:  /(?:千|せん|sen)/i

      sen_irregular_3: /(?:さんぜん|sanzen|san\s*zen|san\s*sen)/i     { 3000 }
      sen_irregular_8: /(?:はっせん|hassen|hachi\s*sen)/i              { 8000 }

      sen_term:   sen_irregular_3                            { $item[1] }
                | sen_irregular_8                            { $item[1] }
                | /三/ sen_word                               { 3000 }
                | /八/ sen_word                               { 8000 }
                | digit sen_word                             { $item[1] * 1000 }
                | sen_word                                   { 1000 }

      sen_block:  sen_term hyaku_block                       { $item[1] + $item[2] }
                | sen_term ju_block                          { $item[1] + $item[2] }
                | sen_term digit                             { $item[1] + $item[2] }
                | sen_term

      # ── 10,000 (man) ──────────────────────────────────────────────────────
      man_word:  /(?:万|まん|man)/i

      # 一万 — bare "man" is also valid input (like Mike Schilli's old API)
      man_term:   sen_block man_word                         { $item[1] * 10_000 }
                | hyaku_block man_word                       { $item[1] * 10_000 }
                | ju_block man_word                          { $item[1] * 10_000 }
                | digit man_word                             { $item[1] * 10_000 }
                | man_word                                   { 10_000 }

      man_block:  man_term sen_block                         { $item[1] + $item[2] }
                | man_term hyaku_block                       { $item[1] + $item[2] }
                | man_term ju_block                          { $item[1] + $item[2] }
                | man_term digit                             { $item[1] + $item[2] }
                | man_term

      # ── 100,000,000 (oku) ────────────────────────────────────────────────
      oku_word:  /(?:億|おく|oku)/i

      oku_term:   sen_block oku_word                         { $item[1] * 100_000_000 }
                | hyaku_block oku_word                       { $item[1] * 100_000_000 }
                | ju_block oku_word                          { $item[1] * 100_000_000 }
                | digit oku_word                             { $item[1] * 100_000_000 }
                | oku_word                                   { 100_000_000 }

      oku_block:  oku_term man_block                         { $item[1] + $item[2] }
                | oku_term sen_block                         { $item[1] + $item[2] }
                | oku_term hyaku_block                       { $item[1] + $item[2] }
                | oku_term ju_block                          { $item[1] + $item[2] }
                | oku_term digit                             { $item[1] + $item[2] }
                | oku_term

      # ── 1,000,000,000,000 (cho) — with whole-block irregular leaders ─────
      cho_word:  /(?:兆|ちょう|cho)/i

      cho_irregular_1:  /(?:いっちょう|itcho|ittchou)/i           { 1_000_000_000_000 }
      cho_irregular_8:  /(?:はっちょう|hatcho|hatchou)/i           { 8_000_000_000_000 }
      cho_irregular_10: /(?:じゅっちょう|jutcho|jucchou|juccho)/i  { 10_000_000_000_000 }

      cho_term:   cho_irregular_1                            { $item[1] }
                | cho_irregular_8                            { $item[1] }
                | cho_irregular_10                           { $item[1] }
                | sen_block cho_word                         { $item[1] * 1_000_000_000_000 }
                | hyaku_block cho_word                       { $item[1] * 1_000_000_000_000 }
                | ju_block cho_word                          { $item[1] * 1_000_000_000_000 }
                | digit cho_word                             { $item[1] * 1_000_000_000_000 }
                | cho_word                                   { 1_000_000_000_000 }

      cho_block:  cho_term oku_block                         { $item[1] + $item[2] }
                | cho_term man_block                         { $item[1] + $item[2] }
                | cho_term sen_block                         { $item[1] + $item[2] }
                | cho_term hyaku_block                       { $item[1] + $item[2] }
                | cho_term ju_block                          { $item[1] + $item[2] }
                | cho_term digit                             { $item[1] + $item[2] }
                | cho_term

GRAMMAR
}

# }}}
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Japanese ordinal suffix:
    #   kanji:    番目
    #   hiragana: ばんめ
    #   romaji:   -ban-me  (or "ban me" / "banme")
    $input =~ s{番目\z}{}xms                  and return $input;
    $input =~ s{ばんめ\z}{}xms                  and return $input;
    $input =~ s{[\s-]?ban[\s-]?me\z}{}xms      and return $input;

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::JPN::Word2Num - Word to number conversion in Japanese

=head1 VERSION

version 0.2604300

=head1 SYNOPSIS

  use Lingua::JPN::Word2Num qw(w2n);

  # Kanji
  say w2n('三千');                  # 3000
  say w2n('千二百三十四');             # 1234

  # Hiragana
  say w2n('さんぜん');                # 3000
  say w2n('せんにひゃくさんじゅうよん');  # 1234

  # Romaji — natural forms with rendaku
  say w2n('sanzen');                # 3000
  say w2n('roppyaku');              # 600
  say w2n('hassen');                # 8000

  # Romaji — legacy un-rendaku'd forms (also accepted)
  say w2n('san sen');               # 3000
  say w2n('roku hyaku');            # 600

=head1 DESCRIPTION

Converts Japanese numeral text to integer values. Accepts input in
B<kanji>, B<hiragana>, or B<romaji> — script is auto-detected.

For romaji, both the canonical native pronunciation (with rendaku and
gemination, e.g. C<sanzen>, C<roppyaku>, C<hassen>) and the older
un-rendaku'd transliteration (C<san sen>, C<roku hyaku>, C<hachi sen>)
are accepted. Output canonical text comes from L<Lingua::JPN::Num2Word>;
this module is intentionally permissive on input.

Recognised range: 0 to 9,999,999,999,999,999 (just under 10^16).

=head1 FUNCTIONS

=over 2

=item B<w2n>($text)

Convert text representation to a number. Returns C<undef> if the input
is not recognised as a Japanese numeral.

=item B<ordinal2cardinal>($text)

Convert ordinal text to cardinal text by stripping the ordinal suffix
(番目 / ばんめ / -ban-me). Returns C<undef> if the input is not an ordinal.

=item B<jpn_numerals> (void)

Internal — returns a fresh L<Parse::RecDescent> parser object.

=back

=cut

# }}}
# {{{ EXPORT_OK

=pod

=head1 EXPORT_OK

=over 2

=item w2n

=item ordinal2cardinal

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
