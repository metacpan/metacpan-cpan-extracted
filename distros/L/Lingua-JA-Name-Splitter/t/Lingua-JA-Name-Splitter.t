use warnings;
use strict;
use Test::More;# tests;# => 3;
BEGIN { use_ok('Lingua::JA::Name::Splitter') };
use Lingua::JA::Name::Splitter qw/split_kanji_name split_romaji_name/;
use utf8;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

# Local variables:
# mode: perl
# End:

my %names = (
    鈴木太郎 => 2,
    福田雅樹 => 2,
    市塚ひろ子 => 2,
    団令子 => 1,
    風太郎 => 1,
    杉浦則夫 => 2,
);

for my $name (keys %names) {
    my ($family, $given) = split_kanji_name ($name);
    ok (length $family eq $names{$name}, "Got $family from $name as expected");
    ok (length ($family) + length ($given) == length ($name),
        "Right name lengths");
}

my $name1 = 'KATSU, Shintaro';
my $name2 = 'Risa Yoshiki';

my ($first1, $last1) = split_romaji_name ($name1);
ok ($first1 eq 'Shintaro', "Split $name1 -> $first1 OK");
ok ($last1 eq 'Katsu', "Split $name1 -> $last1 OK");

my ($first2, $last2) = split_romaji_name ($name2);
ok ($first2 eq 'Risa', "Split $name2 -> $first2 OK");
ok ($last2 eq 'Yoshiki', "Split $name2 -> $last2 OK");

done_testing ();
