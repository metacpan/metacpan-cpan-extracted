use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/:all/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


# nfkc,nfkd,nfc,nfd, decode_entities, strip_html return empty string
#is(nfkc(undef), undef);
#is(nfkd(undef), undef);
#is(nfc(undef), undef);
#is(nfd(undef), undef);
#is(decode_entities(undef), undef);
#is(strip_html(undef), undef);
=begin
is(alnum_z2h(undef), undef);
is(alnum_h2z(undef), undef);
is(space_z2h(undef), undef);
is(space_h2z(undef), undef);
is(katakana_h2z(undef), undef);
is(katakana_z2h(undef), undef);
is(katakana2hiragana(undef), undef);
is(hiragana2katakana(undef), undef);
=end
=cut
is(wave2tilde(undef), undef);
is(tilde2wave(undef), undef);
is(wavetilde2long(undef), undef);
is(wave2long(undef), undef);
is(tilde2long(undef), undef);
is(fullminus2long(undef), undef);
is(dashes2long(undef), undef);
is(drawing_lines2long(undef), undef);
is(unify_long_repeats(undef), undef);
is(nl2space(undef), undef);
is(unify_nl(undef), undef);
is(unify_long_spaces(undef), undef);
is(unify_whitespaces(undef), undef);
is(trim(undef), undef);
is(ltrim(undef), undef);
is(rtrim(undef), undef);
is(old2new_kana(undef), undef);
is(old2new_kanji(undef), undef);
is(tab2space(undef), undef);
is(remove_controls(undef), undef);
is(remove_spaces(undef), undef);
is(remove_DFC(undef), undef);
is(decompose_parenthesized_kanji(undef), undef);
=begin
is(dakuon_normalize(undef), undef);
is(handakuon_normalize(undef), undef);
is(all_dakuon_normalize(undef), undef);
is(square2katakana(undef), undef);
is(circled2kana(undef), undef);
is(circled2kanji(undef), undef);
=end
=cut

=begin
is(nfkc(''), '');
is(nfkd(''), '');
is(nfc(''), '');
is(nfd(''), '');
is(decode_entities(''), '');
is(strip_html(''), '');
is(alnum_z2h(''), '');
is(alnum_h2z(''), '');
is(space_z2h(''), '');
is(space_h2z(''), '');
is(katakana_h2z(''), '');
is(katakana_z2h(''), '');
is(katakana2hiragana(''), '');
is(hiragana2katakana(''), '');
=end
=cut
is(wave2tilde(''), '');
is(tilde2wave(''), '');
is(wavetilde2long(''), '');
is(wave2long(''), '');
is(tilde2long(''), '');
is(fullminus2long(''), '');
is(dashes2long(''), '');
is(drawing_lines2long(''), '');
is(unify_long_repeats(''), '');
is(nl2space(''), '');
is(unify_nl(''), '');
is(unify_long_spaces(''), '');
is(unify_whitespaces(''), '');
is(trim(''), '');
is(ltrim(''), '');
is(rtrim(''), '');
is(old2new_kana(''), '');
is(old2new_kanji(''), '');
is(tab2space(''), '');
is(remove_controls(''), '');
is(remove_spaces(''), '');
is(remove_DFC(''), '');
=begin
is(dakuon_normalize(''), '');
is(handakuon_normalize(''), '');
is(all_dakuon_normalize(''), '');
is(square2katakana(''), '');
is(circled2kana(''), '');
is(circled2kanji(''), '');
=end
=cut

done_testing;
