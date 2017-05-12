use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Lingua::JA::Moji qw/hentai2kana hentai2kanji kana2hentai kanji2hentai/;

# Cannot yet copy paste hentaigana into Emacs.

my @shenanigans = qw/
1b002
1b023
1b077
1b11d
/;

my $hentaigana = '';
for (@shenanigans) {
    $hentaigana .= chr (hex ($_));
}
is ($hentaigana, '𛀂𛀣𛁷𛄝', "consistency test of hentaigana data");
is (hentai2kana ($hentaigana), 'あきとん・む・も', "hentaigana to hiragana test");
# round trip regex to test if the round trip gets us back to
# "something like" the originals.
my $rt_re = qr/𛀂.*𛀣.*𛁷.*𛄝/;
like (kana2hentai ('あきとん'), $rt_re, "kana to hentai round trip");
like (kana2hentai ('アキトン'), $rt_re, "katakana to hentai");
is (hentai2kanji ($hentaigana), '安喜土无', "hentaigana to kanji test");
like (kanji2hentai ('安喜土无'), $rt_re, "round trip of kanji forms");
done_testing ();
