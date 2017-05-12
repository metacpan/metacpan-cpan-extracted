 ################################################
#						#
#	Copyleft by algirdas @ perl.lt		#
#						#
 ################################################

package Metai::Kalendorius;
use strict;

our $VERSION = 0.07;

=head1 NAME


Metai::Kalendorius - Lithuanian calendar.


=head1 SYNOPSIS


	use Metai::Kalendorius;
	use POSIX qw(strftime);

	my $data = strftime "%Y.%m.%d", localtime;

	# Lithuanian day-names
	print Metai::Kalendorius->vardai($data,'utf-8');
	# Lithuanian zodiac name
	print Metai::Kalendorius->zodiakas($data,'www');
	# Lithuanian time of year name
	print Metai::Kalendorius->metu_laikas($data,'utf-8');
	# Lithuanian month name
	print Metai::Kalendorius->menuo($data,'www');
	# Lithuanian day name
	print Metai::Kalendorius->diena($data,'www');


=head1 DESCRIPTION


This module provides subroutines that return Lithuanian day-names/zodiac name/time of year name/month name/day name, based on date.
Each of those can be returned in utf-8 (default) encoding and "www" type (f.e. Vai&#154;vilas).


=head2 vardai


Lithuanian day-names:			Metai::Kalendorius->vardai('2006.12.22');


=head2 zodiakas


Lithuanian zodiac name:			Metai::Kalendorius->zodiakas('2006.12.22');


=head2 metu_laikas


Lithuanian time of year name:		Metai::Kalendorius->metu_laikas('2006.12.22');


=head2 menuo


Lithuanian month name:			Metai::Kalendorius->menuo('2006.12.22');


=head2 diena


Lithuanian day name:			Metai::Kalendorius->diena('2006.12.22');


=head1 AUTHOR


Algirdas R. E<lt>algirdas@perl.ltE<gt>


=cut


sub vardai {
 my ($metai,$menuo,$diena,$koduote) = tikrinimas($_[1],$_[2]);

 my $vardai;
 if ($menuo == 1) {
  if    ($diena == 1)	{ $vardai = 'Me&#0269;islovas,Arvaidas,Arvaid&#0279;,Eufrozija,Me&#0269;ys,Eufrozina'; }
  elsif ($diena == 2)	{ $vardai = 'Bazilijus,Grigalius,Ma&#0380;vydas,Gailut&#0279;,Fulgentas,Stefanija'; }
  elsif ($diena == 3)	{ $vardai = 'Genovait&#0279;,Viltautas,Vyda,Vida'; }
  elsif ($diena == 4)	{ $vardai = 'Arimantas,Arimant&#0279;,Titas,Benediktas,Arminas,Benas,Armin&#0279;,And&#0380;elika,An&#0380;elika'; }
  elsif ($diena == 5)	{ $vardai = 'Simonas,Vytautas,Vytaut&#0279;,Telesforas,Gaudentas,Simas'; }
  elsif ($diena == 6)	{ $vardai = 'Baltazaras,Kasparas,Merkelis,Ar&#0363;nas,Ar&#0363;n&#0279;,Melchioras'; }
  elsif ($diena == 7)	{ $vardai = 'Liucijus,Raimundas,Valentinas,R&#0363;tenis,Raudvil&#0279;'; }
  elsif ($diena == 8)	{ $vardai = 'Apolinaras,Severinas,Teofilius,Vilintas,Gint&#0279;,Teofilis'; }
  elsif ($diena == 9)	{ $vardai = 'Bazil&#0279;,Julijonas,Algis,Gabija,Marcijona'; }
  elsif ($diena == 10)	{ $vardai = 'Agatonas,Vilhelmas,Ginvilas,Ginvil&#0279;,Vilius'; }
  elsif ($diena == 11)	{ $vardai = 'Marcijonas,Stefanija,Audrius,Viln&#0279;,Palemonas'; }
  elsif ($diena == 12)	{ $vardai = 'Arkadijus,Cezarija,Cezarijus,Vaigedas,Lingail&#0279;,Ernestas,Cezar&#0279;,Cezaris'; }
  elsif ($diena == 13)	{ $vardai = 'Veronika,Dargaudas,Gilvyd&#0279;,Iveta,Raimonda,Vera,Hiliaras'; }
  elsif ($diena == 14)	{ $vardai = 'Feliksas,Teodozijus,Auks&#0279;,Hilarijus,Laimis'; }
  elsif ($diena == 15)	{ $vardai = 'Paulius,Skirgaila,Snieguol&#0279;,Meda,Povilas'; }
  elsif ($diena == 16)	{ $vardai = 'Marcelis,Norgailas,Norgail&#0279;'; }
  elsif ($diena == 17)	{ $vardai = 'Antanas,Dovainis,Vilda,Leonil&#0279;'; }
  elsif ($diena == 18)	{ $vardai = 'Gedgaudas,Jogail&#0279;,Liberta,Jolita'; }
  elsif ($diena == 19)	{ $vardai = 'Kanutas,Marijus,Morta,Raivedys,Gedvil&#0279;,Marius'; }
  elsif ($diena == 20)	{ $vardai = 'Fabijonas,Sebastijonas,Daugvydas,Nomeda'; }
  elsif ($diena == 21)	{ $vardai = 'Agniet&#0279;,Galiginas,Gars&#0279;,Ineza,Inesa,Ineta,Ina'; }
  elsif ($diena == 22)	{ $vardai = 'Anastazas,Gaudentas,Vincentas,Au&#0353;rius,Skaist&#0279;,D&#0380;iugas,Vincas'; }
  elsif ($diena == 23)	{ $vardai = 'Gailigedas,Gunda,Raimundas'; }
  elsif ($diena == 24)	{ $vardai = 'Pranci&#0353;kus,Vilgaudas,Gaivil&#0279;,Art&#0363;ras,Felicija'; }
  elsif ($diena == 25)	{ $vardai = 'Viltenis,&#0381;ied&#0279;,Povilas,Paulius'; }
  elsif ($diena == 26)	{ $vardai = 'Timotiejus,Titas,Rimantas,Eigil&#0279;,Justas,Paul&#0279;,Rimas'; }
  elsif ($diena == 27)	{ $vardai = 'Angel&#0279;,Jogundas,Jogund&#0279;,Natalis,Ilona,Anel&#0279;'; }
  elsif ($diena == 28)	{ $vardai = 'Tomas,Gedautas,Nijol&#0279;,Leonidas,Manfredas'; }
  elsif ($diena == 29)	{ $vardai = 'Girkantas,&#0381;ibut&#0279;,Valerijus,Aivaras'; }
  elsif ($diena == 30)	{ $vardai = 'Hiacinta,Jacinta,Martyna,Milgaudas,Banguol&#0279;,Ipolitas,Liudvika,Mart&#0279;,Liuda'; }
  elsif ($diena == 31)	{ $vardai = 'Liudvika,Liuda,Marcel&#0279;,Skirmantas,Budvil&#0279;,Luiza,Skirmant&#0279;'; }
 }
 elsif ($menuo == 2) {
  if    ($diena == 1)	{ $vardai = 'Pijonijus,Gytautas,Eidvil&#0279;,Ignotas,Brigita'; }
  elsif ($diena == 2)	{ $vardai = 'Rytys,Vanden&#0279;,Valdemaras,Kandidas,Rytis,Valdon&#0279;,Valdas,Orintas,Orinta'; }
  elsif ($diena == 3)	{ $vardai = 'Oskaras,Bla&#0380;iejus,Radvilas,Radvil&#0279;,Bla&#0380;ys,Asta'; }
  elsif ($diena == 4)	{ $vardai = 'Andriejus,Vydmantas,Arvil&#0279;,Joana,Andrius,Vidmantas'; }
  elsif ($diena == 5)	{ $vardai = 'Agota,Gaudvinas,Birut&#0279;'; }
  elsif ($diena == 6)	{ $vardai = 'Darata,Paulius,Alkis,&#0381;yvil&#0279;,Titas,Povilas,&#0381;ivil&#0279;,Urt&#0279;,Oksana'; }
  elsif ($diena == 7)	{ $vardai = 'Ri&#0269;ardas,Vildaugas,Jomant&#0279;,Romualdas,Vilgirdas,Vilgird&#0279;'; }
  elsif ($diena == 8)	{ $vardai = 'Aldona,Jeronimas,Dromantas,Daugvil&#0279;,Saliamonas,Honorata,Salys'; }
  elsif ($diena == 9)	{ $vardai = 'Apolonija,Marijus,Joviltas,Alg&#0279;,Erikas,Pol&#0279;,Erika'; }
  elsif ($diena == 10)	{ $vardai = 'Skolastika,Girvydas,Vydgail&#0279;,Gabrielius,Elvyra,Skol&#0279;'; }
  elsif ($diena == 11)	{ $vardai = 'Teodora,Algirdas,Algird&#0279;,Adolfas,Liucijus,Evelina'; }
  elsif ($diena == 12)	{ $vardai = 'Benediktas,Reginaldas,Mantminas,Deimant&#0279;,Eulalija'; }
  elsif ($diena == 13)	{ $vardai = 'Kotryna,Algaudas,Ugn&#0279;,Benignas'; }
  elsif ($diena == 14)	{ $vardai = 'Kirilas,Valentinas,Saulius,Saul&#0279;,Liliana,Lijana'; }
  elsif ($diena == 15)	{ $vardai = 'Faustinas,Jordanas,Zygfridas,Girdenis,Girden&#0279;,Jovita,Jurgina,Jurgita,Vytis'; }
  elsif ($diena == 16)	{ $vardai = 'Julijona,Julijonas,Tautvyd&#0279;'; }
  elsif ($diena == 17)	{ $vardai = 'Aleksas,Vai&#0353;vilas,Vilt&#0279;,Donatas,Donata'; }
  elsif ($diena == 18)	{ $vardai = 'Bernadeta,Simeonas,Lengvenis,Gendr&#0279;,Simas'; }
  elsif ($diena == 19)	{ $vardai = 'Konradas,&#0352;ar&#0363;nas,Nida,Zuzana'; }
  elsif ($diena == 20)	{ $vardai = 'Leonas,Visgintas,Eitvyd&#0279;'; }
  elsif ($diena == 21)	{ $vardai = 'Eleonora,K&#0281;stutis,&#0381;emyna,Feliksas'; }
  elsif ($diena == 22)	{ $vardai = 'Darvydas,Gintaut&#0279;,Elvinas,Margarita'; }
  elsif ($diena == 23)	{ $vardai = 'Gantautas,Butvil&#0279;,Severinas,Romana,Roma'; }
  elsif ($diena == 24)	{ $vardai = 'Demetrija,Gedmantas,Goda,Motiejus,Matas'; }
  elsif ($diena == 25)	{ $vardai = 'Viktoras,Margiris,Rasa,Regimantas'; }
  elsif ($diena == 26)	{ $vardai = 'Aleksandras,Jogintas,Aurim&#0279;,Izabel&#0279;,Sandra'; }
  elsif ($diena == 27)	{ $vardai = 'Gabrielius,Ginvilas,Skirmant&#0279;,Fortunatas,Livija,Mandravas,Mandrav&#0279;'; }
  elsif ($diena == 28)	{ $vardai = 'Osvaldas,Romanas,Vilgardas,&#0381;ygimant&#0279;,Romas'; }
  elsif ($diena == 29)	{ $vardai = 'Gustis,Tolvaldas'; }
 }
 elsif ($menuo == 3) {
  if    ($diena == 1)	{ $vardai = 'Albinas,Tulgaudas,Rusn&#0279;,Antanina,Antan&#0279;'; }
  elsif ($diena == 2)	{ $vardai = 'Simplicijus,Eitautas,Dautara,Marcelinas,Elena'; }
  elsif ($diena == 3)	{ $vardai = 'Kunigunda,Uosis,Tul&#0279;,Nonita'; }
  elsif ($diena == 4)	{ $vardai = 'Kazimieras,Daugvydas,Daina,Vaclava,Kazys,Vac&#0279;'; }
  elsif ($diena == 5)	{ $vardai = 'Austra,Aurora,Liucijus,Vydotas,Giedr&#0279;,Klemensas,Virgilijus'; }
  elsif ($diena == 6)	{ $vardai = 'Gerasimas,Norvilas,Raminta,Ro&#0380;&#0279;'; }
  elsif ($diena == 7)	{ $vardai = 'Felicita,Rimtautas,Galmant&#0279;,Tomas,Laima'; }
  elsif ($diena == 8)	{ $vardai = 'Vydminas,Gaudvil&#0279;,Beata'; }
  elsif ($diena == 9)	{ $vardai = 'Dominykas,Domas,Pranci&#0353;ka,&#0381;ygintas,Visgail&#0279;,Pran&#0279;'; }
  elsif ($diena == 10)	{ $vardai = 'Silvija,Naubartas,Butgail&#0279;,Emilis,Geraldas'; }
  elsif ($diena == 11)	{ $vardai = 'Konstantinas,Gedimtas,Vijol&#0279;,Kostas'; }
  elsif ($diena == 12)	{ $vardai = 'Teofanas,Galvirdas,Darmant&#0279;'; }
  elsif ($diena == 13)	{ $vardai = 'Paulina,Liutauras,Vaidil&#0279;,Kristina,Teodora'; }
  elsif ($diena == 14)	{ $vardai = 'Matilda,Darmantas,Karigail&#0279;'; }
  elsif ($diena == 15)	{ $vardai = 'Klemensas,Lukrecija,Tautas,Tautgint&#0279;,Lionginas,Tautgin&#0279;,Raigardas'; }
  elsif ($diena == 16)	{ $vardai = 'Julijonas,Vaidotas,Norvald&#0279;,Henrika,Norvil&#0279;'; }
  elsif ($diena == 17)	{ $vardai = 'Gerda,Patrikas,Gentvila,Var&#0363;na,Gertr&#0363;da,Gendvilas,Vita'; }
  elsif ($diena == 18)	{ $vardai = 'Kirilas,Eimutis,Eimut&#0279;,Anzelmas,Sibil&#0279;'; }
  elsif ($diena == 19)	{ $vardai = 'Juozapas,Vilys,Vil&#0279;,Juozas'; }
  elsif ($diena == 20)	{ $vardai = '&#0381;ygimantas,Tautvil&#0279;,Filomenas,Irmgarda,Irma,Irmantas'; }
  elsif ($diena == 21)	{ $vardai = 'Mikalojus,Nortautas,Lingail&#0279;,Benediktas,Reda'; }
  elsif ($diena == 22)	{ $vardai = 'Benvenutas,Kotryna,Gedgaudas,Gedgaud&#0279;'; }
  elsif ($diena == 23)	{ $vardai = 'Galgintas,Vismant&#0279;,Alfonsas,Akvil&#0279;,&#0362;la'; }
  elsif ($diena == 24)	{ $vardai = 'Liucija,Daumantas,Ganvil&#0279;,Gabrielius,Donardas'; }
  elsif ($diena == 25)	{ $vardai = 'Normantas,Normant&#0279;'; }
  elsif ($diena == 26)	{ $vardai = 'Feliksas,Liudgaras,Arbutas,Vydmant&#0279;,Emanuelis,Tekl&#0279;,Laimis'; }
  elsif ($diena == 27)	{ $vardai = 'Nikodemas,Rupertas,Alkmenas,R&#0363;ta,Aleksandras,Lidija'; }
  elsif ($diena == 28)	{ $vardai = 'Filemonas,Sikstas,Rimkantas,Girmant&#0279;,Odeta'; }
  elsif ($diena == 29)	{ $vardai = 'Narcizas,Almant&#0279;,Bertoldas,Manvydas'; }
  elsif ($diena == 30)	{ $vardai = 'Gvidonas,Virmantas,Meda,Ferdinandas'; }
  elsif ($diena == 31)	{ $vardai = 'Benjaminas,Ginas,Gina,Kornelija'; }
 }
 elsif ($menuo == 4) {
  if    ($diena == 1)	{ $vardai = 'Hugonas,Teodora,Teodoras,Rimgaudas,Dainora'; }
  elsif ($diena == 2)	{ $vardai = 'Pranci&#0353;kus,Jostautas,Jostaut&#0279;,Pranas,Elona'; }
  elsif ($diena == 3)	{ $vardai = 'Irena,Ri&#0269;ardas,Vytenis,Rimtaut&#0279;,Kristijonas'; }
  elsif ($diena == 4)	{ $vardai = 'Izidorius,Algaudas,Egl&#0279;,Ambraziejus'; }
  elsif ($diena == 5)	{ $vardai = 'Krescencija,Vincentas,Rimvydas,&#0381;ygint&#0279;,Zenonas,Irena,Zenius'; }
  elsif ($diena == 6)	{ $vardai = 'Celestinas,Daugirutis,&#0381;intaut&#0279;,Gerardas'; }
  elsif ($diena == 7)	{ $vardai = 'Minvydas,Kantaut&#0279;,Hermanas,Donata'; }
  elsif ($diena == 8)	{ $vardai = 'Valteris,Girtautas,Skirgail&#0279;,Dionizas,Julija,Alma'; }
  elsif ($diena == 9)	{ $vardai = 'Paladijus,Aurimas,Dalia,Kleopas,Gitana,Gitanas'; }
  elsif ($diena == 10)	{ $vardai = 'Apolonijus,Mintautas,Agna,Margarita'; }
  elsif ($diena == 11)	{ $vardai = 'Stanislovas,Vykintas,Daugail&#0279;,Leonas'; }
  elsif ($diena == 12)	{ $vardai = 'Julijus,Zenonas,Galmantas,J&#0363;rat&#0279;,Damijonas,Julius'; }
  elsif ($diena == 13)	{ $vardai = 'Martynas,Mingaudas,Algaud&#0279;,Ida'; }
  elsif ($diena == 14)	{ $vardai = 'Liudvika,Liuda,Valerijonas,Vai&#0353;vyd&#0279;,Visvaldas,Justinas,Luiza'; }
  elsif ($diena == 15)	{ $vardai = 'Gema,Vilnius,Vaidot&#0279;,Modestas,Anastazijus,Liudvina'; }
  elsif ($diena == 16)	{ $vardai = 'Benediktas,Giedrius,Alged&#0279;,Kalikstas'; }
  elsif ($diena == 17)	{ $vardai = 'Anicetas,Dravenis,Skaidra,Robertas'; }
  elsif ($diena == 18)	{ $vardai = 'Apolonijus,Eitvilas,Girmant&#0279;'; }
  elsif ($diena == 19)	{ $vardai = 'Leonas,Leontina,Eirimas,Aist&#0279;,Simonas,Laisv&#0363;nas,Laisv&#0363;n&#0279;'; }
  elsif ($diena == 20)	{ $vardai = 'Gostautas,Eisvyd&#0279;,Marcijonas,Agn&#0279;'; }
  elsif ($diena == 21)	{ $vardai = 'Anzelmas,Konradas,Milgedas,Skalv&#0279;,Amalija'; }
  elsif ($diena == 22)	{ $vardai = 'Kajus,Visgailas,Norvaid&#0279;,Leonidas,Leonas,Vadimas'; }
  elsif ($diena == 23)	{ $vardai = 'Adalbertas,Jurgis,Daugaudas,Vygail&#0279;,Jurgita,Jurga'; }
  elsif ($diena == 24)	{ $vardai = 'Fidelis,Kantrimas,Gra&#0380;vyda,Ervina'; }
  elsif ($diena == 25)	{ $vardai = 'Morkus,Tolmantas,&#0381;admant&#0279;'; }
  elsif ($diena == 26)	{ $vardai = 'Gailenis,Dargail&#0279;,Klaudijus,Vil&#0363;n&#0279;'; }
  elsif ($diena == 27)	{ $vardai = 'Anastazas,Zita,Gotautas,Au&#0353;ra,&#0381;ydr&#0279;,Edilija'; }
  elsif ($diena == 28)	{ $vardai = 'Prudencijus,Valerija,Vygantas,Rimgail&#0279;,Vitalius'; }
  elsif ($diena == 29)	{ $vardai = 'Kotryna,Tarmantas,Indr&#0279;,Augustinas,Rita'; }
  elsif ($diena == 30)	{ $vardai = 'Marijonas,Pijus,Virbutas,Venta,Sofija'; }
 }
 elsif ($menuo == 5) {
  if    ($diena == 1)	{ $vardai = 'Juozapas,Zigmantas,&#0381;ilvinas,Vydmant&#0279;,Anel&#0279;,Zigmas'; }
  elsif ($diena == 2)	{ $vardai = 'Atanazas,Eidmantas,Meil&#0279;'; }
  elsif ($diena == 3)	{ $vardai = 'Aleksandras,Jok&#0363;bas,Juvenalis,Pilypas,Arvystas,Kantvyd&#0279;'; }
  elsif ($diena == 4)	{ $vardai = 'Antanina,Florijonas,Dargailas,Mintaut&#0279;,Monika,Vitalija'; }
  elsif ($diena == 5)	{ $vardai = 'Irena,Mykolas,Barvydas,Neris,Pijus,Angelas,Anielius'; }
  elsif ($diena == 6)	{ $vardai = 'Judita,Minvydas,Eidmant&#0279;,Liucijus,Benedikta,Ben&#0279;'; }
  elsif ($diena == 7)	{ $vardai = 'Domicel&#0279;,Domicijonas,Butautas,Rimut&#0279;,Danut&#0279;,Stanislovas'; }
  elsif ($diena == 8)	{ $vardai = 'Stanislovas,Viktoras,D&#0380;iugas,Audr&#0279;,Mykolas,Stasys'; }
  elsif ($diena == 9)	{ $vardai = 'Beatas,Edita,Mingailas,Aust&#0279;ja,Grigalius'; }
  elsif ($diena == 10)	{ $vardai = 'Antoninas,Putinas,Sangail&#0279;,Viktorina'; }
  elsif ($diena == 11)	{ $vardai = 'Mamertas,Skirgaudas,Migl&#0279;,Pilypas'; }
  elsif ($diena == 12)	{ $vardai = 'Achilas,Ner&#0279;jas,Vaidutis,Vilgail&#0279;,Ner&#0279;jas,Nerys,Nerijus'; }
  elsif ($diena == 13)	{ $vardai = 'Tautmilas,Alvyd&#0279;,Milda'; }
  elsif ($diena == 14)	{ $vardai = 'Motiejus,Gintaras,Vilda,Bonifacas,Gintar&#0279;'; }
  elsif ($diena == 15)	{ $vardai = 'Izidorius,Sofija,Algedas,Jaunut&#0279;,Zofija'; }
  elsif ($diena == 16)	{ $vardai = 'Andriejus,Ubaldas,Vaidmantas,Bit&#0279;,Andrius'; }
  elsif ($diena == 17)	{ $vardai = 'Paskalis,Virkantas,Gail&#0279;,Bazil&#0279;'; }
  elsif ($diena == 18)	{ $vardai = 'Erikas,Erdvilas,Ryt&#0279;,Julita,Venancijus'; }
  elsif ($diena == 19)	{ $vardai = 'Gilvinas,Tauras,Celestinas'; }
  elsif ($diena == 20)	{ $vardai = 'Bernardinas,Eidvilas,Vygint&#0279;,Akvilas,Alfreda'; }
  elsif ($diena == 21)	{ $vardai = 'Teobaldas,Vaidivutis,Vydmina,Valentas,Aldas,Vaidevutis'; }
  elsif ($diena == 22)	{ $vardai = 'Elena,Julija,Rita,Eimantas,Aldona,Jul&#0279;'; }
  elsif ($diena == 23)	{ $vardai = 'Gertautas,Tautvyd&#0279;,Ivona,&#0381;ydr&#0363;n&#0279;,&#0381;ydr&#0363;nas'; }
  elsif ($diena == 24)	{ $vardai = 'Joana,&#0381;aneta,Vincentas,Vilmantas,Gina,Gerardas,&#0381;ana'; }
  elsif ($diena == 25)	{ $vardai = 'Bedas,Magdalena,Almantas,Danut&#0279;,Urbonas,Evelina'; }
  elsif ($diena == 26)	{ $vardai = 'Pilypas,Algimantas,Milvyd&#0279;,Eduardas,Vilhelmina'; }
  elsif ($diena == 27)	{ $vardai = 'Augustinas,Genadijus,Virgaudas,&#0381;ymant&#0279;,Brunonas,Leonora'; }
  elsif ($diena == 28)	{ $vardai = 'Justas,Jogirdas,Rima,Augustinas'; }
  elsif ($diena == 29)	{ $vardai = 'Teodozija,Algedas,Erdvil&#0279;,Magdalena,Magd&#0279;'; }
  elsif ($diena == 30)	{ $vardai = 'Ferdinandas,Joana,&#0381;aneta,Vyliaudas,Jomil&#0279;,&#0381;ana'; }
  elsif ($diena == 31)	{ $vardai = 'Petron&#0279;l&#0279;,Gintautas,Rimvil&#0279;,Angel&#0279;,Petr&#0279;'; }
 }
 elsif ($menuo == 6) {
  if    ($diena == 1)	{ $vardai = 'Justinas,Jogaila,Galind&#0279;,Konradas,Juvencijus'; }
  elsif ($diena == 2)	{ $vardai = 'Erazmas,Marcelinas,&#0260;&#0380;uolas,Auks&#0279;,Eugenijus'; }
  elsif ($diena == 3)	{ $vardai = 'Karolis,Klotilda,Tautkantas,Dovil&#0279;'; }
  elsif ($diena == 4)	{ $vardai = 'Pranci&#0353;kus,Dausprungas,Deimena,Kornelijus,Vincentas,Vinc&#0279;,Vincenta'; }
  elsif ($diena == 5)	{ $vardai = 'Bonifacas,Vinfridas,Kantautas,Kantvyd&#0279;,Marc&#0279;'; }
  elsif ($diena == 6)	{ $vardai = 'Bogumilas,Klaudijus,Norbertas,Tauras,M&#0279;ta,Paulina'; }
  elsif ($diena == 7)	{ $vardai = 'Robertas,Ratautas,Radvyd&#0279;,Lukrecija,Roberta'; }
  elsif ($diena == 8)	{ $vardai = 'Medardas,Mer&#0363;nas,Eigint&#0279;'; }
  elsif ($diena == 9)	{ $vardai = 'Efremas,Felicijonas,Gintas,Gint&#0279;,Felicijus,Vitalija'; }
  elsif ($diena == 10)	{ $vardai = 'Diana,Liutgarda,Pelagija,Galindas,Vingail&#0279;,Margarita'; }
  elsif ($diena == 11)	{ $vardai = 'Barnabas,Tvirmantas,Aluona,Flora'; }
  elsif ($diena == 12)	{ $vardai = 'Anupras,Ram&#0363;nas,Dov&#0279;,Kristijonas,Kristis,Vilma,Krist&#0279;'; }
  elsif ($diena == 13)	{ $vardai = 'Antanas,Kunotas,Skalv&#0279;,Akvilina'; }
  elsif ($diena == 14)	{ $vardai = 'Rufinas,Valerijus,Labvardas,Almina,Bazilijus,Digna'; }
  elsif ($diena == 15)	{ $vardai = 'Jolanta,Vitas,Tanvilas,Bargail&#0279;,Krescencija'; }
  elsif ($diena == 16)	{ $vardai = 'Benas,Julita,Tolminas,J&#0363;ra'; }
  elsif ($diena == 17)	{ $vardai = 'Grigalius,Daugantas,Vilmant&#0279;,Adolfas,Laura'; }
  elsif ($diena == 18)	{ $vardai = 'Marcelinas,Morkus,Ginbutas,Vaiva,Arnulfas,Marina'; }
  elsif ($diena == 19)	{ $vardai = 'Julijona,Romualdas,Dovilas,Ramun&#0279;,Deodatas,Romas'; }
  elsif ($diena == 20)	{ $vardai = 'Florentina,Silverijus,&#0381;advainas,&#0381;intaut&#0279;,Nandas'; }
  elsif ($diena == 21)	{ $vardai = 'Aloyzas,Galminas,Vasar&#0279;,Alicija'; }
  elsif ($diena == 22)	{ $vardai = 'Paulinas,Tomas,Kaributas,Laima,Inocentas'; }
  elsif ($diena == 23)	{ $vardai = 'Agripina,Arvydas,Vaida,Zenonas,Vanda,Vaidas,Ligita'; }
  elsif ($diena == 24)	{ $vardai = 'Jonas,Eivilitas,Eivilit&#0279;,Eiviltas,Janina'; }
  elsif ($diena == 25)	{ $vardai = 'Vilhelmas,Geistautas,Geistaut&#0279;,Baniut&#0279;,Vilius,Geisvyda,Geisvydas'; }
  elsif ($diena == 26)	{ $vardai = 'Paulius,Jaunutis,Virgilijus,Povilas,Jaunius,Viltaut&#0279;'; }
  elsif ($diena == 27)	{ $vardai = 'Ema,Kirilas,Vladislovas,Gediminas,Norgail&#0279;,Vladas'; }
  elsif ($diena == 28)	{ $vardai = 'Iren&#0279;jus,Tulgedas,Gaudr&#0279;'; }
  elsif ($diena == 29)	{ $vardai = 'Paulius,Petras,Mantigirdas,Gedrim&#0279;,Benita,Povilas'; }
  elsif ($diena == 30)	{ $vardai = 'Otonas,Otas,Tautginas,Novil&#0279;,Emilija,Liucina'; }
 }
 elsif ($menuo == 7) {
  if    ($diena == 1)	{ $vardai = 'Julijus,Tautrimas,Liepa,Julius'; }
  elsif ($diena == 2)	{ $vardai = 'Martinijonas,Jotvingas,Gantaut&#0279;,Marijonas,Martys'; }
  elsif ($diena == 3)	{ $vardai = 'Anatolijus,Leonas,Tomas,Vaidilas,Liaudmina'; }
  elsif ($diena == 4)	{ $vardai = 'Berta,El&#0380;bieta,Ulrikas,Skalvis,Gedgail&#0279;,Teodoras,Malvina'; }
  elsif ($diena == 5)	{ $vardai = 'Antanas,Butginas,Mantmil&#0279;,Karolina,Filomena'; }
  elsif ($diena == 6)	{ $vardai = 'Marija,Nervydas,Ginvil&#0279;,Dominyka,Dom&#0279;,Mindaugas,Nervil&#0279;,Nervilas,Neril&#0279;,Nerilis'; }
  elsif ($diena == 7)	{ $vardai = 'Sangailas,Vilgail&#0279;,Estera,Astijus'; }
  elsif ($diena == 8)	{ $vardai = 'Vaitautas,Valmant&#0279;,Arnoldas,El&#0380;bieta,Elz&#0279;,Virginija,Virga'; }
  elsif ($diena == 9)	{ $vardai = 'Marcelina,Veronika,Algirdas,Algird&#0279;,Leonardas,Marc&#0279;,Vera'; }
  elsif ($diena == 10)	{ $vardai = 'Amalija,Prudencija,Rufina,Gilvainas,Eirim&#0279;'; }
  elsif ($diena == 11)	{ $vardai = 'Benediktas,Vilmantas,&#0352;ar&#0363;n&#0279;,Pijus,Kipras'; }
  elsif ($diena == 12)	{ $vardai = 'Bonifacas,Brunonas,Sigisbertas,Margiris,Vyliaud&#0279;,Izabel&#0279;,Sigitas'; }
  elsif ($diena == 13)	{ $vardai = 'Eugenijus,Henrikas,Arvilas,Arvil&#0279;,Anakletas,Anys'; }
  elsif ($diena == 14)	{ $vardai = 'Kamilas,Vydas,Eigil&#0279;,Libertas'; }
  elsif ($diena == 15)	{ $vardai = 'Bonavent&#0363;ras,Mantas,Gerimant&#0279;,Henrikas,Rozalija,Ro&#0380;&#0279;'; }
  elsif ($diena == 16)	{ $vardai = 'Vaigaudas,Danguol&#0279;,Faustas,Marija'; }
  elsif ($diena == 17)	{ $vardai = 'Aleksas,Magdalena,Darius,Gir&#0279;nas,Vaiga'; }
  elsif ($diena == 18)	{ $vardai = 'Arnoldas,Fridrikas,Tautvilas,Eimant&#0279;,Kamilis,Ervinas'; }
  elsif ($diena == 19)	{ $vardai = 'Aur&#0279;ja,Galigantas,Mantigail&#0279;,Vincentas,Auks&#0279;,Vincas'; }
  elsif ($diena == 20)	{ $vardai = 'Aurelijus,&#0268;eslovas,Elijas,Alvydas,Vismant&#0279;,Jeronimas'; }
  elsif ($diena == 21)	{ $vardai = 'Laurynas,Lionginas,Rimvydas,Rimvyd&#0279;,Danielius'; }
  elsif ($diena == 22)	{ $vardai = 'Magdalena,Dalius,Mantil&#0279;'; }
  elsif ($diena == 23)	{ $vardai = 'Apolinaras,Romula,Tarvilas,Gilmina,Brigita,Roma'; }
  elsif ($diena == 24)	{ $vardai = 'Kristina,Kristoforas,Kunigunda,Dargvilas,Dargvil&#0279;,Kristupas'; }
  elsif ($diena == 25)	{ $vardai = 'Jok&#0363;bas,Kargaudas,Au&#0154;rin&#0279;,Kristoforas,Kristupas'; }
  elsif ($diena == 26)	{ $vardai = 'Joakimas,Ona,Daugintas,Eigird&#0279;,Jokimas'; }
  elsif ($diena == 27)	{ $vardai = 'Natalija,Panteleonas,&#0142;intautas,Svalia,Sergijus'; }
  elsif ($diena == 28)	{ $vardai = 'Ada,Inocentas,Nazarijus,Vytaras,Augmina,Nazaras,Vytas'; }
  elsif ($diena == 29)	{ $vardai = 'Beatri&#0269;&#0279;,Faustinas,Feliksas,Morta,Simplicijus,Mantvydas,Mantvyd&#0279;,Laimis'; }
  elsif ($diena == 30)	{ $vardai = 'Abdonas,Nortautas,Radvil&#0279;,Donatil&#0279;'; }
  elsif ($diena == 31)	{ $vardai = 'Elena,Ignacas,Sanginas,Vykint&#0279;,Ignotas'; }
 }
 elsif ($menuo == 8) {
  if    ($diena == 1)	{ $vardai = 'Alfonsas,Bartautas,Bartaut&#0279;,Almeda'; }
  elsif ($diena == 2)	{ $vardai = 'Euzebijus,Steponas,Tautvilas,Guoda,Gustavas,Alfonsas'; }
  elsif ($diena == 3)	{ $vardai = 'Lidija,Mangirdas,Lengvin&#0279;,Steponas,August&#0279;'; }
  elsif ($diena == 4)	{ $vardai = 'Gerimantas,Milged&#0279;,Dominykas'; }
  elsif ($diena == 5)	{ $vardai = 'Felicisimas,Nona,Rimtas,Mintar&#0279;,Osvaldas,Vilija'; }
  elsif ($diena == 6)	{ $vardai = 'Bylotas,Daiva'; }
  elsif ($diena == 7)	{ $vardai = 'Donatas,Kajetonas,Sikstas,Dr&#0261;sutis,Jogail&#0279;,Klaudija,Jogil&#0279;'; }
  elsif ($diena == 8)	{ $vardai = 'Dominykas,Tulgirdas,Daina,Elidijus,Gustavas'; }
  elsif ($diena == 9)	{ $vardai = 'Romanas,Mintaras,Tarvil&#0279;,Rolandas,Romas'; }
  elsif ($diena == 10)	{ $vardai = 'Laurynas,Norimantas,Laima,Laurynas,Asterija,Astra'; }
  elsif ($diena == 11)	{ $vardai = 'Filomena,Klara,Severas,Zuzana,Visalgas,Visvil&#0279;,Ligija'; }
  elsif ($diena == 12)	{ $vardai = 'Radegunda,Laimonas,Laimona,Klara,Rad&#0279;'; }
  elsif ($diena == 13)	{ $vardai = 'Kasijonas,Poncijonas,Naglis,Gilvil&#0279;,Ipolitas,Diana'; }
  elsif ($diena == 14)	{ $vardai = 'Euzebijus,Maksimilijonas,Grintautas,Guost&#0279;'; }
  elsif ($diena == 15)	{ $vardai = 'Visvilas,Vyden&#0279;,Napoleonas,Sigita,Napalys,Rugil&#0279;'; }
  elsif ($diena == 16)	{ $vardai = 'Rokas,Steponas,Butvydas,Alvita,Jokimas'; }
  elsif ($diena == 17)	{ $vardai = 'Hiacintas,Jacintas,Saulenis,Ma&#0380;vil&#0279;,Jackus'; }
  elsif ($diena == 18)	{ $vardai = 'Elena,Mantautas,Gendvil&#0279;,Ilona'; }
  elsif ($diena == 19)	{ $vardai = 'Emilija,Argaudas,Tolvina,Boleslovas,Balys'; }
  elsif ($diena == 20)	{ $vardai = 'Bernardas,Tolvinas,Neringa'; }
  elsif ($diena == 21)	{ $vardai = 'Linda,Pijus,Gaudvydas,Joana,Kazimiera,Medein&#0279;'; }
  elsif ($diena == 22)	{ $vardai = 'Karijotas,Rimant&#0279;,Ipolitas,Zygfridas'; }
  elsif ($diena == 23)	{ $vardai = 'Pilypas,Ro&#0380;&#0279;,Girmantas,Tautgail&#0279;'; }
  elsif ($diena == 24)	{ $vardai = 'Baltramiejus,Michalina,Vie&#0353;vilas,Rasuol&#0279;,Alicija,Baltrus,Mykol&#0279;'; }
  elsif ($diena == 25)	{ $vardai = 'Juozapas,Liudvikas,Patricija,Mangailas,Mangail&#0279;,Liucil&#0279;,Liudas'; }
  elsif ($diena == 26)	{ $vardai = 'Kazimieras,Zefirinas,Gailius,Algint&#0279;,Aleksandras,Gailutis'; }
  elsif ($diena == 27)	{ $vardai = 'Monika,Tolvydas,Au&#0353;rin&#0279;,Cezarijus'; }
  elsif ($diena == 28)	{ $vardai = 'Augustina,Tarvilas,Steigvil&#0279;'; }
  elsif ($diena == 29)	{ $vardai = 'Adolfas,Sabina,Barvydas,Gaudvyd&#0279;,Beatri&#0269;&#0279;'; }
  elsif ($diena == 30)	{ $vardai = 'Adel&#0279;,Feliksas,Kintenis,Aug&#0363;na,Adauktas,Gaudencija,Laimis,Joris'; }
  elsif ($diena == 31)	{ $vardai = 'Izabel&#0279;,Raimundas,Raimunda,Vilmantas,Vilmant&#0279;'; }
 }
 elsif ($menuo == 9) {
  if    ($diena == 1)	{ $vardai = 'Egidijus,Verena,Gytautas,Burvil&#0279;,Gytis'; }
  elsif ($diena == 2)	{ $vardai = 'Ingrida,Protenis,Vilgaudas,Steponas,Vilgaud&#0279;'; }
  elsif ($diena == 3)	{ $vardai = 'Berta,Bronislovas,Bronislova,Grigalius,Sirtautas,Mirga,Bronislava'; }
  elsif ($diena == 4)	{ $vardai = 'Ida,Rozalija,Girstautas,Germant&#0279;,Ro&#0380;&#0279;'; }
  elsif ($diena == 5)	{ $vardai = 'Laurynas,Erdenis,Dingail&#0279;,Justina,Stanislava,Stas&#0279;'; }
  elsif ($diena == 6)	{ $vardai = 'Beata,Faustas,Vai&#0353;tautas,Tauten&#0279;'; }
  elsif ($diena == 7)	{ $vardai = 'Klodoaldas,Pulcherija,Regina,Bartas,Bart&#0279;,Palmira,Klodas'; }
  elsif ($diena == 8)	{ $vardai = 'Adrijonas,Marija,Liaugaudas,Daumant&#0279;,Klementina'; }
  elsif ($diena == 9)	{ $vardai = 'Serapina,Sergijus,Argintas,Ramut&#0279;,Sonata'; }
  elsif ($diena == 10)	{ $vardai = 'Dionyzas,Konstancija,Mikalojus,Salvijus,Tautgirdas,Girmint&#0279;,Kost&#0279;'; }
  elsif ($diena == 11)	{ $vardai = 'Hiacintas,Jacintas,Augantas,Gytaut&#0279;,Helga,Jackus,Gyt&#0279;'; }
  elsif ($diena == 12)	{ $vardai = 'Gvidas,Marija,Tolvaldas,Vaidmant&#0279;'; }
  elsif ($diena == 13)	{ $vardai = 'Barmantas,Barvyd&#0279;'; }
  elsif ($diena == 14)	{ $vardai = 'Sanita,Sanija,Santa,Eisvinas,Eisvina,Krescencija,Krescencijus'; }
  elsif ($diena == 15)	{ $vardai = 'Eugenija,Rolandas,Vismantas,Rimgail&#0279;,Nikodemas'; }
  elsif ($diena == 16)	{ $vardai = 'Eufemija,Kiprijonas,Kornelijus,Liudmila,Rimgaudas,Jogint&#0279;,Kamil&#0279;,Edita,Kipras'; }
  elsif ($diena == 17)	{ $vardai = 'Robertas,Sintautas,Sintaut&#0279;,Pranci&#0353;kus,Pranas'; }
  elsif ($diena == 18)	{ $vardai = 'Juozapas,Stanislovas,Mingailas,Galmant&#0279;,Stefanija,Stefa'; }
  elsif ($diena == 19)	{ $vardai = 'Arnulfas,Januarijus,Girvinas,Vyt&#0279;,Vilhelmina,Vil&#0279;'; }
  elsif ($diena == 20)	{ $vardai = 'Fausta,Kolumba,Vainoras,Tautgird&#0279;,Eustachijus,Vainora'; }
  elsif ($diena == 21)	{ $vardai = 'Matas,Mantvilas,Viskint&#0279;'; }
  elsif ($diena == 22)	{ $vardai = 'Mauricijus,Tomas,Tarvinas,Virmant&#0279;'; }
  elsif ($diena == 23)	{ $vardai = 'Linas,Tekl&#0279;,Galintas,Galint&#0279;,Lina,Lin&#0279;'; }
  elsif ($diena == 24)	{ $vardai = 'Gerardas,Gedvinas,Gedvin&#0279;'; }
  elsif ($diena == 25)	{ $vardai = 'Kleopas,Vladislovas,Vaigintas,Ramvyd&#0279;,Aurelija'; }
  elsif ($diena == 26)	{ $vardai = 'Damijonas,Vydenis,Gra&#0380;ina,Kipras,Justina,Just&#0279;'; }
  elsif ($diena == 27)	{ $vardai = 'Vincentas,Kovaldas,Daugil&#0279;,Damijonas,Adalbertas'; }
  elsif ($diena == 28)	{ $vardai = 'Svetlana,Lana,Vaclovas,Tautvydas,Vientaut&#0279;,Saliamonas,Vacys'; }
  elsif ($diena == 29)	{ $vardai = 'Gabrielius,Mykolas,Rapolas,K&#0281;sgailas,K&#0281;sgail&#0279;,Michalina,Mykol&#0279;'; }
  elsif ($diena == 30)	{ $vardai = 'Jeronimas,Sofija,&#0381;ymantas,Bytaut&#0279;,Zofija'; }
 }
 elsif ($menuo == 10) {
  if    ($diena == 1)	{ $vardai = 'Emanuelis,Remigijus,Teres&#0279;,Mantas,Mint&#0279;,Benigna'; }
  elsif ($diena == 2)	{ $vardai = 'Modestas,Eidvilas,Getaut&#0279;'; }
  elsif ($diena == 3)	{ $vardai = 'Evaldas,Kristina,Milgintas,Alanta,Teres&#0279;'; }
  elsif ($diena == 4)	{ $vardai = 'Pranci&#0353;kus,M&#0261;stautas,Eivyd&#0279;,Pranas'; }
  elsif ($diena == 5)	{ $vardai = 'Edvinas,Gal&#0279;,Placidas,Palemonas,Gilda,Donata'; }
  elsif ($diena == 6)	{ $vardai = 'Brunonas,Budvydas,Vyten&#0279;'; }
  elsif ($diena == 7)	{ $vardai = 'Morkus,Renatas,Butrimas,Eivina,Justina'; }
  elsif ($diena == 8)	{ $vardai = 'Benedikta,Marcelis,Sergijus,Daugas,Gaivil&#0279;,Brigita,Demetras,Aina'; }
  elsif ($diena == 9)	{ $vardai = 'Liudvikas,Ged&#0279;tas,Virgail&#0279;,Dionyzas,Liudas'; }
  elsif ($diena == 10)	{ $vardai = 'Danielius,Pranci&#0353;kus,Gilvydas,Butaut&#0279;,Danys'; }
  elsif ($diena == 11)	{ $vardai = 'Germanas,Rimgaudas,Daugvyd&#0279;,Zinaida,Zina'; }
  elsif ($diena == 12)	{ $vardai = 'Rudolfas,Serapinas,Gantas,Deimint&#0279;,Salvinas'; }
  elsif ($diena == 13)	{ $vardai = 'Eduardas,Mintaras,Nortautas,Venancijus,Edvardas,Nortaut&#0279;,Edgaras'; }
  elsif ($diena == 14)	{ $vardai = 'Kalikstas,Vincentas,Mindaugas,Rimvyd&#0279;,Fortunata'; }
  elsif ($diena == 15)	{ $vardai = 'Teres&#0279;,Galimintas,Domant&#0279;,Leonardas'; }
  elsif ($diena == 16)	{ $vardai = 'Aurelija,Galius,Jadvyga,Margarita,Gutautas,Dovald&#0279;,Ambraziejus,Dovaidas,Dovaid&#0279;,Greta,Gret&#0279;'; }
  elsif ($diena == 17)	{ $vardai = 'Ignacas,Kintautas,Gyt&#0279;,Marijonas,Margarita,Ignotas'; }
  elsif ($diena == 18)	{ $vardai = 'Lukas,Liubartas,K&#0281;smina,Vaiva'; }
  elsif ($diena == 19)	{ $vardai = 'Akvilinas,Izaokas,Paulius,Geisvilas,Kantrim&#0279;,Kleopatra,Laura,Povilas'; }
  elsif ($diena == 20)	{ $vardai = 'Irena,Gedas,Deimina,Adelina,Adel&#0279;'; }
  elsif ($diena == 21)	{ $vardai = 'Ur&#0353;ul&#0279;,Raitvilas,Gilanda,Hiliaras,Vilma'; }
  elsif ($diena == 22)	{ $vardai = 'Donatas,Malvina,Severinas,Viltaras,Minged&#0279;,Aliodija,Severas'; }
  elsif ($diena == 23)	{ $vardai = 'Sanginas,Ramvyd&#0279;,Odilija'; }
  elsif ($diena == 24)	{ $vardai = 'Antanas,Daugailas,&#0352;vitrigail&#0279;,Rapolas,Gilbertas'; }
  elsif ($diena == 25)	{ $vardai = 'Krizantas,&#0352;vitrigaila,Vaiged&#0279;,Darija,Inga,Krizas'; }
  elsif ($diena == 26)	{ $vardai = 'Liudginas,Mingint&#0279;,Evaristas,Liaudginas,Vita'; }
  elsif ($diena == 27)	{ $vardai = 'Ramojus,Tautmil&#0279;,Vincentas,Sabina,Vincas'; }
  elsif ($diena == 28)	{ $vardai = 'Judas,Tadas,Simonas,Almant&#0279;,Gaudrimas,Simas'; }
  elsif ($diena == 29)	{ $vardai = 'Ermelinda,Gelgaudas,Tolvyd&#0279;,Violeta,Narcizas'; }
  elsif ($diena == 30)	{ $vardai = 'Alfonsas,Liucil&#0279;,Volfgangas,Skirgaila,Skirvyd&#0279;,Edmundas,Darata,Volfas'; }
  elsif ($diena == 31)	{ $vardai = 'Benignas,M&#0261;stvilas,Tanvil&#0279;,Alfonsas,Liucil&#0279;'; }
 }
 elsif ($menuo == 11) {
  if    ($diena == 1)	{ $vardai = '&#0381;ygaudas,Milvyd&#0279;,Andrius'; }
  elsif ($diena == 2)	{ $vardai = 'Gedartas,Gedil&#0279;,Valentas,Valys'; }
  elsif ($diena == 3)	{ $vardai = 'Hubertas,Martynas,Silvija,Vydmantas,Norvain&#0279;'; }
  elsif ($diena == 4)	{ $vardai = 'Agrikola,Karolis,Modesta,Vitalis,Eibartas,Vaidmina,Vitalijus,Vitalius'; }
  elsif ($diena == 5)	{ $vardai = 'El&#0380;bieta,Zacharijas,Audangas,Gedvyd&#0279;,Florijonas,Elz&#0279;'; }
  elsif ($diena == 6)	{ $vardai = 'Leonardas,Melanijus,A&#0353;mantas,Vygaud&#0279;,Armantas'; }
  elsif ($diena == 7)	{ $vardai = 'Ernestas,Rufas,Sirtautas,Gotaut&#0279;,Karina'; }
  elsif ($diena == 8)	{ $vardai = 'Severijonas,Viktorinas,Svirbutas,Domant&#0279;,Gotfridas,Severinas'; }
  elsif ($diena == 9)	{ $vardai = 'Aurelijus,Paulina,Dargintas,Skirtaut&#0279;,Teodoras,Estela'; }
  elsif ($diena == 10)	{ $vardai = 'Andriejus,Leonas,Vai&#0353;viltas,Gelvyd&#0279;,Andrius,Evelina'; }
  elsif ($diena == 11)	{ $vardai = 'Martynas,Vygintas,Milvyd&#0279;,Anastazija,Nast&#0279;'; }
  elsif ($diena == 12)	{ $vardai = 'Juozapotas,Teodoras,A&#0353;mantas,Alvil&#0279;,Kristina,Renata,Kristinas'; }
  elsif ($diena == 13)	{ $vardai = 'Norvydas,Eirim&#0279;,Arkadijus'; }
  elsif ($diena == 14)	{ $vardai = 'Gotfridas,Ramantas,Saulen&#0279;,Emilis,Judita'; }
  elsif ($diena == 15)	{ $vardai = 'Albertas,Leopoldas,Vaidilas,&#0381;advyd&#0279;'; }
  elsif ($diena == 16)	{ $vardai = 'Edmundas,Gertr&#0363;da,Margarita,Vai&#0353;vydas,Gerdvil&#0279;'; }
  elsif ($diena == 17)	{ $vardai = 'Dionyzas,El&#0380;bieta,Grigalius,Getautas,Gilvil&#0279;,Viktorija'; }
  elsif ($diena == 18)	{ $vardai = 'Salom&#0279;ja,Ginvydas,Ginvyd&#0279;,Otonas,Romanas,Otas'; }
  elsif ($diena == 19)	{ $vardai = 'Matilda,Dainotas,Rimgaud&#0279;,Dainius'; }
  elsif ($diena == 20)	{ $vardai = 'Feliksas,Jovydas,Vaidvil&#0279;,Laimis'; }
  elsif ($diena == 21)	{ $vardai = 'Gomantas,Eibart&#0279;,Honorijus,Alberta,Norgaudas,Giren&#0279;,Honoratas,Tomas'; }
  elsif ($diena == 22)	{ $vardai = 'Cecilija,Cil&#0279;,Steigintas,Dargint&#0279;'; }
  elsif ($diena == 23)	{ $vardai = 'Felicita,Klemensas,Kolumbanas,Doviltas,Liubart&#0279;,Adel&#0279;,Kolumbas,Orestas'; }
  elsif ($diena == 24)	{ $vardai = 'Mantvinas,&#0381;ybart&#0279;,Gerardas'; }
  elsif ($diena == 25)	{ $vardai = 'Kotryna,Santautas,Germil&#0279;'; }
  elsif ($diena == 26)	{ $vardai = 'Leonardas,Dobilas,Vygint&#0279;,Silvestras,Vygant&#0279;'; }
  elsif ($diena == 27)	{ $vardai = 'Maksimas,Virgilijus,Skomantas,Girdvyd&#0279;,Virgis,Girvyd&#0279;'; }
  elsif ($diena == 28)	{ $vardai = 'Jok&#0363;bas,Steponas,Rimgaudas,Vakar&#0279;,Rufas'; }
  elsif ($diena == 29)	{ $vardai = 'Saturninas,Daujotas,Butvyd&#0279;,Saturnas'; }
  elsif ($diena == 30)	{ $vardai = 'Andriejus,Saugardas,Dovain&#0279;,Andrius'; }
 }
 elsif ($menuo == 12) {
  if    ($diena == 1)	{ $vardai = 'Aleksandras,Eligijus,Natalija,Butigeidas,Algmina'; }
  elsif ($diena == 2)	{ $vardai = 'Liucijus,Svirgailas,Milmant&#0279;,Aurelija,Paulina'; }
  elsif ($diena == 3)	{ $vardai = 'Pranci&#0353;kus,Gailintas,Audinga,Ksaveras'; }
  elsif ($diena == 4)	{ $vardai = 'Barbora,Osmundas,Vainotas,Liugail&#0279;'; }
  elsif ($diena == 5)	{ $vardai = 'Eimintas,Geisvil&#0279;,Gratas,Gracija'; }
  elsif ($diena == 6)	{ $vardai = 'Mikalojus,Bilmantas,Norvyd&#0279;'; }
  elsif ($diena == 7)	{ $vardai = 'Ambraziejus,Daugardas,Taut&#0279;,Jekaterina'; }
  elsif ($diena == 8)	{ $vardai = 'Zenonas,Vaidginas,Gedmint&#0279;,Guntilda'; }
  elsif ($diena == 9)	{ $vardai = 'Delfina,Leokadija,Vakaris,Geden&#0279;,Valerija'; }
  elsif ($diena == 10)	{ $vardai = 'Eidimtas,Ilma,Eularija,Loreta'; }
  elsif ($diena == 11)	{ $vardai = 'Art&#0363;ras,Aistis,Tautvald&#0279;,Dovydas'; }
  elsif ($diena == 12)	{ $vardai = 'Joana,&#0381;aneta,Gilmintas,Vainged&#0279;,Dagmara,&#0381;ana'; }
  elsif ($diena == 13)	{ $vardai = 'Liucija,Odilija,Kastautas,Eivilt&#0279;,Otilija,Kastytis'; }
  elsif ($diena == 14)	{ $vardai = 'Alfredas,Fortunatas,Tarvainas,Kintvil&#0279;'; }
  elsif ($diena == 15)	{ $vardai = 'Justas,Kristijonas,Kristijona,Nina,Ona,Gaudenis,Gauden&#0279;'; }
  elsif ($diena == 16)	{ $vardai = 'Albina,Vygaudas,Audron&#0279;,Algina,Alina,Adas'; }
  elsif ($diena == 17)	{ $vardai = 'Olimpija,Mantgailas,Drovyd&#0279;,Jolanta'; }
  elsif ($diena == 18)	{ $vardai = 'Gracijonas,Girdvilas,Eivil&#0279;,Gracijus'; }
  elsif ($diena == 19)	{ $vardai = 'Rufas,Urbonas,Gerdvilas,Rimant&#0279;,Darijus'; }
  elsif ($diena == 20)	{ $vardai = 'Dominykas,Daugardas,Gra&#0380;vil&#0279;,Teofilis'; }
  elsif ($diena == 21)	{ $vardai = 'Norgaud&#0279;,Giren&#0279;,Tomas'; }
  elsif ($diena == 22)	{ $vardai = 'Rimbertas,Gedvydas,Dovil&#0279;,Zenonas,Ksavera'; }
  elsif ($diena == 23)	{ $vardai = 'Viktorija,Mina,Vilbutas,Veliuona'; }
  elsif ($diena == 24)	{ $vardai = 'Adel&#0279;,Adomas,Ieva,Irmina,Girstautas,Minvyd&#0279;,Irma'; }
  elsif ($diena == 25)	{ $vardai = 'Anastazija,Gra&#0380;vydas,Sanrim&#0279;,Eugenija,Nast&#0279;,Gen&#0279;'; }
  elsif ($diena == 26)	{ $vardai = 'Steponas,Gaudil&#0279;,Gindvil&#0279;,Gaudvilas'; }
  elsif ($diena == 27)	{ $vardai = 'Dautartas,Gedvin&#0279;,Fabijol&#0279;'; }
  elsif ($diena == 28)	{ $vardai = 'Inga,Ivita,Irvita,Ingeborga,Kantvilas,Vaidilut&#0279;,Ema,Kamil&#0279;'; }
  elsif ($diena == 29)	{ $vardai = 'Tomas,Gentvainas,Gaja,Teofil&#0279;'; }
  elsif ($diena == 30)	{ $vardai = 'Margarita,Sabinas,Sabina,Gra&#0380;vilas,Dovydas,Irmina'; }
  elsif ($diena == 31)	{ $vardai = 'Melanija,Silvestras,Gedgantas,Mingail&#0279;'; }
 }
 else { return 0; }

 return (duomenu_isvedimas($vardai,$koduote));
}

sub zodiakas {
 my ($metai,$menuo,$diena,$koduote) = tikrinimas($_[1],$_[2]);

 my $zodiakas;
 my $data = "$menuo.$diena";
 if    ($data =~ /^((12.2[2-9])|(12.3[0,1])|(1.[1-9])|(1.1[0-9])|(1.20))$/) { $zodiakas = 'O&#0380;iaragis'; } # 12.22-01.20
 elsif ($data =~ /^((1.2[1-9])|(1.3[0,1])|(2.[1-9])|(2.1[0-9]))$/){ $zodiakas = 'Vandenis'; } # 01.21-02.19
 elsif ($data =~ /^((2.2[0-9])|(3.[1-9])|(3.20))$/) { $zodiakas = '&#0381;uvis'; } # 02.20-03.20
 elsif ($data =~ /^((3.2[1-9])|(3.[0,1])|(4.[1-9])|(4.1[0-9])|(4.20))$/) { $zodiakas = 'Avinas'; } # 03.21-04.20
 elsif ($data =~ /^((4.2[1-9])|(4.30)|(5.[1-9])|(5.1[0-9])|(5.2[0-2]))$/) { $zodiakas = 'Jautis'; } # 04.21-05.22
 elsif ($data =~ /^((5.2[3-9])|(5.3[0,1])|(6.[1-9])|(5.1[0-9])|(5.2[0,1]))$/) { $zodiakas = 'Dvynys'; } # 05.23-06.21
 elsif ($data =~ /^((6.2[2-9])|(6.30)|(7.[1-9])|(7.1[0-9])|(7.2[0-2]))$/) { $zodiakas = 'V&#0279;&#0380;ys'; } # 06.22-07.22
 elsif ($data =~ /^((7.2[3-9])|(7.3[0,1])|(8.[1-9])|(8.1[0-9])|(8.2[0-2]))$/) { $zodiakas = 'Li&#0363;tas'; } # 07.23-08.22
 elsif ($data =~ /^((8.2[3-9])|(8.3[0,1])|(9.[1-9])|(9.1[0-9])|(9.2[0-2]))$/) { $zodiakas = 'Mergel&#0279;'; } # 08.23-09.22
 elsif ($data =~ /^((9.2[3-9])|(9.30)|(10.[1-9])|(10.1[0-9])|(10.2[0-2]))$/) { $zodiakas = 'Svarstykl&#0279;s'; } # 09.23-10.22
 elsif ($data =~ /^((10.2[3-9])|(10.3[0,1])|(11.[1-9])|(11.1[0-9])|(11.2[0-2]))$/) { $zodiakas = 'Skorpionas'; } # 10.23-11.22
 elsif ($data =~ /^((11.2[3-9])|(11.30)|(12.[1-9])|(12.1[0-9])|(12.2[0-2]))$/) { $zodiakas = '&#0352;aulys'; } # 11.23-12.22
 elsif ($data =~ /^((12.2[2-9])|(12.3[0,1])|(1.[1-9])|(1.1[0-9])|(1.20))$/) { $zodiakas = 'O&#0380;iaragis'; } # 12.22-01.20

 return (duomenu_isvedimas($zodiakas,$koduote));
}

sub metu_laikas {
 my ($metai,$menuo,$diena,$koduote) = tikrinimas($_[1],$_[2]);

 my $metu_laikas;
 if    ($menuo =~ /^(12|1|2)$/) { $metu_laikas = '&#0381;iema'; }
 elsif ($menuo =~ /^(3|4|5)$/) { $metu_laikas = 'Pavasaris'; }
 elsif ($menuo =~ /^(6|7|8)$/) { $metu_laikas = 'Vasara'; }
 elsif ($menuo =~ /^(9|10|11)$/) { $metu_laikas = 'Ruduo'; }

 return (duomenu_isvedimas($metu_laikas,$koduote));
}

sub menuo {
 my ($metai,$menuo,$diena,$koduote) = tikrinimas($_[1],$_[2]);

 my $men_pav;
 if    ($menuo == 1)  { $men_pav = 'Sausis'; }
 elsif ($menuo == 2)  { $men_pav = 'Vasaris'; }
 elsif ($menuo == 3)  { $men_pav = 'Kovas'; }
 elsif ($menuo == 4)  { $men_pav = 'Balandis'; }
 elsif ($menuo == 5)  { $men_pav = 'Gegu&#0380;&#0279;'; }
 elsif ($menuo == 6)  { $men_pav = 'Bir&#0380;elis'; }
 elsif ($menuo == 7)  { $men_pav = 'Liepa'; }
 elsif ($menuo == 8)  { $men_pav = 'Rugpj&#0363;tis'; }
 elsif ($menuo == 9)  { $men_pav = 'Rugs&#0279;jis'; }
 elsif ($menuo == 10) { $men_pav = 'Spalis'; }
 elsif ($menuo == 11) { $men_pav = 'Lapkritis'; }
 elsif ($menuo == 12) { $men_pav = 'Gruodis'; }
 
 return (duomenu_isvedimas($men_pav,$koduote));
}

sub diena {
 my ($metai,$menuo,$diena,$koduote) = tikrinimas($_[1],$_[2]);
 my %m=(1,0,2,3,3,2,4,5,5,0,6,3,7,5,8,1,9,4,10,6,11,2,12,4,);
 my $MDS = (($diena+$m{$menuo}+$metai+(int($metai/4))-(int($metai/100))+(int($metai/400)))%7);
 my $dien_pav;
 if ($MDS == 1) { $dien_pav = 'Pirmadienis'; }
 elsif ($MDS == 2) { $dien_pav = 'Antradienis'; }
 elsif ($MDS == 3) { $dien_pav = 'Tre&#0269;iadienis'; }
 elsif ($MDS == 4) { $dien_pav = 'Ketvirtadienis'; }
 elsif ($MDS == 5) { $dien_pav = 'Penktadienis'; }
 elsif ($MDS == 6) { $dien_pav = '&#0352;e&#0353;tadienis'; }
 elsif ($MDS == 0) { $dien_pav = 'Sekmadienis'; }

 return (duomenu_isvedimas($dien_pav,$koduote));
}

sub tikrinimas {
 my ($data,$koduote) = @_;
 my ($metai,$menuo,$diena) = split(/\./,$data);
 $menuo =~ s/^0//;
 $diena =~ s/^0//;

 return 0 unless (
 (($menuo == 1) && ($diena < 32)) || # 1.31
 (($menuo == 2) && ((($metai/4) =~ /^\d+\.\d+$/) && ($diena < 29))) || (((($metai/4) =~ /^\d+$/) && ($diena < 30))) || # 2.28, o kas 4 metus ("keliamieji metai") 2.29
 (($menuo == 3) && ($diena < 32)) || # 3.31
 (($menuo == 4) && ($diena < 31)) || # 4.30
 (($menuo == 5) && ($diena < 32)) || # 5.31
 (($menuo == 6) && ($diena < 31)) || # 6.30
 (($menuo == 7) && ($diena < 32)) || # 7.31
 (($menuo == 8) && ($diena < 32)) || # 8.31
 (($menuo == 9) && ($diena < 31)) || # 9.30
 (($menuo == 10) && ($diena < 32)) || # 10.31
 (($menuo == 11) && ($diena < 31)) || # 11.30
 (($menuo == 12) && ($diena < 32))); # 12.31

 return ($metai,$menuo,$diena,$koduote);
}

sub duomenu_isvedimas {
 my ($eilute,$koduote) = @_;
 $koduote = 'utf-8' unless 'www';
 if ($koduote eq 'utf-8') { $eilute =~ s/&#(\d{4});/pack('U',$1)/eg; }
 return $eilute;
}

1;
