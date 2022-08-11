#!/usr/bin/env perl
# Copyright (C) 2012-2022  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::CharacterSheetGenerator::DwarfName - return a dwarf name

=head1 SYNOPSIS

    use Game::CharacterSheetGenerator::DwarfName qw(dwarf_name);
    # returns both $name and $gender (F, M, or ?)
    my ($name, $gender) = dwarf_name();
    # returns the same name and its gender
    ($name, $gender) = dwarf_name("Alex");

=head1 DESCRIPTION

This package has one function that returns a dwarf name and a gender. The gender
returned is "M", "F", or "?".

If a name is provided, the gender is returned.

=cut

package Game::CharacterSheetGenerator::DwarfNames;
use Modern::Perl;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dwarf_name);

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

# https://dwarrowscholar.wordpress.com/general-documents/male-dwarf-outer-names/
# https://dwarrowscholar.wordpress.com/general-documents/female-dwarf-outer-names/

my @names = qw{Aín M Áiskjald M Áispori M Áithrasir M Áivari M Ajar M Áki M
Albin M Alekin M Alf M Alfar M Alfi M Alfin M Alfskjald M Alfthrasir M Alfvari M
Althar M Althi M Althin M Althjof M Althskjald M Althspori M Alththrasir M
Althvari M Álvfinnur M Álvhethin M Alvi M Álvur M Ámundur M Anar M Andar M Andi
M Andin M Andri M Andskjald M Andspori M Andthrasir M Andvari M Ani M Anin M
Anskjald M Anspori M Anthrasir M Anvari M Ari M Ári M Aritur M Arnaldur M
Arnfinnur M Arnfríthur M Arngrímur M Arni M Árni M Arnlígur M Arnljótur M
Arnoddur M Arvinur M Ásbergur M Ásbrandur M Ásfinnur M Ásgrímur M Ási M Askur M
Áslakur M Ásleivur M Ásmóthur M Ásmundur M Ásvaldur M Ásvarthur M Atli M Aurar M
Auri M Aurin M Aurskjald M Aurspori M Aurthrasir M Aurvang M Aurvari M Austar M
Austi M Austin M Austri M Austskjald M Austspori M Austvari M Ávaldur M Balar M
Baldur M Baldvin M Bali M Balin M Bálli M Balskjald M Balspori M Balthrasir M
Balvari M Baraldur M Báraldur M Barinur M Bárivin M Bárthur M Bávurin M Beini M
Benrin M Bergfinnur M Bergfríthur M Bergleivur M Bergur M Bersi M Bessi M Bifar
M Bifi M Bifin M Bifskjald M Bifspori M Bifur M Bifvari M Bilar M Bilbur M Bildr
M Bili M Bilin M Billar M Billi M Billin M Billing M Billskjald M Billspori M
Billthrasir M Bilskjald M Bilthrasir M Bilvari M Birni M Bjarki M Bjarngrímur M
Bjarnhethin M Bjarni M Bjarnvarthur M Bjarti M Bjartur M Bjórgfinnur M
Bjórghethin M Bjórgolvur M Bjórgúlvur M Bofar M Bofi M Bofin M Bofskjald M
Bofspori M Bofthrasir M Bofur M Bofvari M Bogi M Bombar M Bombi M Bombin M
Bombskjald M Bombspori M Bombthrasir M Bombur M Bombvari M Bótolvur M Bragi M
Bráli M Brandur M Brávur M Bresti M Brialdur M Broddi M Broddur M Bróin M Bróri
M Brosi M Brunar M Bruni M Brunin M Brunskjald M Brunspori M Brunthrasir M Brúsi
M Brynjolvur M Brynleivur M Búgvi M Búi M Burar M Buri M Burin M Burinur M Bursi
M Burskjald M Burspori M Burthrasir M Dagbjartur M Dagfinnur M Dagur M Dáin M
Dár M Daskjald M Dávi M Dávur M Díthrikur M Ditleivur M Djóni M Dolgar M Dolgi M
Dolgin M Dolgskjald M Dolgspori M Dolgthrasir M Dolgvari M Dorar M Dori M Dorin
M Dorskjald M Dorspori M Dorthrasir M Dorvari M Draupar M Draupi M Draupin M
Draupnir M Draupskjald M Draupspori M Draupthrasir M Draupvari M Dróin M Drúinur
M Duf M Dufar M Dufi M Dufin M Dufskjald M Dufthrasir M Dufvari M Dunaldur M
Durar M Duri M Durinar M Durskjald M Durspori M Durthrasir M Durvari M Dwali M
Dwalin M Dwalskjald M Dwalspori M Dwalthrasir M Dwalur M Dwalvari M Dwárli M
Ebbi M Edmundur M Edvin M Egi M Egin M Eikar M Eiki M Eikin M Eikinskjaldi M
Eikskjald M Eikspori M Eikthrasir M Eikvari M Eilívur M Eindri M Eiri M Eirikur
M Eivindur M Eli M Ellindur M Enokur M Erlendur M Erlingur M Esmundur M Filar M
Fili M Filin M Filskjald M Filspori M Filthrasir M Filvari M Finn M Finnar M
Finnbogi M Finnfríthi M Finni M Finnin M Finnleivur M Finnskjald M Finnspori M
Finnur M Finnvari M Fjalar M Fjali M Fjalin M Fjalskjald M Fjalspori M
Fjalthrasir M Fjalvari M Fláim M Fláimingur M Flemmingur M Flói M Flóki M Flosi
M Flóvin M Fraeg M Fráin M Frar M Frár M Frarar M Frari M Frarin M Frarskjald M
Frarspori M Frarthrasir M Fraspori M Frathrasir M Fravari M Fridleivur M
Fríthálvur M Fríthbjartur M Fríthfinnur M Fríthi M Fríthmundur M Frítholvur M
Fríthrikur M Fríthur M Frostar M Frosti M Frostin M Frostskjald M Frostspori M
Frostthrasir M Frostvari M Fróthi M Fulla M Fundar M Fundi M Fundin M Fundskjald
M Fundspori M Fundthrasir M Fundvari M Ganar M Gani M Ganin M Ganskjald M
Ganthrasir M Geirbrandur M Geirfinnur M Geiri M Geirmundur M Geirolvur M Geirur
M Gestur M Gilli M Ginnar M Ginni M Ginnin M Ginnskjald M Ginnspori M
Ginnthrasir M Ginnvari M Gísli M Gissur M Gíti M Gloar M Glói M Glóin M Gloínur
M Glólin M Gloskjald M Glospori M Glothrasir M Glovari M Glúmur M Gormundur M
Gormur M Gráim M Greipur M Grímolvur M Grímur M Gripur M Gróim M Grómi M
Gudfinnur M Gudlígur M Gudmundur M Gulakur M Gullbrandur M Gundur M Gunnálvur M
Gunni M Gunnleikur M Gunnleivur M Gunnlígur M Gunnolvur M Gunnvaldur M Gusti M
Guthbjartur M Guthbrandur M Guthlakur M Gutti M Guttormur M Gylvi M Hábarthur M
Hagbarthur M Hallbergur M Hallfríthur M Hallgrímur M Hallmundur M Hallormur M
Hallur M Hallvarthur M Hámundur M Hannar M Hanni M Hannin M Hannskjald M
Hannspori M Hannthrasir M Hannvari M Haraldur M Hárikur M Haugar M Haugi M
Haugin M Haugskjald M Haugspori M Haugthrasir M Haugvari M Hávarthur M Havgrímur
M Havlithi M Heimurin M Heindrikur M Heini M Heinrikur M Heithrikur M Helgi M
Hemingur M Hemmingur M Hendrikur M Henningur M Heptar M Hepti M Heptin M
Heptskjald M Heptspori M Heptvari M Herálvur M Herbjartur M Herbrandur M
Herfinnur M Herfríthur M Hergrímur M Heri M Herjolvur M Herleivur M Herlígur M
Hermóthur M Hermundur M Herningur M Herolvur M Hervarthur M Hethin M
Hildibjartur M Hildibrandur M Hjalgrímur M Hjalti M Hjórgrímur M Hjórleivur M
Hjórmundur M Hjórtur M Hlear M Hlei M Hlein M Hleskjald M Hlespori M Hlevang M
Hlevari M Hlóin M Hógni M Hor M Hóraldur M Horar M Hori M Hóri M Horin M Hornar
M Hornbori M Horni M Hornin M Hornskjald M Hornthrasir M Horskjald M Horspori M
Horthrasir M Hórthur M Horvari M Hóskuldur M Hugi M Hugin M Húnbogi M Húni M
Ímundur M Ingálvur M Ingi M Ingibjartur M Ingileivur M Ingimundur M Ingivaldur M
Ingjaldur M Ingolvur M Ingvaldur M Ísakur M Ísleivur M Íthálvur M Íthbjartur M
Íthfinnur M Íthgrímur M Íthi M Íthleivur M Íthmundur M Ítholvur M Íthvarthur M
Jallgrímur M Jarar M Jari M Jarin M Jarleivur M Jarmundur M Jarskjald M Jarspori
M Jarthrasir M Jarvari M Jaspur M Jatmundur M Játmundur M Jatvarthur M Jófríthur
M Jónfinnur M Jónhethin M Jóni M Jónleivur M Jórmundur M Jórundur M Justi M
Jústi M Kai M Kálvur M Kári M Karstin M Kartni M Kilar M Kili M Kilin M
Kilskjald M Kilspori M Kilthrasir M Kilvari M Knútur M Kolfinnur M Kolgrímur M
Kolmundur M Koraldur M Kristin M Kristleivur M Kristmundur M Kristoffur M Kyrri
M Lassi M Leiki M Leivur M Levi M Lit M Litar M Liti M Litin M Litskjald M
Litthrasir M Lofar M Lofi M Lofin M Lofskjald M Lofspori M Loftur M Lofvari M
Lonar M Loni M Lonin M Lonskjald M Lonspori M Lonthrasir M Lonvari M Lothin M
Lýthur M Magni M Manni M Marni M Martur M Máur M Mjothar M Mjothi M Mjothin M
Mjothskjald M Mjothspori M Mjoththrasir M Mjothvari M Mjothvitnir M Módsognir M
Motar M Moti M Motin M Motsognir M Motspori M Motvari M Naddoddur M Naglur M
Náin M Nalar M Nali M Náli M Nalin M Nalskjald M Nalspori M Nalthrasir M Nar M
Nár M Narar M Nari M Narin M Narspori M Narthrasir M Narvari M Narvi M Naskjald
M Naspori M Niklái M Nipar M Nipi M Nipin M Niping M Nipskjald M Nipspori M
Nipthrasir M Nipvari M Nithar M Nithi M Nithin M Nithspori M Niththrasir M
Njálur M Nói M Norar M Nori M Norin M Norskjald M Norspori M Northar M Northi M
Northin M Northleivur M Northrasir M Northri M Northskjald M Norththrasir M
Norvari M Nyar M Nyr M Nyrar M Nyrath M Nyri M Nyrin M Nyrspori M Nyrthrasir M
Nyrvari M Nyskjald M Nyspori M Nythrasir M Nyvari M Oddfinnur M Oddfríthur M
Oddleivur M Oddmundur M Oddur M Oddvaldur M Ógmundur M Ógvaldur M Óigrímur M
Óileivur M Óilolvur M Óimundur M Oínur M Óivindur M Óksur M Ólavur M Óli M Ólin
M Olivur M Onar M Oni M Onin M Onskjald M Onthrasir M Onundur M Orar M Ori M
Orin M Órin M Ormur M Órnolvur M Orri M Orskjald M Orspori M Orthrasir M Órvur M
Óssur M Óthin M Ovi M Páitur M Palli M Pátrin M Petrur M Poli M Ragnvaldur M
Rani M Rathsar M Rathsin M Rathskjald M Rathspori M Rathsthrasir M Rathsvari M
Rathsvith M Ravnur M Regar M Regi M Regin M Regskjald M Regspori M Regthrasir M
Regvari M Reinaldur M Ríkaldur M Ríkin M Róaldur M Rodleivur M Rodmundur M
Rógnvaldur M Rógvi M Rói M Róin M Rókur M Róli M Rólvur M Rómundur M Ronni M
Rórin M Rósingur M Róthbjartur M Rótholvur M Rubekur M Rúni M Rúnolvur M
Sáifinnur M Sáimundur M Saksi M Salmundur M Sámur M Sandur M Servin M Sevrin M
Sigbjartur M Sigbrandur M Sigfríthur M Sighvatur M Sigmundur M Signhethin M
Sigvaldur M Sindrinur M Sjúrthi M Sjúrthur M Skafar M Skafi M Skafin M Skafith M
Skafthrasir M Skafvari M Skeggi M Skirfar M Skirfi M Skirfin M Skirfir M
Skirfskjald M Skirfthrasir M Skirfvari M Skofti M Skúvur M Snámiúlvur M Sniolvur
M Snorri M Sólbjartur M Sólfinnur M Sólmundur M Sólvi M Sonni M Sórin M Sórkvi M
Sórli M Sproti M Steinfinnur M Steingrímur M Steinmundur M Steinoddur M
Steinolvur M Steinur M Stígur M Sudri M Summaldur M Summarlithi M Suni M Súni M
Súnmundur M Sunnleivur M Suthar M Suthi M Suthin M Suthri M Suthskjald M
Suthspori M Suththrasir M Suthvari M Sveinungur M Sveinur M Svenningur M Sverri
M Svín M Sviskjald M Svispori M Svithrasir M Sviur M Svivari M Svjar M Teitur M
Terji M Thekk M Thekkar M Thekki M Thekkin M Thekkskjald M Thekkspori M
Thekkvari M Thorar M Thori M Thorin M Thornur M Thorskjald M Thorspori M
Thorthrasir M Thorvari M Thráim M Thráin M Thrárin M Thraskjald M Thraspori M
Thravari M Thrór M Throrar M Throri M Throrin M Throrskjald M Throrspori M
Throrthrasir M Throrvari M Títhrikur M Tjálvi M Tjótholvur M Tóki M Tollakur M
Tonni M Tóraldur M Tórálvur M Tórarin M Torbergur M Torbrandur M Torfinnur M
Torfríthur M Torgestur M Torgrímur M Tórhallur M Tórhethin M Tóri M Torleivur M
Torlígur M Tormóthur M Tormundur M Tóroddur M Tórolvur M Torri M Tórthur M Tórur
M Torvaldur M Tóti M Tráin M Tráli M Trísti M Tróndur M Tróstur M Trygvi M Tyrni
M Týrur M Uggi M Úlvhethin M Úlvur M Uni M Vagnur M Valbergur M Valbrandur M
Valdi M Vermundur M Vestar M Vesti M Vestin M Vestri M Vestskjald M Vestspori M
Vestthrasir M Vestvari M Veturlithi M Vígbaldur M Vígbrandur M Vigg M Viggar M
Viggi M Viggin M Víggrímur M Viggskjald M Viggspori M Viggthrasir M Viggvari M
Vígúlvur M Vilar M Vilbergur M Vilhjálmur M Vili M Vilin M Viljormur M Villi M
Vilmundur M Vilskjald M Vilspori M Vilthrasir M Vilvari M Vinar M Vindalf M Vini
M Vinin M Vinsi M Vinskjald M Vinspori M Vinthrasir M Virfar M Virfi M Virfin M
Virfir M Virfskjald M Virfspori M Virfthrasir M Virfvari M Vistri M Vit M Vóggur
M Vólundur M Vónbjartur M Wali M Yngvi M Ábria F Agda F Aí F Aís F Alda F Aldís
F Alma F Alrún F Álvdís F Ánania F Anís F Anní F Arís F Arna F Árna F Arndís F
Arnina F Arnóra F Arnvór F Ása F Ásbera F Ásdís F Áshild F Ásla F Áslíg F Asta F
Ásta F Ásvór F Ata F Báldís F Bára F Barba F Beinta F Bera F Bergní F Betta F
Bettí F Billa F Bina F Birna F Birta F Bís F Bjalla F Bjarma F Bjarta F Bjólla F
Borgní F Bórka F Brá F Brynja F Bylgja F Dagní F Dagrún F Dagunn F Dái F Dania F
Danvór F Dina F Dinna F Dís F Dógg F Drós F Durís F Durita F Duruta F Ebba F
Edda F Eilin F Eina F Eir F Elsba F Elspa F Elsuba F Embla F Enna F Erla F Erna
F Esta F Ester F Estur F Fanní F Fía F Fípa F Fís F Fjóla F Flykra F Fólva F
Frái F Fróia F Frótha F Geira F Gís F Glóa F Gortra F Gróa F Gudní F Gudvór F
Gunn F Gunna F Gunnvá F Gurli F Gylta F Halda F Havdís F Henní F Hera F Herta F
Hervór F Hildur F Hjalma F Hjordís F Hulda F Ida F Ina F Ingrún F Ingunn F Ingvá
F Ingvór F Inna F Irena F Íth F Ithunn F Íthunn F Íthur F Janna F Jansí F
Járndís F Jensa F Jensia F Jódís F Jóhild F Jónvár F Jórunn F Jovina F Jóvór F
Jústa F Jútta F Kaia F Kamma F Kára F Kárunn F Katla F Lí F Lilja F Lín F Lís F
Lívói F Lóa F Lona F Lovisa F Lula F Lusia F Magga F Malja F Malla F Marí F
Marjun F Marna F Masa F Merrí F Metta F Milja F Mina F Minna F Mira F Myrna F
Nái F Naina F Nanna F Nanní F Nís F Nísi F Nita F Nomi F Oda F Oddní F Oddrún F
Oddvá F Oddvór F Óidís F Óigló F Óilíg F Óivór F Oluffa F Óluva F Píl F Ragna F
Rakul F Randi F Rannvá F Revna F Rikka F Ritva F Ró F Róa F Roda F Róskva F
Rótha F Rún F Rúna F Saldís F Salní F Salvór F Sanna F Sigga F Signa F Signí F
Sigrun F Sigvór F Sissal F Siv F Sól F Sóldís F Sólja F Sólrun F Sólva F Sólvá F
Sólvór F Stina F Suffía F Súna F Sunnvá F Svanna F Sváva F Svelldís F Sví F
Talita F Thrái F Tíra F Tordís F Torní F Tórunn F Torvór F Tóta F Tova F Tóva F
Turith F Ulla F Una F Unn F Unna F Unnur F Urth F Urtha F Vagna F Valdís F Vár F
Várdís F Vígdís F Vinní F Vís F Vísi F Vón F Yngva F Yrsa F};

# This slow setting allows us to find errors.
my %names;
my $last = "";
while (@names) {
  my $key = shift(@names);
  my $val = shift(@names);
  die "$last $key" unless $val =~ /^[FM?]$/;
  $names{$key} = $val;
  $last = $val;
}

sub dwarf_name {
  my $name = shift || one(keys %names);
  my $gender = $names{$name};
  return ($name, $gender);
}

1;
