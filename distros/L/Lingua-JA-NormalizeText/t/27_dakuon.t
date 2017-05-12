use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/dakuon_normalize handakuon_normalize all_dakuon_normalize/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/dakuon_normalize handakuon_normalize/);

is(   dakuon_normalize("さ\x{309B}" x 2), "ざ" x 2,         "dakuon_normalize");
is(   dakuon_normalize("み\x{3099}" x 2), "み\x{3099}" x 2, "dakuon_normalize");
is(handakuon_normalize("は\x{309A}" x 2), "ぱ" x 2,         "handakuon_normalize");
is(all_dakuon_normalize("さ\x{3099}は\x{309A}" x 2),        "ざぱ" x 2, "all_dakuon_normalize");
is($normalizer->normalize("さ\x{3099}は\x{309A}" x 2),      "ざぱ" x 2, "all dakuon normalizer");

{
    local $Lingua::JA::Dakuon::EnableCombining = 0;
    is(   dakuon_normalize("さ\x{3099}" x 2), "ざ" x 2,    "dakuon_normalize");
    is(   dakuon_normalize("み\x{3099}" x 2), "み" x 2,    "dakuon_normalize");
    is(handakuon_normalize("は\x{309A}" x 2), "ぱ" x 2,    "handakuon_normalize");
    is(all_dakuon_normalize("さ\x{3099}は\x{309A}" x 2),   "ざぱ" x 2, "all_dakuon_normalize");
    is($normalizer->normalize("さ\x{3099}は\x{309A}" x 2), "ざぱ" x 2, "all dakuon normalizer");
}

done_testing;
