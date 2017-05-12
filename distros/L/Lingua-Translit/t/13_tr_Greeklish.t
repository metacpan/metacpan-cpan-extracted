use strict;
use Test::More tests => 6;

my $name	=   "Greeklish";

# Taken from http://www.unhchr.ch/udhr/lang/grk.htm
my $input	=   "Επειδή έχει ουσιαστική σημασία να προστατεύονται τα " .
		    "ανθρώπινα δικαιώματα από ένα καθεστώς δικαίου, ώστε ο " .
		    "άνθρωπος να μην αναγκάζεται να προσφεύγει, ως έσχατο " .
		    "καταφύγιο, στην εξέγερση κατά της τυραννίας και της " .
		    "καταπίεσης.";
my $output_ok	=   "Epidi ehi usiastiki simasia na prostatefontai ta " .
		    "anthropina dikaiomata apo ena kathestos dikaiu, oste " .
		    "o anthropos na min anaykazetai na prosfefyi, os " .
		    "eshato katafiyio, stin exeyersi kata tis tirannias " .
		    "kai tis katapiesis.";

# Taken from http://en.wikipedia.org/wiki/Greeklish#Examples
my $wiki_1	=   "Καλημέρα, πώς είστε;";
my $wiki_1_ok	=   "Kalimera, pos iste?";
my $wiki_2	=   "Θήτα";
my $wiki_2_ok	=   "Thita";

# Check digraphs
my $digraph	=   "ειέιείευέυεύουούόυ";
my $digraph_ok	=   "iiiefefefuuu";

# Upsilon bug fixed?  ("«" -> "I": "Iideoloyika»")
my $bug_1	=   "«ιδεολογικά» -- Ϋ";
my $bug_1_ok	=   "«ideoloyika» -- I";

use Lingua::Translit;

my $tr = new Lingua::Translit($name);


# 1
is($tr->can_reverse(), 0, "$name: not reversible");

my $o = $tr->translit($input);

# 2
is($o, $output_ok, "$name: UDOHR transliteration");

$o = $tr->translit($wiki_1);

# 3
is($o, $wiki_1_ok, "$name: Wikipedia example #1");

$o = $tr->translit($wiki_2);

# 4
is($o, $wiki_2_ok, "$name: Wikipedia example #2");

$o = $tr->translit($digraph);

# 5
is($o, $digraph_ok, "$name: digraphs");

$o = $tr->translit($bug_1);

# 6
is($o, $bug_1_ok, "$name: bugfix #1");
