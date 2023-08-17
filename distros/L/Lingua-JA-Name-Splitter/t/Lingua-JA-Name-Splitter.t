use warnings;
use strict;
use Test::More;# tests => 38;
use Test::Deep;
use Test::Warnings ':all';
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

# Test split_kanji_name()

my %names = (
    鈴木太郎 => 2,
    福田雅樹 => 2,
    福島ひろ子 => 2,
    団令子 => 1,
    風太郎 => 1,
    杉浦則夫 => 2,
    佐々木順平 => 3,
    佐じ => 1, # Trivially short (for coverage)
    佐张ケイ => 2, # Includes "unknown" kanji (for coverage)
);

for my $name (keys %names) {
    my ($family, $given) = split_kanji_name ($name);
    ok (length $family eq $names{$name}, "Got $family from $name as expected");
    ok (length ($family) + length ($given) == length ($name),
        "Right name lengths");
}

my @warnings = warnings { my @tmp = split_kanji_name () };
cmp_deeply ([@warnings], [re (qr/No valid name was provided to split_kanji_name/)], 'kanji name not supplied warning');

@warnings = warnings { my @tmp = split_kanji_name ('佐') };
cmp_deeply ([@warnings], [re (qr/is only one character long, so there is nothing to split/)], 'kanji name too short warning');

@warnings = warnings { my @tmp = split_kanji_name ('abc') };
cmp_deeply ([@warnings], [re (qr/does not look like a kanji\/kana name/)], 'kanji name not kanji/kana warning');

@warnings = warnings { my $tmp = split_kanji_name ('鈴木太郎') };
cmp_deeply ([@warnings], [re (qr/The return value of split_kanji_name is an array/)], 'kanji not array context warning');

# Test split_romaji_name()

my @romaji_names = (
    ['KATSU, Shintaro', 'Shintaro', 'Katsu'],
    ['Katsu, Shintaro', 'Shintaro', 'Katsu'],
    ['Risa Yoshiki', 'Risa', 'Yoshiki'],
    ['RisaYOSHIKI', 'Risa', 'Yoshiki'],
    ['Yoshiki', '', 'Yoshiki'],
);

for my $case (@romaji_names)
{
    my ($name, $first, $last) = @{$case};
    my ($first1, $last1) = split_romaji_name ($name);
    is ($first1, $first, "Split $name -> first $first1");
    is ($last1, $last, "Split $name -> last $last1");
}

@warnings = warnings { my @tmp = split_romaji_name () };
cmp_deeply ([@warnings], [re (qr/No name given to split_romaji_name/)], 'romaji name not supplied warning');

@warnings = warnings { my $tmp = split_romaji_name ('Risa Yoshiki') };
cmp_deeply ([@warnings], [re (qr/The return value of split_romaji_name is an array/)], 'romaji not array context warning');

@warnings = warnings { my @tmp = split_romaji_name ('Risa XYZ') };
cmp_deeply ([@warnings], [re (qr/doesn't look like Japanese romaji/)], 'romaji name not romaji warning');

@warnings = warnings { my @tmp = split_romaji_name ('Risa Shintaro Katsu') };
cmp_deeply ([@warnings], [re (qr/Strange Japanese name '.*' with middle name\?/)], 'romaji middle name warning');

done_testing ();
