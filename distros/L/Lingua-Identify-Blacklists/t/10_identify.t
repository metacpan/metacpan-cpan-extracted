#!/usr/bin/env perl
#-*-perl-*-

use Test::More;
use utf8;

# use FindBin qw/$Bin/;
# use lib "$Bin/../lib";

use Lingua::Identify::Blacklists ':all';


my %texts = ( 'unknown' => '<B8><A4>^A<BA>^R@^P^\^L^',   # CLD things this is En!
	      'en' => 'This is a very short English text',
	      'bs' => 'U Sudu BiH danas je saslušanjem svjedoka optužbe nastavljeno suđenje zločinačkoj organizaciji na čelu sa Zijadom Turkovićem koja se tereti za više monstruoznih likvidacija, međunarodnu trgovinu drogom, pljačku 2,5 miliona maraka iz sarajevskog aerodroma, pranje novca te otimanje dionica fabrike čarapa “Ključ”. Svjedočio je Drago Neimarović zvani Sandokan koji je bio blizak prijatelj ubijenog Marija Tolića. On je kazao da je Turkovića upoznao prije četiri ili pet godina u diskoteci “Party” u Busovači.',
	      'hr' => 'VOĆIN – Unatoč kiši tijekom vikenda u voćinskim šumama i na ratnim ruševinama bivšeg odmarališta Zvečevo na Papuku, Komisija za potrage i lavine GSS-a Hrvatske uspješno je provela trodnevnu vježbu i licenciranje potražnih ekipa u kojoj je sudjelovalo dvadesetak spasilaca i njihovih potražnih pasa iz cijele Hrvatske. Domaćin vježbe bili su podružnica GSS-a Požega i spasilac Stjepan Gal iz Slatine, a u organizaciji vježbe pomogla je Općina Voćin. Malo je poznato da GSS Hrvatske danas ima 550 volontera, spasilaca, od kojih je 350 položilo zahtjevne ispite i dobilo licenciju spašavatelja. Kad god postoji potreba, volonteri velikog srca ostavljaju poslove, sjedaju u automobile i ponekad prelaze više od 800 kilometara samo da bi, bez ikakve naknade, pomogli ljudima u nevolji.',
	      'sr' => 'Održavanje predsedničkih i parlamentarnih izbora na Kosmetu, a pogotovo najava predsednika Opštine Kosovska Mitrovica Krstimira Pantića da će u opštinama na severu Kosova, Zvečanu i Zubinom Potoku, uprkos protivljenju zvaničnog Beograda biti održani i lokalni izbori, alarmirali su NATO. Tako će ova vojna alijansa u srpsku pokrajinu do kraja ove nedelje poslati još 700 vojnika koji će pojačati nemački i austrijski kontingent. Oni će biti stacionirani na punktovima u Kosovskoj Mitrovici i u albanskim selima u opštinama Zvečan i Zubin Potok. Procena komande NATO-a jeste da u slučaju bilo kakvih etnički motivisanih sukoba Euleks ne bi imao dovoljno snage i kapaciteta da zaustavi nasilje.');

foreach my $lang (keys %texts){
    is( identify($texts{$lang}), $lang );
}

done_testing;
