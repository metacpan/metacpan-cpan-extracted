use strict;
require 5.008;
use utf8;
use Encode;
use Test::More tests => 7;

my $name	=   "DIN 31634";

# Taken from http://www.unhchr.ch/udhr/lang/grk.htm
my $input	=   "Επειδή έχει ουσιαστική σημασία να προστατεύονται τα " .
		    "ανθρώπινα δικαιώματα από ένα καθεστώς δικαίου, ώστε ο " .
		    "άνθρωπος να μην αναγκάζεται να προσφεύγει, ως έσχατο " .
		    "καταφύγιο, στην εξέγερση κατά της τυραννίας και της " .
		    "καταπίεσης.";
my $output_ok	=   "Epeidē echei usiastikē sēmasia na prostateyontai ta " .
		    "anthrōpina dikaiōmata apo ena kathestōs dikaiu, ōste " .
		    "o anthrōpos na mēn anankazetai na prospheygei, ōs " .
		    "eschato kataphygio, stēn exegersē kata tēs tyrannias " .
		    "kai tēs katapiesēs.";

my $txt_1	=   "Νέος ΓΓ του ΝΑΤΟ διορίζεται";
my $txt_1_ok	=   "Neos NG tu NATO diorizetai";

my $txt_2	=   "Γκρουπ 1: Αυστρία, Ελβετία, Ελλάδα, Ολλανδία";
my $txt_2_ok	=   "Gkrup 1: Austria, Elbetia, Ellada, Ollandia";

my $txt_3	=   "Σχετικές αλλαγές"; 
my $txt_3_ok	=   "Schetikes allages";

my $txt_4	=   "Μπιλ Γκρεγκ -- Αυστραλιανό -- δημιουργήθηκε -- Ουσίες";
my $txt_4_ok	=   "Mpil Gkrenk -- Australiano -- dēmiurgēthēke -- Usies";

my $txt_5	=   "εξαϋλωμένο -- προϋπάρχουσα -- Κεϋλάνη";
my $txt_5_ok	=   "exaÿlōmeno -- proÿparchusa -- Keylanē";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

my $o = $tr->translit($input);

# 2
is($o, $output_ok, "$name: UDOHR transliteration");

$o = $tr->translit($txt_1);

# 3
is($o, $txt_1_ok, "$name: Short text #1");

$o = $tr->translit($txt_2);

# 4
is($o, $txt_2_ok, "$name: Short text #2");

$o = $tr->translit($txt_3);

# 5
is($o, $txt_3_ok, "$name: Short text #3");

$o = $tr->translit($txt_4);

# 6
is($o, $txt_4_ok, "$name: Short text #4");

$o = $tr->translit($txt_5);

# 7
is($o, $txt_5_ok, "$name: Short text #5");
