use Test::More tests => 5;
use_ok("Lingua::JP::Kanjidic");
my $x = new Lingua::JP::Kanjidic ("t/minidic");
isa_ok($x, "Lingua::JP::Kanjidic");
use Data::Dumper;
my $a = $x->next;
is_deeply($a->meaning, [ 'Asia', 'rank next', 'come after', '-ous' ],
"Picks up a- OK");
ok($a->joyo, "a- is joyo");
$test = $x->lookup($a->kanji);
is_deeply($a, $test, "Can search");
