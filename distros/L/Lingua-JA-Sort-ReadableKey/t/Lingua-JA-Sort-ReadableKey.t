use Test::More tests => 25;
use_ok("Lingua::JA::Sort::ReadableKey");
Lingua::JA::Sort::ReadableKey->import;
open IN, "<:utf8", "t/sorting.txt" or die $!;
my @answers = (qw(
ha  O/hiragana
hadaka  O@+/hiragana
hidora  RIc/katakana
hitsuyou  RCl&/hiragana
hitta  RE?/katakana
bin  Sp/hiragana
pin  Tp/katakana
bimbou  Sp\&/hiragana
hijou R8m&/hiragana
jitto 8EH/hiragana
tempura FpWc/hiragana
shouga), "7m&,/hiragana"
);
while (<IN>) {
    chomp;
    my $x = japanese_pronunciation($_);
    is($x, shift @answers, "$x is pronounced correctly");
    is(japanese_sort_order($_), shift @answers, "$x sorts correctly");
}
