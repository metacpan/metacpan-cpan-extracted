use strict;
use Test::More tests => 3;

my $truth;

my $name	=   "ISO 843";

# Taken from http://www.unhchr.ch/udhr/lang/grk.htm
my $greek_valid =   "Επειδή η αναγνώριση της αξιοπρέπειας, που είναι " .
		    "σύμφυτη σε όλα τα μέλη της ανθρώπινης οικογένειας, " .
		    "καθώς και των ίσων και αναπαλλοτρίωτων δικαιωμάτων " .
		    "τους αποτελεί το θεμέλιο της ελευθερίας, της " .
		    "δικαιοσύνης και της ειρήνης στον κόσμο.";
my $latin_valid =   "Epeidī́ ī anagnṓrisī tīs axioprépeias, poy eínai " .
		    "sýmfytī se óla ta mélī tīs anthrṓpinīs oikogéneias, " .
		    "kathṓs kai tōn ísōn kai anapallotríōtōn dikaiōmátōn " .
		    "toys apoteleí to themélio tīs eleytherías, tīs " .
		    "dikaiosýnīs kai tīs eirī́nīs ston kósmo.";

my $punct_greek =   "και;";
my $punct_valid =   "kai?";

use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $latin_tr = $tr->translit($greek_valid);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($latin_tr, $latin_valid, "$name: UDOHR transliteration");

my $punct_tr = $tr->translit($punct_greek);

# 3
is($punct_tr, $punct_valid, "$name: punctation transliteration");
