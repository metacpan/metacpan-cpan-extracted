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

Game::CharacterSheetGenerator::HumanName - return a human name

=head1 SYNOPSIS

    use Game::CharacterSheetGenerator::HumanName qw(human_name);
    # returns both $name and $gender (F, M, or ?)
    my ($name, $gender) = human_name();
    # returns the same name and its gender
    ($name, $gender) = human_name("Alex");

=head1 DESCRIPTION

This package has one function that returns a human name and a gender. The gender
returned is "M", "F", or "?".

If a name is provided, the gender is returned.

=cut

package Game::CharacterSheetGenerator::HumanNames;
use Modern::Perl;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(human_name);

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

# http://www.stadt-zuerich.ch/content/prd/de/index/statistik/publikationsdatenbank/Vornamen-Verzeichnis/VVZ_2012.html

my @names = qw{Aadhya F Aaliyah F Aanya F Aarna F Aarusha F Abiha F Abira F
Abisana F Abishana F Abisheya F Ada F Adalia F Adelheid F Adelia F Adina F Adira
F Adisa F Adisha F Adriana F Adriane F Adrijana F Aela F Afriela F Agata F
Agatha F Aicha F Aikiko F Aiko F Aila F Ainara F Aischa F Aisha F Aissatou F
Aiyana F Aiza F Aji F Ajshe F Akksaraa F Aksha F Akshaya F Alaa F Alaya F Alea F
Aleeya F Alegria F Aleksandra F Alena F Alessandra F Alessia F Alexa F Alexandra
F Aleyda F Aleyna F Alia F Alice F Alicia F Aliena F Alienor F Aliénor F Alija F
Alina F Aline F Alisa F Alisha F Alissa F Alissia F Alix F Aliya F Aliyana F
Aliza F Alizée F Allegra F Allizza F Alma F Almira F Alva F Alva-Maria F Alya F
Alysha F Alyssa F Amalia F Amalya F Amanda F Amara F Amaris F Amber F Ambra F
Amea F Amelia F Amelie F Amélie F Amina F Amira F Amor F Amora F Amra F Amy F
Amy-Lou ? Ana F Anaahithaa F Anabell F Anabella F Anaëlle F Anaïs F Ananya F
Anastasia F Anastasija F Anastazia F Anaya F Andeline F Andjela F Andrea F
Anduena F Anela F Anesa F Angel ? Angela F Angelina F Angeline F Anik ? Anika F
Anila F Anisa F Anise F Anisha F Anja F Ann F Anna F Anna-Malee F Annabel F
Annabelle F Annalena F Anne F Anne-Sophie F Annica F Annicka F Annigna F Annik F
Annika F Anouk F Antonet F Antonia F Antonina F Anusha F Aralyn F Ariane F
Arianna F Ariel ? Ariela F Arina F Arisa F Arishmi F Arlinda F Arsema F Arwana F
Arwen F Arya F Ashley F Ashmi F Asmin F Astrid F Asya F Athena F Aubrey F Audrey
F Aurelia F Aurélie F Aurora F Ava F Avery F Avy F Aya F Ayana F Ayla F Ayleen F
Aylin F Ayse F Azahel F Azra F Barfin F Batoul F Batya F Beatrice F Belén F
Bella F Bente F Beril F Betel F Betelehim F Bleona F Bracha F Briana F Bronwyn F
Bruchi F Bruna F Büsra F Caelynn F Caitlin F Caja F Callista F Camille F Cao F
Carice F Carina F Carla F Carlotta F Carolina F Caroline F Cassandra F Castille
F Cataleya F Caterina F Catherine F Céleste F Celia F Celina F Celine F Ceylin F
Chana F Chanel F Chantal F Charielle F Charleen F Charlie ? Charlize F Charlott
F Charlotte F Charly F Chavi F Chaya F Chiara F Chiara-Maé F Chinyere F Chléa F
Chloe F Chloé F Ciara F Cilgia F Claire F
Clara F Claudia F Clea F Cleo F Cleofe F Clodagh F Cloé F Coco F Colette F Coral
F Coralie F Cyrielle F Daliah F Dalila F Dalilah F Dalina F Damiana F Damla F
Dana F Daniela F Daria F Darija F Dean ? Deborah F Déborah-Isabel F Defne F
Delaila F Delia F Delina F Derya F Deshira F Deva F Diana F Diara F Diarra F
Diesa F Dilara F Dina F Dinora F Djurdjina F Dominique F Donatella F Dora F
Dorina F Dunja F Eda F Edessa F Edith F Edna F Eduina F Eidi F Eileen F Ela F
Elanur F Elda F Eldana F Elea F Eleanor F Elena F Eleni F Elenor F Eleonor F
Eleonora F Elhana F Eliana F Elidiana F Eliel F Elif F Elin F Elina F Eline F
Elinor F Elisa F Elisabeth F Elise F Eliska F Eliza F Ella F Ellen F Elliana F
Elly F Elma F Elodie F Elona F Elora F Elsa F Elva F Elyssa F Emelie F Emi F
Emilia F Emiliana F Emilie F Émilie F Emilija F Emily F Emma F Enis F Enna F
Enrica F Enya F Erdina F Erika F Erin F Erina F Erisa F Erna F Erona F Erva F
Esma F Esmeralda F Estée F Esteline F Estelle F Ester F Esther F Eteri F
Euphrasie F Eva F Eve F Evelin F Eviana F Evita F Ewa F Eya F Fabia F Fabienne F
Fatima F Fatma F Fay F Faye F Fe F Fedora F Felia F Felizitas F Fiamma F Filipa
F Filippa F Filomena F Fina F Finja F Fiona F Fjolla F Flaminia F Flavia F Flor
F Flora F Florence F Florina F Florita F Flurina F Franca F Francesca F
Francisca F Franziska F Freija F Freya F Freyja F Frida F Gabriela F Gabrielle F
Gaia F Ganiesha F Gaon F Gavisgaa F Gemma F Georgina F Ghazia F Gia F Giada F
Gianna F Gila F Gioanna F Gioia F Giorgia F Gitty F Giulia F Greta F Grete F
Gwenaelle F Gwendolin F Gyane F Hadidscha F Hadzera F Hana F Hanar F Hania F
Hanna F Hannah F Hanni F Hédi ? Heidi F Helen F Helena F Helene F Helia F
Heloise F Héloïse F Helya F Henna F Henrietta F Heran F Hermela F Hiba F Hinata
F Hiteshree F Hodman F Honey F Iara F Ibtihal F Ida F Idil F Ilaria F Ileenia F
Ilenia F Iman F Ina F Indira F Ines F Inés F Inez F Ira F Irene F Iria F Irina F
Iris F Isabel F Isabela F Isabell F Isabella F Isabelle F Isra F Iva F Jada F
Jael F Jaël F Jaelle F Jaelynn F Jalina F Jamaya F Jana F Jane F Jannatul F Jara
F Jasmijn F Jasmin F Jasmina F Jayda F Jeanne F Jelisaveta F Jemina F Jenna F
Jennifer F Jerishka F Jessica F Jesuela F Jil F Joan ? Joana F Joanna F Johanna
F Jola F Joleen F Jolie F Jonna F Joseline F Josepha F Josephine F Joséphine F
Joudia F Jovana F Joy F Judith F Jule F Juli F Julia F Julie F Juliette F Julija
F Jully F Juna F Juno F Justine F Kahina F Kaja F Kalina F Kalista F Kapua F
Karina F Karla F Karnika F Karolina F Kashfia F Kassiopeia F Kate F Katerina F
Katharina F Kaya F Kayla F Kayley F Kayra F Kehla F Keira F Keren-Happuch F
Keziah F Khadra F Khardiata F Kiana F Kiara F Kim F Kinda F Kira F Klara F Klea
F Kostana F Kristina F Kristrún F Ksenija F Kugagini F Kyra F Ladina F Laetitia
F Laila F Laís F Lakshmi F Lana F Lani F Lara F Laraina F Larina F Larissa F
Laura F Laurelle F Lauri ? Laurianne F Lauryn F Lavin F Lavinia F Laya F Layana
F Layla F Lea F Léa F Leah F Leana F Leandra F Leanne F Leia F Leilani-Yara F
Lejla F Lelia F Lena F Leni F Lenia F Lenie F Lenja F Lenka F Lennie ? Leona F
Leoni F Leonie F Léonie F Leonor F Leticia F Leya F Leyla F Leyre F Lia F Liana
F Liane F Liann F Lianne F Liara F Liayana F Liba F Lidia F Lidija F Lijana F
Lila-Marie F Lili F Lilia F Lilian F Liliane F Lilijana F Lilith F Lilja F Lilla
F Lilli F Lilly F Lilly-Rose F Lilo F Lily F Lin F Lina F Linda F Line F Linn F
Lioba F Liora F Lisa F Lisandra F Liselotte F Liv F Liva F Livia F Liz F Loa F
Loe F Lokwa F Lola F Lorea F Loreen F Lorena F Loriana F Lorina F Lorisa F Lotta
F Louanne F Louisa F Louise F Lovina F Lua F Luana F Luanda F Lucia F Luciana F
Lucie F Lucy F Luisa F Luise F Lux ? Luzia F Lya F Lyna F Lynn F Lynna F Maëlle
F Maelyn F Maëlys F Maeva F Magali F Magalie F Magdalena F Mahsa F Maira F
Maisun F Maja F Maka F Malaeka F Malaika F Malea F Maléa F Malia F Malin F
Malkif F Malky F Maltina F Malu F Manar F Manha F Manisha F Mara F Maram F Mare
F Mareen F Maren F Margarida F Margherita F Margo F Margot F Maria F Mariangely
F Maribel F Marie F Marie-Alice F Marietta F Marija F Marika F Mariko F Marina F
Marisa F Marisol F Marissa F Marla F Marlen F Marlene F Marlène F Marlin F Marta
F Martina F Martje F Mary F Maryam F Mascha F Mathilda F Matilda F Matilde F
Mauadda F Maxine F Maya F Mayas F Mayla F Maylin F Mayra F Mayumi F Medea F
Medina F Meena F Mehjabeen F Mehnaz F Meila F Melanie F Mélanie F Melek F Melian
F Melike F Melina F Melisa F Melissa F Mélissa F Melka F Melyssa F Mena F Meret
F Meri F Merry F Meryem F Meta F Mia F Mía F Michal F Michelle F Mihaela F Mila
F Milania F Milena F Milica F Milja F Milla F Milou F Mina F Mingke F Minna F
Minu F Mira F Miray F Mirdie F Miriam F Mirjam F Mirta F Miya F Miyu F Moa F
Moena F Momo F Momoco F Mona F Morea F Mubera F Muriel F Mylène F Myriam F N'Dea
F Nabihaumama F Nadija F Nadin F Nadja F Nael ? Naemi F Naila F Naïma F Naina F
Naliya F Nandi F Naomi F Nara F Naraya F Nardos F Nastasija F Natalia F Natalina
F Natania F Natascha F Nathalie F Nava F Navida F Navina F Nayara F Nea F Neda F
Neea F Nejla F Nela F Nepheli F Nera F Nerea F Nerine F Nesma F Nesrine F Neva F
Nevia F Nevya F Nico ? Nicole F Nika F Nikita F Nikolija F Nikolina F Nina F
Nine F Nirya F Nisa F Nisha F Nives F Noa ? Noé ? Noë F Noée F Noelia F Noemi F
Noémie F Nola F Nora F Nordon F Norea F Norin F Norina F Norlha F Nour F Nova F
Nóva F Nubia F Nuo F Nura F Nurah F Nuray F Nuria F Nuriyah F Nusayba F Oceane F
Oda F Olive F Olivia F Olsa F Oluwashayo F Ornela F Ovia F Pamela-Anna F Paola F
Pattraporn F Paula F Paulina F Pauline F Penelope F Pepa F Perla F Pia F Pina F
Rabia F Rachel F Rahel F Rahela F Raïssa F Raizel F Rajana F Rana F Ranim F
Raphaela F Raquel F Rayan ? Rejhana F Rejin F Réka F Renata F Rhea F
Rhynisha-Anna F Ria F Riga F Rijona F Rina F Rita F Rivka F Riya F Roberta F
Robin ? Robyn F Rohzerin F Róisín F Romina F Romy F Ronja F Ronya F Rosa F Rose
F Rosina F Roxane F Royelle F Rozen F Rubaba F Rubina F Ruby F Rufina F Rukaye F
Rumi ? Rym F Saanvika F Sabrina F Sadia F Safiya F Sahira F Sahra F Sajal F
Salma F Salome F Salomé F Samantha F Samina F Samira F Samira-Aliyah F
Samira-Mukaddes F Samruddhi F Sania F Sanna F Sara F Sarah F Sarahi F Saraia F
Saranda F Saray F Sari F Sarina F Sasha F Saskia F Savka F Saya F Sayema F
Scilla F Sejla F Selene F Selihom F Selina F Selma F Semanur F Sena F Sephora F
Serafima F Serafina F Serafine F Seraina F Seraphina F Seraphine F Serena F
Serra F Setareh F Shan F Shanar F Shathviha F Shayenna F Shayna F Sheindel F
Shireen F Shirin F Shiyara F Shreshtha F Sia F Sidona F Siena F Sienna F Siiri F
Sila F Silja F Silvanie-Alison F Silvia F Simea F Simi F Simona F Sina F Sira F
Sirajum F Siri F Sirija F Sivana F Smilla F Sofia F Sofia-Margarita F Sofie F
Sofija F Solea F Soleil F Solène F Solenn F Sonia F Sophia F Sophie F Sora F
Soraya F Sosin F Sriya F Stella F Stina F Su F Subah F Suela F Suhaila F Suleqa
F Sumire F Summer F Syria F Syrina F Tabea F Talina F Tamara F Tamasha F Tamina
F Tamiya F Tara F Tatjana F Tayla F Tayscha F Tea F Tenzin ? Teodora F Tessa F
Tharusha F Thea F Theniya F Tiana F Tijana F Tilda F Timea F Timeja F Tina F
Tomma F Tonia F Tsiajara F Tuana F Tyra F Tzi ? Uendi F Uma F Urassaya F Vailea
F Valentina F Valentine F Valeria F Valerie F Vanessa F Vanja F Varshana F Vella
F Vera F Victoria F Viktoria F Vinda F Viola F Vivianne F Vivien F Vivienne F
Wanda F Wayane F Wilma F Xin F Xingchen F Yael F Yaël F Yamina F Yang F Yara F
Yasmine F Yeilin F Yen F Yersalm F Yesenia F Yeva F Yi F Yildiz-Kiymet F Ying ?
Yixin F Ylvi F Yocheved F Yoko F Yosan F Yosmely F Yuen F Yuhan F Yuna F Yvaine
F Zahraa F Zaina F Zazie F Zeinab F Zelda F Zeliha F Zenan F Zerya F Zeta F
Zeyna F Zeynep F Ziporah F Zivia F Zoe F Zoé F Zoë F Zoë-Sanaa F Zoey F Zohar F
Zoi F Zuri F Aadil M Aaron M Abdimaalik M Abdirahman M Abdul M Abdullah M Abi M
Abraham M Abrar M Abubakar M Achmed M Adam M Adan M Adesh M Adhrit M Adil M
Adiyan M Adrian M Adriano M Adrien M Adrijan M Adthish M Advay M Advik M Aeneas
M Afonso M Agustín M Ahammed M Ahnaf M Ahron M Aiden M Ailo M Aimo M Ajan M
Ajdin M Ajish M Akil M Akilar M Akira M Akito M Aksayan M Alan M Aldin M Aldion
M Alec M Alejandro M Aleksa M Aleksandar M Aleksander M Aleksandr M Alem M
Alessandro M Alessio M Alex M Alexander M Alexandre M Alexandru M Alexey M
Alexis M Alfred M Ali M Allison M Almir M Alois M Altin M Aly M Amael M Aman M
Amar M Amaury M Amedeo M Ami M Amil M Amin M Amir M Amirhan M Amirthesh M Ammar
M Amogh M Anaël M Anakin M Anas M Anatol M Anatole M Anay M Anayo M Andi M
Andreas M Andrej M Andrés M Andrey M Andri M Andrin M Andriy M Andy M Aneesh M
Anes M Angelo M Anoush M Anqi M Antoine M Anton M Antonio M António M Anua M
Anush M Arab M Arafat M Aramis M Aras M Arbion M Arda M Ardit M Arham M Arian M
Arianit M Arijon M Arin M Aris M Aritra M Ariya M Arlind M Arman M Armin M
Arnaud M Arne M Arno M Aron M Arsène M Art M Artemij M Arthur M Arturo M Arvid M
Arvin M Aryan M Arye M Aswad M Atharv M Attila M Attis M Aulon M Aurel M Aurelio
M Austin M Avinash M Avrohom M Axel M Ayan M Ayano M Ayham M Ayman M Aymar M
Aymon M Azaan M Azad M Azad-Can M Bailey M Balthazar M Barnaba M Barnabas M
Basil M Basilio M Bátor M Beda M Bela M Ben M Benart M Benjamin M Bennet M Benno
M Berend M Berktan M Bertal M Besir M Bilal M Bilgehan M Birk M Bjarne M Bleart
M Blend M Blendi M Bo M Bogdan M Bolaji M Bora M Boris M Brady M Brandon M
Breyling M Brice M Bruce M Bruno M Bryan M Butrint M Caleb M Camil M Can M Cário
M Carl M Carlo M Carlos M Carmelo M Cas M Caspar M Cedric M Cédric M Célestin M
Celestino M Cemil-Lee M César M Chaim M Chandor M Charles M Chilo M
Ciaran M Cillian M Cla M Claudio M Colin M
Collin M Connor M Conrad M Constantin M Corey M Cosmo M Cristian M Curdin M
Custavo M Cynphael M Cyprian M Cyrill M Daan M Dagemawi M Daha M Dalmar M Damian
M Damián M Damien M Damjan M Daniel M Daniele M Danilo M Danny M Dareios M Darel
M Darian M Dario M Daris M Darius M Darwin M Davi M David M Dávid M Davide M
Davin M Davud M Denis M Deniz M Deon M Devan M Devin M Diago M Dian M Diar M
Diego M Dilom M Dimitri M Dino M Dion M Dionix M Dior M Dishan M Diyari M Djamal
M Djamilo M Domenico M Dominic M Dominik M Donart M Dorian M Dries M Drisar M
Driton M Duart M Duarte M Durgut M Durim M Dylan M Ebu M Ebubeker M Edgar M Edi
M Edon M Édouard M Edrian M Edward M Edwin M Efehan M Efraim M Ehimay M Einar M
Ekrem M Eldi M Eldian M Elia M Eliah M Elias M Elija M Elijah M Elio M Eliot M
Elliot M Elouan M Élouan M Eloy M Elvir M Emanuel M Emil M Emilio M Emin M Emir
M Emmanuel M Endrit M Enea M Enes M Engin M Engjëll M Ennio M Enrico M Enrique M
Ensar M Enzo M Erblin M Erd M Eren M Ergin M Eric M Erik M Erind M Erion M Eris
M Ernest-Auguste M Erol M Eron M Ersin M Ervin M Erwin M Essey M Ethan M Etienne
M Evan M Ewan M Eymen M Ezio M Fabian M Fabiàn M Fabio M Fabrice M Fadri M Faris
M Faruk M Federico M Félicien M Felipe M Felix M Ferdinand M Fernando M Filip M
Filipe M Finlay M Finn M Fionn M Firat M Fitz-Patrick M Flavio M Flori M Florian
M Florin M Flurin M Flynn M Francesco M Frederic M Frederick M Frederik M Frédo
M Fridtjof M Fritz M Furkan M Fynn M Gabriel M Gabriele M Gael M Galin M Gaspar
M Gaspard M Gavin M Geeth M Genc M Georg M Gerald M Geronimo M Getoar M Gian M
Gian-Andri M Gianluca M Gianno M Gibran M Gibril M Gil M Gil-Leo M Gilles M Gion
M Giona M Giovanni M Giuliano M Giuseppe M Glen M Glenn M Gonçalo M Gondini M
Gregor M Gregory M Güney M Guilien M Guillaume M Gustav M Gustavo M Gusti M
Haakon M Haci M Hadeed M Halil M Hamad M Hamid M Hamza M Hannes M Hans M Hari M
Haris M Harry M Hassan M Heath M Hektor M Hendri M Henri M Henrik M Henry M
Henus M Hugo M Hussein M Huw M Iago M Ian M Iasu M Ibrahim M Idan M Ieremia M
Ifran M Iheb M Ikechi M Ilai M Ilarion M Ilian M Ilias M Ilja M Ilyes M Ioav M
Iorek M Isaac M Isak M Ishaan M Ishak M Isi M Isidor M Ismael M Ismaël M Itay M
Ivan M Iven M Ivo M Jack M Jacob M Jacques M Jaden M Jae-Eun M Jago M Jahongir M
Jake M Jakob M Jakov M Jakub M Jamal M Jamen M James M Jamie M Jamiro M Jan M
Janick M Janis M Jann M Jannes M Jannik M Jannis M Janos M János M Janosch M
Jari M Jaron M Jasha M Jashon M Jason M Jasper M Javier M Jawhar M Jay M Jayden
M Jayme M Jean M Jechiel M Jemuël M Jens M Jeremias M Jeremy M Jerlen M Jeroen M
Jérôme M Jerun M Jhun M Jim M Jimmy M Jitzchak M Joah M Joaquin M Joel M Joël M
Johan M Johann M Johannes M Johansel M John M Johnny M Jon M Jona M Jonah M
Jonas M Jonathan M Joona M Jordan M Jorin M Joris M Jose M Josef M Joseph-Lion M
Josh M Joshua M Jovan M Jovin M Jules M Julian M Julien M Julius M Jun-Tao M
Junior M Junis M Juri M Jurij M Justin M Jythin M Kaan M Kailash M Kaitos M
Kajeesh M Kajetan M Kardo M Karim M Karl M Karl-Nikolaus M Kasimir M Kaspar M
Kassim M Kathiravan M Kaynaan M Kaynan M Keanan M Keano M Kejwan M Kenai M
Kennedy M Kento M Kerim M Kevin M Khodor M Kian M Kieran M Kilian M Kimon M
Kiran M Kiyan M Koji M Konrad M Konstantin M Kosmo M Krishang M Krzysztof M
Kuzey M Kyan M Kyle M Labib M Lakishan M Lamoral M Lanyu M Laris M Lars M Larton
M Lasse M Laurent M Laurenz M Laurin M Lawand M Lawrence M Lazar M Lean M
Leander M Leandro M Leano M Leart M Leas M Leen M Leif M Len M Lenart M Lend M
Lendrit M Lenert M Lenn M Lennard M Lennart M Lenno M Lennox M Lenny M Leno M
Leo M Leon M León M Léon M Leonard M Leonardo M Leonel M Leonidas M Leopold M
Leopoldo M Leron M Levi M Leviar M Levin M Levis M Lewis M Liam M Lian M Lias M
Liél M Lieven M Linard M Lino M Linor M Linus M Linus-Lou M Lio M Lion M Lionel
M Lior M Liun M Livio M Lizhang M Lloyd M Logan M Loïc M Lois M Long M Lono M
Lorenz M Lorenzo M Lorian M Lorik M Loris M Lou M Louay M Louis M Lovis M Lowell
M Luan M Luc M Luca M Lucas M Lucian M Lucien M Lucio M Ludwig M Luis M Luís M
Luk M Luka M Lukas M Lumen M Lyan M Maaran M Maddox M Mads M Mael M Maél M Máel
M Mahad M Mahir M Mahmoud M Mailo M Maksim M Maksut M Malik M Manfred M Máni M
Manuel M Manuele M Maor M Marc M Marcel M Marco M Marek M Marino M Marius M Mark
M Marko M Markus M Marley M Marlon M Marouane M Marti M Martim M Martin M Marvin
M Marwin M Mason M Massimo M Matay M Matej M Mateja M Mateo M Matheo M Mathéo M
Matheus M Mathias M Mathieu M Mathis M Matia M Matija M Matisjohu M Mats M
Matteo M Matthew M Matthias M Matthieu M Matti M Mattia M Mattis M Maurice M
Mauricio M Maurin M Maurizio M Mauro M Maurus M Max M Maxence M Maxim M Maxime M
Maximilian M Maximiliano M Maximilien M Maxmilan M Maylon M Median M
Melis M Melvin M Memet M Memet-Deniz M Menachem M Meo M Meris M Merlin M Mert M
Mete M Methma M Mias M Micah M Michael M Michele M Miguel M Mihailo M Mihajlo M
Mika M Mike M Mikias M Mikka M Mikko M Milad M Milan M Milo M Milos M Minyou M
Mio M Miran M Miraxh M Miro M Miron M Mishkin M Mithil M
Moische M Momodou M Mordechai M Moreno M Moritz M Morris M Moses M Mubaarak M
Muhannad M Muneer M Munzur M Mustafa M Nadir M
Nahuel M Naïm M Nando M Nasran M Nathan M Nathanael M Natnael M Nelio M Nelson M
Nenad M Neo M Néo M Nepomuk M Nevan M Nevin M Nevio M Nic M Nick M Nick-Nolan M
Niclas M Nicolas M Nicolás M Niilo M Nik M Nikhil M Niklas M Nikola M Nikolai M
Nikos M Nilas M Nils M Nima M Nimo M Nino M Niven M Nnamdi M Noah M Noam M Noan
M Noè M Noel M Noël M Nurhat M Nuri M Nurullmubin M Odarian M Odin M Ognjen M
Oliver M Olufemi M Omar M Omer M Ömer M Orell M Orlando M Oscar M Oskar M Osman
M Otávio M Otto M Ousmane M Pablo M Pablo-Battista M Paolo M Paris M Pascal M
Patrice M Patrick M Patrik M Paul M Pavle M Pawat M Pax M Paxton M Pedro M
Peppino M Pessach M Peven M Phil M Philemon M Philip M Philipp M Phineas M
Phoenix-Rock M Piero M Pietro M Pio M Pjotr M Prashanth M Quentin M Quinnlan M
Quirin M Rafael M Raffael M Raffaele M Rainer M Rami M Ramí M Ran M Raoul M
Raphael M Raphaël M Rasmus M Raúl M Ray M Rayen M Reban M Reda M Refoel M Rejan
M Relja M Remo M Remy M Rémy M Rénas M Rens M Resul M Rexhep M Rey M Riaan M
Rian M Riccardo M Richard M Rico M Ridley M Riley M Rimon M Rinaldo M Rio M Rion
M Riyan M Riza M Roa M Roald M Robert M Rodney-Jack M Rodrigo M Roman M Romeo M
Ronan M Rory M Rouven M Roy M Ruben M Rúben M Rubino M Rufus M Ryan M Saakith M
Saatvik M Sabir M Sabit M Sacha M Sahl M Salaj M Salman M Salomon M Sami M
Sami-Abdeljebar M Sammy M Samuel M Samuele M Samy M Sandro M Santiago M Saqlain
M Saranyu M Sascha M Sava M Schloime M Schmuel M Sebastian M Sebastián M Selim M
Semih M Semir M Semyon M Senthamil M Serafin M Seraphin M Seth M Sevan M Severin
M Seya M Seymen M Seymour M Shafin M Shahin M Shaor M Sharon M Shayaan M Shayan
M Sheerbaz M Shervin M Shian M Shiraz M Shlomo M Shon M Siddhesh M Silas M
Sileye M Silvan M Silvio M Simeon M Simon M Sirak M Siro M Sivan M Soel M Sol M
Solal M Souleiman M Sriswaralayan M Sruli M Stefan M Stefano M Stephan M Steven
M Stian M Strahinja M Sumedh M Suryansh M Sven M Taavi M Taha M Taner M Tanerau
M Tao M Tarik M Tashi M Tassilo M Tayshawn M Temuulen M Teo M Teris M Thelonious
M Thenujan M Theo M Theodor M Thiago M Thierry M Thies M Thijs M Thilo M Thom M
Thomas M Thor M Tiago M Tiemo M Til M Till M Tilo M Tim M Timo M Timon M
Timothée M Timotheos M Timothy M Tino M Titus M Tjade M Tjorben M Tobias M Tom M
Tomás M Tomeo M Tosco M Tristan M Truett M Tudor M Tugra M Turan M Tyson M Uari
M Uros M Ursin M Usuy M Uwais M Valentin M Valerian M Valerio M Vangelis M
Vasilios M Vico M Victor M Viggo M Vihaan M Viktor M Villads M Vincent M Vinzent
M Vinzenz M Vito M Vladimir M Vleron M Vo M Vojin M Wander M Wanja M William M
Wim M Xavier M Yaakov M Yadiel M Yair M Yamin M Yanhao M Yanic M Yanik M Yanis M
Yann M Yannick M Yannik M Yannis M Yardil M Yared M Yari M Yasin M Yasir M Yavuz
M Yecheskel M Yehudo M Yeirol M Yekda M Yellyngton M Yiannis M Yifan M Yilin M
Yitzchok M Ylli M Yoan M Yohannes M Yonatan M Yonathan M Yosias M Younes M
Yousef M Yousif M Yousuf M Youwei M Ysaac M Yuma M Yussef M Yusuf M Yves M Zaim
M Zeno M Zohaq M Zuheyb M Zvi M};

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

sub human_name {
  my $name = shift || one(keys %names);
  my $gender = $names{$name};
  return ($name, $gender);
}

1;
