use strict;
use Test::More tests => 3;

my $name	=   "Common CES";

# Taken from http://www.unhchr.ch/udhr/lang/czc.htm
my $input	=   "Žádný rozdíl nebude dále činěn z důvodu politického, " .
		    "právního nebo mezinárodního postavení země nebo " .
		    "území, k nimž určitá osoba přísluší, ať jde o zemi " .
		    "nebo území nezávislé nebo pod poručenstvím, " .
		    "nesamosprávné nebo podrobené jakémukoli jinému " .
		    "omezení suverenity.";
my $output_ok	=   "Zadny rozdil nebude dale cinen z duvodu politickeho, " .
		    "pravniho nebo mezinarodniho postaveni zeme nebo " .
		    "uzemi, k nimz urcita osoba prislusi, at jde o zemi " .
		    "nebo uzemi nezavisle nebo pod porucenstvim, " .
		    "nesamospravne nebo podrobene jakemukoli jinemu " .
		    "omezeni suverenity.";

my $all_caps	=   "DĚJSTVÍ PRVNÍ";
my $all_caps_ok	=   "DEJSTVI PRVNI";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($output, $output_ok, "$name: UDOHR transliteration");

my $o = $tr->translit($all_caps);

# 3
is($o, $all_caps_ok, "$name: all caps");
