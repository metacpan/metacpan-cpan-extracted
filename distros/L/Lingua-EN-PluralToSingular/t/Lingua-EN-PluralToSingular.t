use warnings;
use strict;
use Test::More;

use Lingua::EN::PluralToSingular 'to_singular', 'is_plural';

my %words = qw/ 
bogus bogus 
citrus citrus 
menus menu 
species species 
flies fly 
monkeys monkey 
children child 
women woman 
mice mouse 
toes toe
potatoes potato
lies lie
flies fly
wolves wolf
knives knife
lives life
geese goose
dishes dish
misses miss
report's report's
bus bus
buses bus
Texas Texas
boxes box
prefixes prefix
various various
previous previous
tenses tense
horses horse
dresses dress
horse horse
dwarves dwarf
mrs mrs
canvases  canvas
geniuses  genius
viruses  virus
abaci abacus
ghetti ghetto
rhinoceri rhinoceros
releases release
/;

for my $word (sort keys %words) { 
    my $s = to_singular ($word); 
    is ($s, $words{$word}, "$s == $words{$word}"); 
} 

my $s = 's';
my $sout = to_singular ($s);
is ($s, $sout, "Don't truncate the single letter 's'");
my $is = 'is';
my $isout = to_singular ($is);
is ($is, $isout, "Don't truncate two letter words ending in 's'");

my %bugs = (qw/
/);

TODO: {
    local $TODO = 'bugs';
    for my $word (sort keys %bugs) { 
        my $s = to_singular ($word); 
        is ($s, $bugs{$word}, "$s == $bugs{$word}"); 
    } 
};

is (is_plural ('cannabis'), 0);
is (is_plural ('nyanburgers'), 1);
is (is_plural ('garfield'), 0);
is (is_plural ('cats'), 1);
is (is_plural ('sheep'), 1);
is (is_plural ('syllabi'), 1);
is (is_plural ('notaniplurali'), 0);
is (is_plural ('alveoli'), 1);
is (is_plural ('improvisatori'), 1);

done_testing ();

# Local variables:
# mode: perl
# End:
