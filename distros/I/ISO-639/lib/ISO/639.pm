#!/usr/bin/perl
#-------------------------------------------------------------------------------
# ISO 639 Language codes from:
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2017
#-------------------------------------------------------------------------------

package ISO::639;
our $VERSION = '20171214';
use v5.8.0;
use warnings FATAL => qw(all);
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;
use strict;

&generate unless caller;

#1 Language Codes                                                               # Language names from ISO 639 2 and 3 digit language codes in English, French, German

sub English(*)                                                                  #S Full name in English from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{en}{$code}
 }

sub anglais(*)                                                                  #S Full name in English from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{en}{$code}
 }

sub Englisch(*)                                                                 #S Full name in English from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{en}{$code}
 }

sub French(*)                                                                   #S Full name in French from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{fr}{$code}
 }

sub français(*)                                                                 #S Full name in French from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{fr}{$code}
 }

sub Französisch(*)                                                              #S Full name in French from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{fr}{$code}
 }

sub German(*)                                                                   #S Full name in German from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{de}{$code}
 }

sub allemand(*)                                                                 #S Full name in German from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{de}{$code}
 }

sub Deutsch(*)                                                                  #S Full name in German from 2 or 3 digit language code
 {my ($code) = @_;                                                              # Language code
  &codes->{de}{$code}
 }

#0

sub generate                                                                    ## Generate the language code tables from the raw data
 {my @l = grep {!/tr><tr/} split /\n/, &raw;                                    # Split the raw data into lines of <td>

  for (0..$#l/5)                                                                # Check that there are 5 rows per language code
   {my $n = $_ * 5;
    my $l = $l[$n];
    $l =~ m(<td scope="row">) or confess
      "Expected 3 digit language code on line $n, got:\n$l";
   }

  s(<td scope="row">|<td>|</td>|\A\s+|\s+\Z|&nbsp;)()g for @l;                  # Remove HTML

  my @L;                                                                        # Input in blocks of 5 to capture the data for each language
  for (0..$#l/5)
   {my $n = $_ * 5;
    next if $l[$n] =~ m(\Aqaa-qtz\Z);                                           # Ignore this block of 'Reserved for local use'
    push @L, [@l[$n..$n+4]];
   }

  for(@L)                                                                       # Break out languages with two codes
   {my ($c3) = @$_;
    my (undef, @r) = @$_;
    if ($c3 =~ m(\A(\w\w\w)\s*\x28B\x29<br>(\w\w\w)\s+\x28T\x29\Z))             # \x28 and \x29 are (, ) which apparently cannot be escaped in perl 5.18 and 5.20
     {push @L, [$1, @r];
      $_ = [$2, @r];
     }
   }

  my %l;                                                                        # {translation: en, fr, de}{language code} = [code 3, code 2, english, french, german]
  for(@L)
   {my ($c3, $c2, $e, $f, $g) = @$_;
    length($c3) == 3 or         confess "=$c3= is not 3 chars long";            # Check that the codes haveteh expected lengths
    length($c2) == 2 or !$c2 or confess "=$c2= is not 2 chars long";

    if    ($e =~ m(\ABokmål, Norwegian; Norwegian Bokmål\Z)s){$e = q(Norwegian)}# Choose a language name consistent with Aws::Polly
    elsif ($e =~ m(\ADutch; Flemish\Z)s)                     {$e = q(Dutch)}
    elsif ($e =~ m(\ARomanian; Moldavian; Moldovan\Z)s)      {$e = q(Romanian)}
    elsif ($e =~ m(\ASpanish; Castilian\Z)s)                 {$e = q(Spanish)}

    $l{en}{$c3} = $e;                                                           # 3 char code
    $l{fr}{$c3} = $f;
    $l{de}{$c3} = $g;
    if ($c2)                                                                    # 2 char code if present
     {$l{en}{$c2} = $e;
      $l{fr}{$c2} = $f;
      $l{de}{$c2} = $g;
     }
   }

  if (1)                                                                        # Generate a hash of translations we can use in Perl
   {my %r2 = map {$l{en}{$_}=>$_} grep{length($_) == 2} keys %{$l{en}};         # Language names in English from two character codes
    my %r3 = map {$l{en}{$_}=>$_} grep{length($_) == 3} keys %{$l{en}};         # Language names in English from three character codes
    my $d  = dump(\%l);
    my $r2 = dump(\%r2);
    my $r3 = dump(\%r3);
    $_ =~ s(\n) ( )gs for $d, $r2, $r3;                                         # Fit onto a single line

    my $enFr = ISO::639::French("en");                                          # Alternate language names
    my $enDe = ISO::639::German("en");

    my $frFr = ISO::639::French("fr");
    my $frDe = ISO::639::German("fr");

    my $deFr = ISO::639::French("de");
    my $deDe = ISO::639::German("de");

    my $s = <<END;
sub codes {$d}
sub languageFromCode2{$r2}
sub languageFromCode3{$r3}
BEGIN
 {*$enFr = *$enDe = *English;
  *$frFr = *$frDe = *French;
  *$deFr = *$deDe = *German;
 }
END

    if (my $f = do{"zzz.data"})                                                 # File to save the translations hash to
     {writeFile($f, $s);                                                        # Save the translations hash
      say STDERR "New version written to:\n$f";
     }
   }
 }

# Translations hash goes here
sub codes {{   de => {           aa  => "Danakil-Sprache",           aar => "Danakil-Sprache",           ab  => "Abchasisch",           abk => "Abchasisch",           ace => "Aceh-Sprache",           ach => "Acholi-Sprache",           ada => "Adangme-Sprache",           ady => "Adygisch",           ae  => "Avestisch",           af  => "Afrikaans",           afa => "Hamitosemitische Sprachen (Andere)",           afh => "Afrihili",           afr => "Afrikaans",           ain => "Ainu-Sprache",           ak  => "Akan-Sprache",           aka => "Akan-Sprache",           akk => "Akkadisch",           alb => "Albanisch",           ale => "Aleutisch",           alg => "Algonkin-Sprachen (Andere)",           alt => "Altaisch",           am  => "Amharisch",           amh => "Amharisch",           an  => "Aragonesisch",           ang => "Altenglisch",           anp => "Anga-Sprache",           apa => "Apachen-Sprachen",           ar  => "Arabisch",           ara => "Arabisch",           arc => "Aram\xE4isch",           arg => "Aragonesisch",           arm => "Armenisch",           arn => "Arauka-Sprachen",           arp => "Arapaho-Sprache",           art => "Kunstsprachen (Andere)",           arw => "Arawak-Sprachen",           as  => "Assamesisch",           asm => "Assamesisch",           ast => "Asturisch",           ath => "Athapaskische Sprachen (Andere)",           aus => "Australische Sprachen",           av  => "Awarisch",           ava => "Awarisch",           ave => "Avestisch",           awa => "Awadhi",           ay  => "Aymar\xE1-Sprache",           aym => "Aymar\xE1-Sprache",           az  => "Aserbeidschanisch",           aze => "Aserbeidschanisch",           ba  => "Baschkirisch",           bad => "Banda-Sprachen (Ubangi-Sprachen)",           bai => "Bamileke-Sprachen",           bak => "Baschkirisch",           bal => "Belutschisch",           bam => "Bambara-Sprache",           ban => "Balinesisch",           baq => "Baskisch",           bas => "Basaa-Sprache",           bat => "Baltische Sprachen (Andere)",           be  => "Wei\xDFrussisch",           bej => "Bedauye",           bel => "Wei\xDFrussisch",           bem => "Bemba-Sprache",           ben => "Bengali",           ber => "Berbersprachen (Andere)",           bg  => "Bulgarisch",           bh  => "Bihari (Andere)",           bho => "Bhojpuri",           bi  => "Beach-la-mar",           bih => "Bihari (Andere)",           bik => "Bikol-Sprache",           bin => "Edo-Sprache",           bis => "Beach-la-mar",           bla => "Blackfoot-Sprache",           bm  => "Bambara-Sprache",           bn  => "Bengali",           bnt => "Bantusprachen (Andere)",           bo  => "Tibetisch",           bod => "Tibetisch",           bos => "Bosnisch",           br  => "Bretonisch",           bra => "Braj-Bhakha",           bre => "Bretonisch",           bs  => "Bosnisch",           btk => "Batak-Sprache",           bua => "Burjatisch",           bug => "Bugi-Sprache",           bul => "Bulgarisch",           bur => "Birmanisch",           byn => "Bilin-Sprache",           ca  => "Katalanisch",           cad => "Caddo-Sprachen",           cai => "Indianersprachen, Zentralamerika (Andere)",           car => "Karibische Sprachen",           cat => "Katalanisch",           cau => "Kaukasische Sprachen (Andere)",           ce  => "Tschetschenisch",           ceb => "Cebuano",           cel => "Keltische Sprachen (Andere)",           ces => "Tschechisch",           ch  => "Chamorro-Sprache",           cha => "Chamorro-Sprache",           chb => "Chibcha-Sprachen",           che => "Tschetschenisch",           chg => "Tschagataisch",           chi => "Chinesisch",           chk => "Trukesisch",           chm => "Tscheremissisch",           chn => "Chinook-Jargon",           cho => "Choctaw-Sprache",           chp => "Chipewyan-Sprache",           chr => "Cherokee-Sprache",           chu => "Kirchenslawisch",           chv => "Tschuwaschisch",           chy => "Cheyenne-Sprache",           cmc => "Cham-Sprachen",           co  => "Korsisch",           cop => "Koptisch",           cor => "Kornisch",           cos => "Korsisch",           cpe => "Kreolisch-Englisch (Andere)",           cpf => "Kreolisch-Franz\xF6sisch (Andere)",           cpp => "Kreolisch-Portugiesisch (Andere)",           cr  => "Cree-Sprache",           cre => "Cree-Sprache",           crh => "Krimtatarisch",           crp => "Kreolische Sprachen; Pidginsprachen (Andere)",           cs  => "Tschechisch",           csb => "Kaschubisch",           cu  => "Kirchenslawisch",           cus => "Kuschitische Sprachen (Andere)",           cv  => "Tschuwaschisch",           cy  => "Kymrisch",           cym => "Kymrisch",           cze => "Tschechisch",           da  => "D\xE4nisch",           dak => "Dakota-Sprache",           dan => "D\xE4nisch",           dar => "Darginisch",           day => "Dajakisch",           de  => "Deutsch",           del => "Delaware-Sprache",           den => "Slave-Sprache",           deu => "Deutsch",           dgr => "Dogrib-Sprache",           din => "Dinka-Sprache",           div => "Maledivisch",           doi => "Dogri",           dra => "Drawidische Sprachen (Andere)",           dsb => "Niedersorbisch",           dua => "Duala-Sprachen",           dum => "Mittelniederl\xE4ndisch",           dut => "Niederl\xE4ndisch",           dv  => "Maledivisch",           dyu => "Dyula-Sprache",           dz  => "Dzongkha",           dzo => "Dzongkha",           ee  => "Ewe-Sprache",           efi => "Efik",           egy => "\xC4gyptisch",           eka => "Ekajuk",           el  => "Neugriechisch",           ell => "Neugriechisch",           elx => "Elamisch",           en  => "Englisch",           eng => "Englisch",           enm => "Mittelenglisch",           eo  => "Esperanto",           epo => "Esperanto",           es  => "Spanisch",           est => "Estnisch",           et  => "Estnisch",           eu  => "Baskisch",           eus => "Baskisch",           ewe => "Ewe-Sprache",           ewo => "Ewondo",           fa  => "Persisch",           fan => "Pangwe-Sprache",           fao => "F\xE4r\xF6isch",           fas => "Persisch",           fat => "Fante-Sprache",           ff  => "Ful",           fi  => "Finnisch",           fij => "Fidschi-Sprache",           fil => "Pilipino",           fin => "Finnisch",           fiu => "Finnougrische Sprachen (Andere)",           fj  => "Fidschi-Sprache",           fo  => "F\xE4r\xF6isch",           fon => "Fon-Sprache",           fr  => "Franz\xF6sisch",           fra => "Franz\xF6sisch",           fre => "Franz\xF6sisch",           frm => "Mittelfranz\xF6sisch",           fro => "Altfranz\xF6sisch",           frr => "Nordfriesisch",           frs => "Ostfriesisch",           fry => "Friesisch",           ful => "Ful",           fur => "Friulisch",           fy  => "Friesisch",           ga  => "Irisch",           gaa => "Ga-Sprache",           gay => "Gayo-Sprache",           gba => "Gbaya-Sprache",           gd  => "G\xE4lisch-Schottisch",           gem => "Germanische Sprachen (Andere)",           geo => "Georgisch",           ger => "Deutsch",           gez => "Alt\xE4thiopisch",           gil => "Gilbertesisch",           gl  => "Galicisch",           gla => "G\xE4lisch-Schottisch",           gle => "Irisch",           glg => "Galicisch",           glv => "Manx",           gmh => "Mittelhochdeutsch",           gn  => "Guaran\xED-Sprache",           goh => "Althochdeutsch",           gon => "Gondi-Sprache",           gor => "Gorontalesisch",           got => "Gotisch",           grb => "Grebo-Sprache",           grc => "Griechisch",           gre => "Neugriechisch",           grn => "Guaran\xED-Sprache",           gsw => "Schweizerdeutsch",           gu  => "Gujarati-Sprache",           guj => "Gujarati-Sprache",           gv  => "Manx",           gwi => "Kutchin-Sprache",           ha  => "Haussa-Sprache",           hai => "Haida-Sprache",           hat => "Ha\xEFtien (Haiti-Kreolisch)",           hau => "Haussa-Sprache",           haw => "Hawaiisch",           he  => "Hebr\xE4isch",           heb => "Hebr\xE4isch",           her => "Herero-Sprache",           hi  => "Hindi",           hil => "Hiligaynon-Sprache",           him => "Himachali",           hin => "Hindi",           hit => "Hethitisch",           hmn => "Miao-Sprachen",           hmo => "Hiri-Motu",           ho  => "Hiri-Motu",           hr  => "Kroatisch ",           hrv => "Kroatisch ",           hsb => "Obersorbisch",           ht  => "Ha\xEFtien (Haiti-Kreolisch)",           hu  => "Ungarisch",           hun => "Ungarisch",           hup => "Hupa-Sprache",           hy  => "Armenisch",           hye => "Armenisch",           hz  => "Herero-Sprache",           ia  => "Interlingua",           iba => "Iban-Sprache",           ibo => "Ibo-Sprache",           ice => "Isl\xE4ndisch",           id  => "Bahasa Indonesia",           ido => "Ido",           ie  => "Interlingue",           ig  => "Ibo-Sprache",           ii  => "Lalo-Sprache",           iii => "Lalo-Sprache",           ijo => "Ijo-Sprache",           ik  => "Inupik",           iku => "Inuktitut",           ile => "Interlingue",           ilo => "Ilokano-Sprache",           ina => "Interlingua",           inc => "Indoarische Sprachen (Andere)",           ind => "Bahasa Indonesia",           ine => "Indogermanische Sprachen (Andere)",           inh => "Inguschisch",           io  => "Ido",           ipk => "Inupik",           ira => "Iranische Sprachen (Andere)",           iro => "Irokesische Sprachen",           is  => "Isl\xE4ndisch",           isl => "Isl\xE4ndisch",           it  => "Italienisch",           ita => "Italienisch",           iu  => "Inuktitut",           ja  => "Japanisch",           jav => "Javanisch",           jbo => "Lojban",           jpn => "Japanisch",           jpr => "J\xFCdisch-Persisch",           jrb => "J\xFCdisch-Arabisch",           jv  => "Javanisch",           ka  => "Georgisch",           kaa => "Karakalpakisch",           kab => "Kabylisch",           kac => "Kachin-Sprache",           kal => "Gr\xF6nl\xE4ndisch",           kam => "Kamba-Sprache",           kan => "Kannada",           kar => "Karenisch",           kas => "Kaschmiri",           kat => "Georgisch",           kau => "Kanuri-Sprache",           kaw => "Kawi",           kaz => "Kasachisch",           kbd => "Kabardinisch",           kg  => "Kongo-Sprache",           kha => "Khasi-Sprache",           khi => "Khoisan-Sprachen (Andere)",           khm => "Kambodschanisch",           kho => "Sakisch",           ki  => "Kikuyu-Sprache",           kik => "Kikuyu-Sprache",           kin => "Rwanda-Sprache",           kir => "Kirgisisch",           kj  => "Kwanyama-Sprache",           kk  => "Kasachisch",           kl  => "Gr\xF6nl\xE4ndisch",           km  => "Kambodschanisch",           kmb => "Kimbundu-Sprache",           kn  => "Kannada",           ko  => "Koreanisch",           kok => "Konkani",           kom => "Komi-Sprache",           kon => "Kongo-Sprache",           kor => "Koreanisch",           kos => "Kosraeanisch",           kpe => "Kpelle-Sprache",           kr  => "Kanuri-Sprache",           krc => "Karatschaiisch-Balkarisch",           krl => "Karelisch",           kro => "Kru-Sprachen (Andere)",           kru => "Oraon-Sprache",           ks  => "Kaschmiri",           ku  => "Kurdisch",           kua => "Kwanyama-Sprache",           kum => "Kum\xFCkisch",           kur => "Kurdisch",           kut => "Kutenai-Sprache",           kv  => "Komi-Sprache",           kw  => "Kornisch",           ky  => "Kirgisisch",           la  => "Latein",           lad => "Judenspanisch",           lah => "Lahnda",           lam => "Lamba-Sprache (Bantusprache)",           lao => "Laotisch",           lat => "Latein",           lav => "Lettisch",           lb  => "Luxemburgisch",           lez => "Lesgisch",           lg  => "Ganda-Sprache",           li  => "Limburgisch",           lim => "Limburgisch",           lin => "Lingala",           lit => "Litauisch",           ln  => "Lingala",           lo  => "Laotisch",           lol => "Mongo-Sprache",           loz => "Rotse-Sprache",           lt  => "Litauisch",           ltz => "Luxemburgisch",           lu  => "Luba-Katanga-Sprache",           lua => "Lulua-Sprache",           lub => "Luba-Katanga-Sprache",           lug => "Ganda-Sprache",           lui => "Luise\xF1o-Sprache",           lun => "Lunda-Sprache",           luo => "Luo-Sprache",           lus => "Lushai-Sprache",           lv  => "Lettisch",           mac => "Makedonisch",           mad => "Maduresisch",           mag => "Khotta",           mah => "Marschallesisch",           mai => "Maithili",           mak => "Makassarisch",           mal => "Malayalam",           man => "Malinke-Sprache",           mao => "Maori-Sprache",           map => "Austronesische Sprachen (Andere)",           mar => "Marathi",           mas => "Massai-Sprache",           may => "Malaiisch",           mdf => "Mokscha-Sprache",           mdr => "Mandaresisch",           men => "Mende-Sprache",           mg  => "Malagassi-Sprache",           mga => "Mittelirisch",           mh  => "Marschallesisch",           mi  => "Maori-Sprache",           mic => "Micmac-Sprache",           min => "Minangkabau-Sprache",           mis => "Einzelne andere Sprachen",           mk  => "Makedonisch",           mkd => "Makedonisch",           mkh => "Mon-Khmer-Sprachen (Andere)",           ml  => "Malayalam",           mlg => "Malagassi-Sprache",           mlt => "Maltesisch",           mn  => "Mongolisch",           mnc => "Mandschurisch",           mni => "Meithei-Sprache",           mno => "Manobo-Sprachen",           moh => "Mohawk-Sprache",           mon => "Mongolisch",           mos => "Mossi-Sprache",           mr  => "Marathi",           mri => "Maori-Sprache",           ms  => "Malaiisch",           msa => "Malaiisch",           mt  => "Maltesisch",           mul => "Mehrere Sprachen",           mun => "Mundasprachen (Andere)",           mus => "Muskogisch",           mwl => "Mirandesisch",           mwr => "Marwari",           my  => "Birmanisch",           mya => "Birmanisch",           myn => "Maya-Sprachen",           myv => "Erza-Mordwinisch",           na  => "Nauruanisch",           nah => "Nahuatl",           nai => "Indianersprachen, Nordamerika (Andere)",           nap => "Neapel / Mundart",           nau => "Nauruanisch",           nav => "Navajo-Sprache",           nb  => "Bokm\xE5l",           nbl => "Ndebele-Sprache (Transvaal)",           nd  => "Ndebele-Sprache (Simbabwe)",           nde => "Ndebele-Sprache (Simbabwe)",           ndo => "Ndonga",           nds => "Niederdeutsch",           ne  => "Nepali",           nep => "Nepali",           new => "Newari",           ng  => "Ndonga",           nia => "Nias-Sprache",           nic => "Nigerkordofanische Sprachen (Andere)",           niu => "Niue-Sprache",           nl  => "Niederl\xE4ndisch",           nld => "Niederl\xE4ndisch",           nn  => "Nynorsk",           nno => "Nynorsk",           no  => "Norwegisch",           nob => "Bokm\xE5l",           nog => "Nogaisch",           non => "Altnorwegisch",           nor => "Norwegisch",           nqo => "N'Ko",           nr  => "Ndebele-Sprache (Transvaal)",           nso => "Pedi-Sprache",           nub => "Nubische Sprachen",           nv  => "Navajo-Sprache",           nwc => "Alt-Newari",           ny  => "Nyanja-Sprache",           nya => "Nyanja-Sprache",           nym => "Nyamwezi-Sprache",           nyn => "Nkole-Sprache",           nyo => "Nyoro-Sprache",           nzi => "Nzima-Sprache",           oc  => "Okzitanisch",           oci => "Okzitanisch",           oj  => "Ojibwa-Sprache",           oji => "Ojibwa-Sprache",           om  => "Galla-Sprache",           or  => "Oriya-Sprache",           ori => "Oriya-Sprache",           orm => "Galla-Sprache",           os  => "Ossetisch",           osa => "Osage-Sprache",           oss => "Ossetisch",           ota => "Osmanisch",           oto => "Otomangue-Sprachen",           pa  => "Pandschabi-Sprache",           paa => "Papuasprachen (Andere)",           pag => "Pangasinan-Sprache",           pal => "Mittelpersisch",           pam => "Pampanggan-Sprache",           pan => "Pandschabi-Sprache",           pap => "Papiamento",           pau => "Palau-Sprache",           peo => "Altpersisch",           per => "Persisch",           phi => "Philippinisch-Austronesisch (Andere)",           phn => "Ph\xF6nikisch",           pi  => "Pali",           pl  => "Polnisch",           pli => "Pali",           pol => "Polnisch",           pon => "Ponapeanisch",           por => "Portugiesisch",           pra => "Prakrit",           pro => "Altokzitanisch",           ps  => "Paschtu",           pt  => "Portugiesisch",           pus => "Paschtu",           qu  => "Quechua-Sprache",           que => "Quechua-Sprache",           raj => "Rajasthani",           rap => "Osterinsel-Sprache",           rar => "Rarotonganisch",           rm  => "R\xE4toromanisch",           rn  => "Rundi-Sprache",           ro  => "Rum\xE4nisch",           roa => "Romanische Sprachen (Andere)",           roh => "R\xE4toromanisch",           rom => "Romani (Sprache)",           ron => "Rum\xE4nisch",           ru  => "Russisch",           rum => "Rum\xE4nisch",           run => "Rundi-Sprache",           rup => "Aromunisch",           rus => "Russisch",           rw  => "Rwanda-Sprache",           sa  => "Sanskrit",           sad => "Sandawe-Sprache",           sag => "Sango-Sprache",           sah => "Jakutisch",           sai => "Indianersprachen, S\xFCdamerika (Andere)",           sal => "Salish-Sprache",           sam => "Samaritanisch",           san => "Sanskrit",           sas => "Sasak",           sat => "Santali",           sc  => "Sardisch",           scn => "Sizilianisch",           sco => "Schottisch",           sd  => "Sindhi-Sprache",           se  => "Nordsaamisch",           sel => "Selkupisch",           sem => "Semitische Sprachen (Andere)",           sg  => "Sango-Sprache",           sga => "Altirisch",           sgn => "Zeichensprachen",           shn => "Schan-Sprache",           si  => "Singhalesisch",           sid => "Sidamo-Sprache",           sin => "Singhalesisch",           sio => "Sioux-Sprachen (Andere)",           sit => "Sinotibetische Sprachen (Andere)",           sk  => "Slowakisch",           sl  => "Slowenisch",           sla => "Slawische Sprachen (Andere)",           slk => "Slowakisch",           slo => "Slowakisch",           slv => "Slowenisch",           sm  => "Samoanisch",           sma => "S\xFCdsaamisch",           sme => "Nordsaamisch",           smi => "Saamisch",           smj => "Lulesaamisch",           smn => "Inarisaamisch",           smo => "Samoanisch",           sms => "Skoltsaamisch",           sn  => "Schona-Sprache",           sna => "Schona-Sprache",           snd => "Sindhi-Sprache",           snk => "Soninke-Sprache",           so  => "Somali",           sog => "Sogdisch",           som => "Somali",           son => "Songhai-Sprache",           sot => "S\xFCd-Sotho-Sprache",           spa => "Spanisch",           sq  => "Albanisch",           sqi => "Albanisch",           sr  => "Serbisch ",           srd => "Sardisch",           srn => "Sranantongo",           srp => "Serbisch ",           srr => "Serer-Sprache",           ss  => "Swasi-Sprache",           ssa => "Nilosaharanische Sprachen (Andere)",           ssw => "Swasi-Sprache",           st  => "S\xFCd-Sotho-Sprache",           su  => "Sundanesisch",           suk => "Sukuma-Sprache",           sun => "Sundanesisch",           sus => "Susu",           sux => "Sumerisch",           sv  => "Schwedisch",           sw  => "Swahili",           swa => "Swahili",           swe => "Schwedisch",           syc => "Syrisch",           syr => "Neuostaram\xE4isch",           ta  => "Tamil",           tah => "Tahitisch",           tai => "Thaisprachen (Andere)",           tam => "Tamil",           tat => "Tatarisch",           te  => "Telugu-Sprache",           tel => "Telugu-Sprache",           tem => "Temne-Sprache",           ter => "Tereno-Sprache",           tet => "Tetum-Sprache",           tg  => "Tadschikisch",           tgk => "Tadschikisch",           tgl => "Tagalog",           th  => "Thail\xE4ndisch",           tha => "Thail\xE4ndisch",           ti  => "Tigrinja-Sprache",           tib => "Tibetisch",           tig => "Tigre-Sprache",           tir => "Tigrinja-Sprache",           tiv => "Tiv-Sprache",           tk  => "Turkmenisch",           tkl => "Tokelauanisch",           tl  => "Tagalog",           tlh => "Klingonisch",           tli => "Tlingit-Sprache",           tmh => "Tama\x{161}eq",           tn  => "Tswana-Sprache",           to  => "Tongaisch",           tog => "Tonga (Bantusprache, Sambia)",           ton => "Tongaisch",           tpi => "Neumelanesisch",           tr  => "T\xFCrkisch",           ts  => "Tsonga-Sprache",           tsi => "Tsimshian-Sprache",           tsn => "Tswana-Sprache",           tso => "Tsonga-Sprache",           tt  => "Tatarisch",           tuk => "Turkmenisch",           tum => "Tumbuka-Sprache",           tup => "Tupi-Sprache",           tur => "T\xFCrkisch",           tut => "Altaische Sprachen (Andere)",           tvl => "Elliceanisch",           tw  => "Twi-Sprache",           twi => "Twi-Sprache",           ty  => "Tahitisch",           tyv => "Tuwinisch",           udm => "Udmurtisch",           ug  => "Uigurisch",           uga => "Ugaritisch",           uig => "Uigurisch",           uk  => "Ukrainisch",           ukr => "Ukrainisch",           umb => "Mbundu-Sprache",           und => "Nicht zu entscheiden",           ur  => "Urdu",           urd => "Urdu",           uz  => "Usbekisch",           uzb => "Usbekisch",           vai => "Vai-Sprache",           ve  => "Venda-Sprache",           ven => "Venda-Sprache",           vi  => "Vietnamesisch",           vie => "Vietnamesisch",           vo  => "Volap\xFCk",           vol => "Volap\xFCk",           vot => "Wotisch",           wa  => "Wallonisch",           wak => "Wakash-Sprachen",           wal => "Walamo-Sprache",           war => "Waray",           was => "Washo-Sprache",           wel => "Kymrisch",           wen => "Sorbisch (Andere)",           wln => "Wallonisch",           wo  => "Wolof-Sprache",           wol => "Wolof-Sprache",           xal => "Kalm\xFCckisch",           xh  => "Xhosa-Sprache",           xho => "Xhosa-Sprache",           yao => "Yao-Sprache (Bantusprache)",           yap => "Yapesisch",           yi  => "Jiddisch",           yid => "Jiddisch",           yo  => "Yoruba-Sprache",           yor => "Yoruba-Sprache",           ypk => "Ypik-Sprachen",           za  => "Zhuang",           zap => "Zapotekisch",           zbl => "Bliss-Symbol",           zen => "Zenaga",           zgh => "",           zh  => "Chinesisch",           zha => "Zhuang",           zho => "Chinesisch",           znd => "Zande-Sprachen",           zu  => "Zulu-Sprache",           zul => "Zulu-Sprache",           zun => "Zu\xF1i-Sprache",           zxx => "Kein linguistischer Inhalt",           zza => "Zazaki",         },   en => {           aa  => "Afar",           aar => "Afar",           ab  => "Abkhazian",           abk => "Abkhazian",           ace => "Achinese",           ach => "Acoli",           ada => "Adangme",           ady => "Adyghe; Adygei",           ae  => "Avestan",           af  => "Afrikaans",           afa => "Afro-Asiatic languages",           afh => "Afrihili",           afr => "Afrikaans",           ain => "Ainu",           ak  => "Akan",           aka => "Akan",           akk => "Akkadian",           alb => "Albanian",           ale => "Aleut",           alg => "Algonquian languages",           alt => "Southern Altai",           am  => "Amharic",           amh => "Amharic",           an  => "Aragonese",           ang => "English, Old (ca.450-1100)",           anp => "Angika",           apa => "Apache languages",           ar  => "Arabic",           ara => "Arabic",           arc => "Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)",           arg => "Aragonese",           arm => "Armenian",           arn => "Mapudungun; Mapuche",           arp => "Arapaho",           art => "Artificial languages",           arw => "Arawak",           as  => "Assamese",           asm => "Assamese",           ast => "Asturian; Bable; Leonese; Asturleonese",           ath => "Athapascan languages",           aus => "Australian languages",           av  => "Avaric",           ava => "Avaric",           ave => "Avestan",           awa => "Awadhi",           ay  => "Aymara",           aym => "Aymara",           az  => "Azerbaijani",           aze => "Azerbaijani",           ba  => "Bashkir",           bad => "Banda languages",           bai => "Bamileke languages",           bak => "Bashkir",           bal => "Baluchi",           bam => "Bambara",           ban => "Balinese",           baq => "Basque",           bas => "Basa",           bat => "Baltic languages",           be  => "Belarusian",           bej => "Beja; Bedawiyet",           bel => "Belarusian",           bem => "Bemba",           ben => "Bengali",           ber => "Berber languages",           bg  => "Bulgarian",           bh  => "Bihari languages",           bho => "Bhojpuri",           bi  => "Bislama",           bih => "Bihari languages",           bik => "Bikol",           bin => "Bini; Edo",           bis => "Bislama",           bla => "Siksika",           bm  => "Bambara",           bn  => "Bengali",           bnt => "Bantu languages",           bo  => "Tibetan",           bod => "Tibetan",           bos => "Bosnian",           br  => "Breton",           bra => "Braj",           bre => "Breton",           bs  => "Bosnian",           btk => "Batak languages",           bua => "Buriat",           bug => "Buginese",           bul => "Bulgarian",           bur => "Burmese",           byn => "Blin; Bilin",           ca  => "Catalan; Valencian",           cad => "Caddo",           cai => "Central American Indian languages",           car => "Galibi Carib",           cat => "Catalan; Valencian",           cau => "Caucasian languages",           ce  => "Chechen",           ceb => "Cebuano",           cel => "Celtic languages",           ces => "Czech",           ch  => "Chamorro",           cha => "Chamorro",           chb => "Chibcha",           che => "Chechen",           chg => "Chagatai",           chi => "Chinese",           chk => "Chuukese",           chm => "Mari",           chn => "Chinook jargon",           cho => "Choctaw",           chp => "Chipewyan; Dene Suline",           chr => "Cherokee",           chu => "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic",           chv => "Chuvash",           chy => "Cheyenne",           cmc => "Chamic languages",           co  => "Corsican",           cop => "Coptic",           cor => "Cornish",           cos => "Corsican",           cpe => "Creoles and pidgins, English based",           cpf => "Creoles and pidgins, French-based",           cpp => "Creoles and pidgins, Portuguese-based",           cr  => "Cree",           cre => "Cree",           crh => "Crimean Tatar; Crimean Turkish",           crp => "Creoles and pidgins",           cs  => "Czech",           csb => "Kashubian",           cu  => "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic",           cus => "Cushitic languages",           cv  => "Chuvash",           cy  => "Welsh",           cym => "Welsh",           cze => "Czech",           da  => "Danish",           dak => "Dakota",           dan => "Danish",           dar => "Dargwa",           day => "Land Dayak languages",           de  => "German",           del => "Delaware",           den => "Slave (Athapascan)",           deu => "German",           dgr => "Dogrib",           din => "Dinka",           div => "Divehi; Dhivehi; Maldivian",           doi => "Dogri",           dra => "Dravidian languages",           dsb => "Lower Sorbian",           dua => "Duala",           dum => "Dutch, Middle (ca.1050-1350)",           dut => "Dutch",           dv  => "Divehi; Dhivehi; Maldivian",           dyu => "Dyula",           dz  => "Dzongkha",           dzo => "Dzongkha",           ee  => "Ewe",           efi => "Efik",           egy => "Egyptian (Ancient)",           eka => "Ekajuk",           el  => "Greek, Modern (1453-)",           ell => "Greek, Modern (1453-)",           elx => "Elamite",           en  => "English",           eng => "English",           enm => "English, Middle (1100-1500)",           eo  => "Esperanto",           epo => "Esperanto",           es  => "Spanish",           est => "Estonian",           et  => "Estonian",           eu  => "Basque",           eus => "Basque",           ewe => "Ewe",           ewo => "Ewondo",           fa  => "Persian",           fan => "Fang",           fao => "Faroese",           fas => "Persian",           fat => "Fanti",           ff  => "Fulah",           fi  => "Finnish",           fij => "Fijian",           fil => "Filipino; Pilipino",           fin => "Finnish",           fiu => "Finno-Ugrian languages",           fj  => "Fijian",           fo  => "Faroese",           fon => "Fon",           fr  => "French",           fra => "French",           fre => "French",           frm => "French, Middle (ca.1400-1600)",           fro => "French, Old (842-ca.1400)",           frr => "Northern Frisian",           frs => "Eastern Frisian",           fry => "Western Frisian",           ful => "Fulah",           fur => "Friulian",           fy  => "Western Frisian",           ga  => "Irish",           gaa => "Ga",           gay => "Gayo",           gba => "Gbaya",           gd  => "Gaelic; Scottish Gaelic",           gem => "Germanic languages",           geo => "Georgian",           ger => "German",           gez => "Geez",           gil => "Gilbertese",           gl  => "Galician",           gla => "Gaelic; Scottish Gaelic",           gle => "Irish",           glg => "Galician",           glv => "Manx",           gmh => "German, Middle High (ca.1050-1500)",           gn  => "Guarani",           goh => "German, Old High (ca.750-1050)",           gon => "Gondi",           gor => "Gorontalo",           got => "Gothic",           grb => "Grebo",           grc => "Greek, Ancient (to 1453)",           gre => "Greek, Modern (1453-)",           grn => "Guarani",           gsw => "Swiss German; Alemannic; Alsatian",           gu  => "Gujarati",           guj => "Gujarati",           gv  => "Manx",           gwi => "Gwich'in",           ha  => "Hausa",           hai => "Haida",           hat => "Haitian; Haitian Creole",           hau => "Hausa",           haw => "Hawaiian",           he  => "Hebrew",           heb => "Hebrew",           her => "Herero",           hi  => "Hindi",           hil => "Hiligaynon",           him => "Himachali languages; Western Pahari languages",           hin => "Hindi",           hit => "Hittite",           hmn => "Hmong; Mong",           hmo => "Hiri Motu",           ho  => "Hiri Motu",           hr  => "Croatian",           hrv => "Croatian",           hsb => "Upper Sorbian",           ht  => "Haitian; Haitian Creole",           hu  => "Hungarian",           hun => "Hungarian",           hup => "Hupa",           hy  => "Armenian",           hye => "Armenian",           hz  => "Herero",           ia  => "Interlingua (International Auxiliary Language Association)",           iba => "Iban",           ibo => "Igbo",           ice => "Icelandic",           id  => "Indonesian",           ido => "Ido",           ie  => "Interlingue; Occidental",           ig  => "Igbo",           ii  => "Sichuan Yi; Nuosu",           iii => "Sichuan Yi; Nuosu",           ijo => "Ijo languages",           ik  => "Inupiaq",           iku => "Inuktitut",           ile => "Interlingue; Occidental",           ilo => "Iloko",           ina => "Interlingua (International Auxiliary Language Association)",           inc => "Indic languages",           ind => "Indonesian",           ine => "Indo-European languages",           inh => "Ingush",           io  => "Ido",           ipk => "Inupiaq",           ira => "Iranian languages",           iro => "Iroquoian languages",           is  => "Icelandic",           isl => "Icelandic",           it  => "Italian",           ita => "Italian",           iu  => "Inuktitut",           ja  => "Japanese",           jav => "Javanese",           jbo => "Lojban",           jpn => "Japanese",           jpr => "Judeo-Persian",           jrb => "Judeo-Arabic",           jv  => "Javanese",           ka  => "Georgian",           kaa => "Kara-Kalpak",           kab => "Kabyle",           kac => "Kachin; Jingpho",           kal => "Kalaallisut; Greenlandic",           kam => "Kamba",           kan => "Kannada",           kar => "Karen languages",           kas => "Kashmiri",           kat => "Georgian",           kau => "Kanuri",           kaw => "Kawi",           kaz => "Kazakh",           kbd => "Kabardian",           kg  => "Kongo",           kha => "Khasi",           khi => "Khoisan languages",           khm => "Central Khmer",           kho => "Khotanese; Sakan",           ki  => "Kikuyu; Gikuyu",           kik => "Kikuyu; Gikuyu",           kin => "Kinyarwanda",           kir => "Kirghiz; Kyrgyz",           kj  => "Kuanyama; Kwanyama",           kk  => "Kazakh",           kl  => "Kalaallisut; Greenlandic",           km  => "Central Khmer",           kmb => "Kimbundu",           kn  => "Kannada",           ko  => "Korean",           kok => "Konkani",           kom => "Komi",           kon => "Kongo",           kor => "Korean",           kos => "Kosraean",           kpe => "Kpelle",           kr  => "Kanuri",           krc => "Karachay-Balkar",           krl => "Karelian",           kro => "Kru languages",           kru => "Kurukh",           ks  => "Kashmiri",           ku  => "Kurdish",           kua => "Kuanyama; Kwanyama",           kum => "Kumyk",           kur => "Kurdish",           kut => "Kutenai",           kv  => "Komi",           kw  => "Cornish",           ky  => "Kirghiz; Kyrgyz",           la  => "Latin",           lad => "Ladino",           lah => "Lahnda",           lam => "Lamba",           lao => "Lao",           lat => "Latin",           lav => "Latvian",           lb  => "Luxembourgish; Letzeburgesch",           lez => "Lezghian",           lg  => "Ganda",           li  => "Limburgan; Limburger; Limburgish",           lim => "Limburgan; Limburger; Limburgish",           lin => "Lingala",           lit => "Lithuanian",           ln  => "Lingala",           lo  => "Lao",           lol => "Mongo",           loz => "Lozi",           lt  => "Lithuanian",           ltz => "Luxembourgish; Letzeburgesch",           lu  => "Luba-Katanga",           lua => "Luba-Lulua",           lub => "Luba-Katanga",           lug => "Ganda",           lui => "Luiseno",           lun => "Lunda",           luo => "Luo (Kenya and Tanzania)",           lus => "Lushai",           lv  => "Latvian",           mac => "Macedonian",           mad => "Madurese",           mag => "Magahi",           mah => "Marshallese",           mai => "Maithili",           mak => "Makasar",           mal => "Malayalam",           man => "Mandingo",           mao => "Maori",           map => "Austronesian languages",           mar => "Marathi",           mas => "Masai",           may => "Malay",           mdf => "Moksha",           mdr => "Mandar",           men => "Mende",           mg  => "Malagasy",           mga => "Irish, Middle (900-1200)",           mh  => "Marshallese",           mi  => "Maori",           mic => "Mi'kmaq; Micmac",           min => "Minangkabau",           mis => "Uncoded languages",           mk  => "Macedonian",           mkd => "Macedonian",           mkh => "Mon-Khmer languages",           ml  => "Malayalam",           mlg => "Malagasy",           mlt => "Maltese",           mn  => "Mongolian",           mnc => "Manchu",           mni => "Manipuri",           mno => "Manobo languages",           moh => "Mohawk",           mon => "Mongolian",           mos => "Mossi",           mr  => "Marathi",           mri => "Maori",           ms  => "Malay",           msa => "Malay",           mt  => "Maltese",           mul => "Multiple languages",           mun => "Munda languages",           mus => "Creek",           mwl => "Mirandese",           mwr => "Marwari",           my  => "Burmese",           mya => "Burmese",           myn => "Mayan languages",           myv => "Erzya",           na  => "Nauru",           nah => "Nahuatl languages",           nai => "North American Indian languages",           nap => "Neapolitan",           nau => "Nauru",           nav => "Navajo; Navaho",           nb  => "Norwegian",           nbl => "Ndebele, South; South Ndebele",           nd  => "Ndebele, North; North Ndebele",           nde => "Ndebele, North; North Ndebele",           ndo => "Ndonga",           nds => "Low German; Low Saxon; German, Low; Saxon, Low",           ne  => "Nepali",           nep => "Nepali",           new => "Nepal Bhasa; Newari",           ng  => "Ndonga",           nia => "Nias",           nic => "Niger-Kordofanian languages",           niu => "Niuean",           nl  => "Dutch",           nld => "Dutch",           nn  => "Norwegian Nynorsk; Nynorsk, Norwegian",           nno => "Norwegian Nynorsk; Nynorsk, Norwegian",           no  => "Norwegian",           nob => "Norwegian",           nog => "Nogai",           non => "Norse, Old",           nor => "Norwegian",           nqo => "N'Ko",           nr  => "Ndebele, South; South Ndebele",           nso => "Pedi; Sepedi; Northern Sotho",           nub => "Nubian languages",           nv  => "Navajo; Navaho",           nwc => "Classical Newari; Old Newari; Classical Nepal Bhasa",           ny  => "Chichewa; Chewa; Nyanja",           nya => "Chichewa; Chewa; Nyanja",           nym => "Nyamwezi",           nyn => "Nyankole",           nyo => "Nyoro",           nzi => "Nzima",           oc  => "Occitan (post 1500)",           oci => "Occitan (post 1500)",           oj  => "Ojibwa",           oji => "Ojibwa",           om  => "Oromo",           or  => "Oriya",           ori => "Oriya",           orm => "Oromo",           os  => "Ossetian; Ossetic",           osa => "Osage",           oss => "Ossetian; Ossetic",           ota => "Turkish, Ottoman (1500-1928)",           oto => "Otomian languages",           pa  => "Panjabi; Punjabi",           paa => "Papuan languages",           pag => "Pangasinan",           pal => "Pahlavi",           pam => "Pampanga; Kapampangan",           pan => "Panjabi; Punjabi",           pap => "Papiamento",           pau => "Palauan",           peo => "Persian, Old (ca.600-400 B.C.)",           per => "Persian",           phi => "Philippine languages",           phn => "Phoenician",           pi  => "Pali",           pl  => "Polish",           pli => "Pali",           pol => "Polish",           pon => "Pohnpeian",           por => "Portuguese",           pra => "Prakrit languages",           pro => "Proven\xE7al, Old (to 1500);Occitan, Old (to 1500)",           ps  => "Pushto; Pashto",           pt  => "Portuguese",           pus => "Pushto; Pashto",           qu  => "Quechua",           que => "Quechua",           raj => "Rajasthani",           rap => "Rapanui",           rar => "Rarotongan; Cook Islands Maori",           rm  => "Romansh",           rn  => "Rundi",           ro  => "Romanian",           roa => "Romance languages",           roh => "Romansh",           rom => "Romany",           ron => "Romanian",           ru  => "Russian",           rum => "Romanian",           run => "Rundi",           rup => "Aromanian; Arumanian; Macedo-Romanian",           rus => "Russian",           rw  => "Kinyarwanda",           sa  => "Sanskrit",           sad => "Sandawe",           sag => "Sango",           sah => "Yakut",           sai => "South American Indian languages",           sal => "Salishan languages",           sam => "Samaritan Aramaic",           san => "Sanskrit",           sas => "Sasak",           sat => "Santali",           sc  => "Sardinian",           scn => "Sicilian",           sco => "Scots",           sd  => "Sindhi",           se  => "Northern Sami",           sel => "Selkup",           sem => "Semitic languages",           sg  => "Sango",           sga => "Irish, Old (to 900)",           sgn => "Sign Languages",           shn => "Shan",           si  => "Sinhala; Sinhalese",           sid => "Sidamo",           sin => "Sinhala; Sinhalese",           sio => "Siouan languages",           sit => "Sino-Tibetan languages",           sk  => "Slovak",           sl  => "Slovenian",           sla => "Slavic languages",           slk => "Slovak",           slo => "Slovak",           slv => "Slovenian",           sm  => "Samoan",           sma => "Southern Sami",           sme => "Northern Sami",           smi => "Sami languages",           smj => "Lule Sami",           smn => "Inari Sami",           smo => "Samoan",           sms => "Skolt Sami",           sn  => "Shona",           sna => "Shona",           snd => "Sindhi",           snk => "Soninke",           so  => "Somali",           sog => "Sogdian",           som => "Somali",           son => "Songhai languages",           sot => "Sotho, Southern",           spa => "Spanish",           sq  => "Albanian",           sqi => "Albanian",           sr  => "Serbian",           srd => "Sardinian",           srn => "Sranan Tongo",           srp => "Serbian",           srr => "Serer",           ss  => "Swati",           ssa => "Nilo-Saharan languages",           ssw => "Swati",           st  => "Sotho, Southern",           su  => "Sundanese",           suk => "Sukuma",           sun => "Sundanese",           sus => "Susu",           sux => "Sumerian",           sv  => "Swedish",           sw  => "Swahili",           swa => "Swahili",           swe => "Swedish",           syc => "Classical Syriac",           syr => "Syriac",           ta  => "Tamil",           tah => "Tahitian",           tai => "Tai languages",           tam => "Tamil",           tat => "Tatar",           te  => "Telugu",           tel => "Telugu",           tem => "Timne",           ter => "Tereno",           tet => "Tetum",           tg  => "Tajik",           tgk => "Tajik",           tgl => "Tagalog",           th  => "Thai",           tha => "Thai",           ti  => "Tigrinya",           tib => "Tibetan",           tig => "Tigre",           tir => "Tigrinya",           tiv => "Tiv",           tk  => "Turkmen",           tkl => "Tokelau",           tl  => "Tagalog",           tlh => "Klingon; tlhIngan-Hol",           tli => "Tlingit",           tmh => "Tamashek",           tn  => "Tswana",           to  => "Tonga (Tonga Islands)",           tog => "Tonga (Nyasa)",           ton => "Tonga (Tonga Islands)",           tpi => "Tok Pisin",           tr  => "Turkish",           ts  => "Tsonga",           tsi => "Tsimshian",           tsn => "Tswana",           tso => "Tsonga",           tt  => "Tatar",           tuk => "Turkmen",           tum => "Tumbuka",           tup => "Tupi languages",           tur => "Turkish",           tut => "Altaic languages",           tvl => "Tuvalu",           tw  => "Twi",           twi => "Twi",           ty  => "Tahitian",           tyv => "Tuvinian",           udm => "Udmurt",           ug  => "Uighur; Uyghur",           uga => "Ugaritic",           uig => "Uighur; Uyghur",           uk  => "Ukrainian",           ukr => "Ukrainian",           umb => "Umbundu",           und => "Undetermined",           ur  => "Urdu",           urd => "Urdu",           uz  => "Uzbek",           uzb => "Uzbek",           vai => "Vai",           ve  => "Venda",           ven => "Venda",           vi  => "Vietnamese",           vie => "Vietnamese",           vo  => "Volap\xFCk",           vol => "Volap\xFCk",           vot => "Votic",           wa  => "Walloon",           wak => "Wakashan languages",           wal => "Wolaitta; Wolaytta",           war => "Waray",           was => "Washo",           wel => "Welsh",           wen => "Sorbian languages",           wln => "Walloon",           wo  => "Wolof",           wol => "Wolof",           xal => "Kalmyk; Oirat",           xh  => "Xhosa",           xho => "Xhosa",           yao => "Yao",           yap => "Yapese",           yi  => "Yiddish",           yid => "Yiddish",           yo  => "Yoruba",           yor => "Yoruba",           ypk => "Yupik languages",           za  => "Zhuang; Chuang",           zap => "Zapotec",           zbl => "Blissymbols; Blissymbolics; Bliss",           zen => "Zenaga",           zgh => "Standard Moroccan Tamazight",           zh  => "Chinese",           zha => "Zhuang; Chuang",           zho => "Chinese",           znd => "Zande languages",           zu  => "Zulu",           zul => "Zulu",           zun => "Zuni",           zxx => "No linguistic content; Not applicable",           zza => "Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki",         },   fr => {           aa  => "afar",           aar => "afar",           ab  => "abkhaze",           abk => "abkhaze",           ace => "aceh",           ach => "acoli",           ada => "adangme",           ady => "adygh\xE9",           ae  => "avestique",           af  => "afrikaans",           afa => "afro-asiatiques, langues",           afh => "afrihili",           afr => "afrikaans",           ain => "a\xEFnou",           ak  => "akan",           aka => "akan",           akk => "akkadien",           alb => "albanais",           ale => "al\xE9oute",           alg => "algonquines, langues",           alt => "altai du Sud",           am  => "amharique",           amh => "amharique",           an  => "aragonais",           ang => "anglo-saxon (ca.450-1100)",           anp => "angika",           apa => "apaches, langues",           ar  => "arabe",           ara => "arabe",           arc => "aram\xE9en d'empire (700-300 BCE)",           arg => "aragonais",           arm => "arm\xE9nien",           arn => "mapudungun; mapuche; mapuce",           arp => "arapaho",           art => "artificielles, langues",           arw => "arawak",           as  => "assamais",           asm => "assamais",           ast => "asturien; bable; l\xE9onais; asturol\xE9onais",           ath => "athapascanes, langues",           aus => "australiennes, langues",           av  => "avar",           ava => "avar",           ave => "avestique",           awa => "awadhi",           ay  => "aymara",           aym => "aymara",           az  => "az\xE9ri",           aze => "az\xE9ri",           ba  => "bachkir",           bad => "banda, langues",           bai => "bamil\xE9k\xE9, langues",           bak => "bachkir",           bal => "baloutchi",           bam => "bambara",           ban => "balinais",           baq => "basque",           bas => "basa",           bat => "baltes, langues",           be  => "bi\xE9lorusse",           bej => "bedja",           bel => "bi\xE9lorusse",           bem => "bemba",           ben => "bengali",           ber => "berb\xE8res, langues",           bg  => "bulgare",           bh  => "langues biharis",           bho => "bhojpuri",           bi  => "bichlamar",           bih => "langues biharis",           bik => "bikol",           bin => "bini; edo",           bis => "bichlamar",           bla => "blackfoot",           bm  => "bambara",           bn  => "bengali",           bnt => "bantou, langues",           bo  => "tib\xE9tain",           bod => "tib\xE9tain",           bos => "bosniaque",           br  => "breton",           bra => "braj",           bre => "breton",           bs  => "bosniaque",           btk => "batak, langues",           bua => "bouriate",           bug => "bugi",           bul => "bulgare",           bur => "birman",           byn => "blin; bilen",           ca  => "catalan; valencien",           cad => "caddo",           cai => "am\xE9rindiennes de l'Am\xE9rique centrale,  langues",           car => "karib; galibi; carib",           cat => "catalan; valencien",           cau => "caucasiennes, langues",           ce  => "tch\xE9tch\xE8ne",           ceb => "cebuano",           cel => "celtiques, langues; celtes, langues",           ces => "tch\xE8que",           ch  => "chamorro",           cha => "chamorro",           chb => "chibcha",           che => "tch\xE9tch\xE8ne",           chg => "djaghata\xEF",           chi => "chinois",           chk => "chuuk",           chm => "mari",           chn => "chinook, jargon",           cho => "choctaw",           chp => "chipewyan",           chr => "cherokee",           chu => "slavon d'\xE9glise; vieux slave; slavon liturgique; vieux bulgare",           chv => "tchouvache",           chy => "cheyenne",           cmc => "chames, langues",           co  => "corse",           cop => "copte",           cor => "cornique",           cos => "corse",           cpe => "cr\xE9oles et pidgins bas\xE9s sur l'anglais",           cpf => "cr\xE9oles et pidgins bas\xE9s sur le fran\xE7ais",           cpp => "cr\xE9oles et pidgins bas\xE9s sur le portugais",           cr  => "cree",           cre => "cree",           crh => "tatar de Crim\xE9",           crp => "cr\xE9oles et pidgins",           cs  => "tch\xE8que",           csb => "kachoube",           cu  => "slavon d'\xE9glise; vieux slave; slavon liturgique; vieux bulgare",           cus => "couchitiques,  langues",           cv  => "tchouvache",           cy  => "gallois",           cym => "gallois",           cze => "tch\xE8que",           da  => "danois",           dak => "dakota",           dan => "danois",           dar => "dargwa",           day => "dayak, langues",           de  => "allemand",           del => "delaware",           den => "esclave (athapascan)",           deu => "allemand",           dgr => "dogrib",           din => "dinka",           div => "maldivien",           doi => "dogri",           dra => "dravidiennes,  langues",           dsb => "bas-sorabe",           dua => "douala",           dum => "n\xE9erlandais moyen (ca. 1050-1350)",           dut => "n\xE9erlandais; flamand",           dv  => "maldivien",           dyu => "dioula",           dz  => "dzongkha",           dzo => "dzongkha",           ee  => "\xE9w\xE9",           efi => "efik",           egy => "\xE9gyptien",           eka => "ekajuk",           el  => "grec moderne (apr\xE8s 1453)",           ell => "grec moderne (apr\xE8s 1453)",           elx => "\xE9lamite",           en  => "anglais",           eng => "anglais",           enm => "anglais moyen (1100-1500)",           eo  => "esp\xE9ranto",           epo => "esp\xE9ranto",           es  => "espagnol; castillan",           est => "estonien",           et  => "estonien",           eu  => "basque",           eus => "basque",           ewe => "\xE9w\xE9",           ewo => "\xE9wondo",           fa  => "persan",           fan => "fang",           fao => "f\xE9ro\xEFen",           fas => "persan",           fat => "fanti",           ff  => "peul",           fi  => "finnois",           fij => "fidjien",           fil => "filipino; pilipino",           fin => "finnois",           fiu => "finno-ougriennes,  langues",           fj  => "fidjien",           fo  => "f\xE9ro\xEFen",           fon => "fon",           fr  => "fran\xE7ais",           fra => "fran\xE7ais",           fre => "fran\xE7ais",           frm => "fran\xE7ais moyen (1400-1600)",           fro => "fran\xE7ais ancien (842-ca.1400)",           frr => "frison septentrional",           frs => "frison oriental",           fry => "frison occidental",           ful => "peul",           fur => "frioulan",           fy  => "frison occidental",           ga  => "irlandais",           gaa => "ga",           gay => "gayo",           gba => "gbaya",           gd  => "ga\xE9lique; ga\xE9lique \xE9cossais",           gem => "germaniques, langues",           geo => "g\xE9orgien",           ger => "allemand",           gez => "gu\xE8ze",           gil => "kiribati",           gl  => "galicien",           gla => "ga\xE9lique; ga\xE9lique \xE9cossais",           gle => "irlandais",           glg => "galicien",           glv => "manx; mannois",           gmh => "allemand, moyen haut (ca. 1050-1500)",           gn  => "guarani",           goh => "allemand, vieux haut (ca. 750-1050)",           gon => "gond",           gor => "gorontalo",           got => "gothique",           grb => "grebo",           grc => "grec ancien (jusqu'\xE0 1453)",           gre => "grec moderne (apr\xE8s 1453)",           grn => "guarani",           gsw => "suisse al\xE9manique; al\xE9manique; alsacien",           gu  => "goudjrati",           guj => "goudjrati",           gv  => "manx; mannois",           gwi => "gwich'in",           ha  => "haoussa",           hai => "haida",           hat => "ha\xEFtien; cr\xE9ole ha\xEFtien",           hau => "haoussa",           haw => "hawa\xEFen",           he  => "h\xE9breu",           heb => "h\xE9breu",           her => "herero",           hi  => "hindi",           hil => "hiligaynon",           him => "langues himachalis; langues paharis occidentales",           hin => "hindi",           hit => "hittite",           hmn => "hmong",           hmo => "hiri motu",           ho  => "hiri motu",           hr  => "croate",           hrv => "croate",           hsb => "haut-sorabe",           ht  => "ha\xEFtien; cr\xE9ole ha\xEFtien",           hu  => "hongrois",           hun => "hongrois",           hup => "hupa",           hy  => "arm\xE9nien",           hye => "arm\xE9nien",           hz  => "herero",           ia  => "interlingua (langue auxiliaire internationale)",           iba => "iban",           ibo => "igbo",           ice => "islandais",           id  => "indon\xE9sien",           ido => "ido",           ie  => "interlingue",           ig  => "igbo",           ii  => "yi de Sichuan",           iii => "yi de Sichuan",           ijo => "ijo, langues",           ik  => "inupiaq",           iku => "inuktitut",           ile => "interlingue",           ilo => "ilocano",           ina => "interlingua (langue auxiliaire internationale)",           inc => "indo-aryennes, langues",           ind => "indon\xE9sien",           ine => "indo-europ\xE9ennes, langues",           inh => "ingouche",           io  => "ido",           ipk => "inupiaq",           ira => "iraniennes, langues",           iro => "iroquoises, langues",           is  => "islandais",           isl => "islandais",           it  => "italien",           ita => "italien",           iu  => "inuktitut",           ja  => "japonais",           jav => "javanais",           jbo => "lojban",           jpn => "japonais",           jpr => "jud\xE9o-persan",           jrb => "jud\xE9o-arabe",           jv  => "javanais",           ka  => "g\xE9orgien",           kaa => "karakalpak",           kab => "kabyle",           kac => "kachin; jingpho",           kal => "groenlandais",           kam => "kamba",           kan => "kannada",           kar => "karen, langues",           kas => "kashmiri",           kat => "g\xE9orgien",           kau => "kanouri",           kaw => "kawi",           kaz => "kazakh",           kbd => "kabardien",           kg  => "kongo",           kha => "khasi",           khi => "kho\xEFsan, langues",           khm => "khmer central",           kho => "khotanais; sakan",           ki  => "kikuyu",           kik => "kikuyu",           kin => "rwanda",           kir => "kirghiz",           kj  => "kuanyama; kwanyama",           kk  => "kazakh",           kl  => "groenlandais",           km  => "khmer central",           kmb => "kimbundu",           kn  => "kannada",           ko  => "cor\xE9en",           kok => "konkani",           kom => "kom",           kon => "kongo",           kor => "cor\xE9en",           kos => "kosrae",           kpe => "kpell\xE9",           kr  => "kanouri",           krc => "karatchai balkar",           krl => "car\xE9lien",           kro => "krou, langues",           kru => "kurukh",           ks  => "kashmiri",           ku  => "kurde",           kua => "kuanyama; kwanyama",           kum => "koumyk",           kur => "kurde",           kut => "kutenai",           kv  => "kom",           kw  => "cornique",           ky  => "kirghiz",           la  => "latin",           lad => "jud\xE9o-espagnol",           lah => "lahnda",           lam => "lamba",           lao => "lao",           lat => "latin",           lav => "letton",           lb  => "luxembourgeois",           lez => "lezghien",           lg  => "ganda",           li  => "limbourgeois",           lim => "limbourgeois",           lin => "lingala",           lit => "lituanien",           ln  => "lingala",           lo  => "lao",           lol => "mongo",           loz => "lozi",           lt  => "lituanien",           ltz => "luxembourgeois",           lu  => "luba-katanga",           lua => "luba-lulua",           lub => "luba-katanga",           lug => "ganda",           lui => "luiseno",           lun => "lunda",           luo => "luo (Kenya et Tanzanie)",           lus => "lushai",           lv  => "letton",           mac => "mac\xE9donien",           mad => "madourais",           mag => "magahi",           mah => "marshall",           mai => "maithili",           mak => "makassar",           mal => "malayalam",           man => "mandingue",           mao => "maori",           map => "austron\xE9siennes, langues",           mar => "marathe",           mas => "massa\xEF",           may => "malais",           mdf => "moksa",           mdr => "mandar",           men => "mend\xE9",           mg  => "malgache",           mga => "irlandais moyen (900-1200)",           mh  => "marshall",           mi  => "maori",           mic => "mi'kmaq; micmac",           min => "minangkabau",           mis => "langues non cod\xE9es",           mk  => "mac\xE9donien",           mkd => "mac\xE9donien",           mkh => "m\xF4n-khmer, langues",           ml  => "malayalam",           mlg => "malgache",           mlt => "maltais",           mn  => "mongol",           mnc => "mandchou",           mni => "manipuri",           mno => "manobo, langues",           moh => "mohawk",           mon => "mongol",           mos => "mor\xE9",           mr  => "marathe",           mri => "maori",           ms  => "malais",           msa => "malais",           mt  => "maltais",           mul => "multilingue",           mun => "mounda, langues",           mus => "muskogee",           mwl => "mirandais",           mwr => "marvari",           my  => "birman",           mya => "birman",           myn => "maya, langues",           myv => "erza",           na  => "nauruan",           nah => "nahuatl, langues",           nai => "nord-am\xE9rindiennes, langues",           nap => "napolitain",           nau => "nauruan",           nav => "navaho",           nb  => "norv\xE9gien bokm\xE5l",           nbl => "nd\xE9b\xE9l\xE9 du Sud",           nd  => "nd\xE9b\xE9l\xE9 du Nord",           nde => "nd\xE9b\xE9l\xE9 du Nord",           ndo => "ndonga",           nds => "bas allemand; bas saxon; allemand, bas; saxon, bas",           ne  => "n\xE9palais",           nep => "n\xE9palais",           new => "nepal bhasa; newari",           ng  => "ndonga",           nia => "nias",           nic => "nig\xE9ro-kordofaniennes, langues",           niu => "niu\xE9",           nl  => "n\xE9erlandais; flamand",           nld => "n\xE9erlandais; flamand",           nn  => "norv\xE9gien nynorsk; nynorsk, norv\xE9gien",           nno => "norv\xE9gien nynorsk; nynorsk, norv\xE9gien",           no  => "norv\xE9gien",           nob => "norv\xE9gien bokm\xE5l",           nog => "noga\xEF; nogay",           non => "norrois, vieux",           nor => "norv\xE9gien",           nqo => "n'ko",           nr  => "nd\xE9b\xE9l\xE9 du Sud",           nso => "pedi; sepedi; sotho du Nord",           nub => "nubiennes, langues",           nv  => "navaho",           nwc => "newari classique",           ny  => "chichewa; chewa; nyanja",           nya => "chichewa; chewa; nyanja",           nym => "nyamwezi",           nyn => "nyankol\xE9",           nyo => "nyoro",           nzi => "nzema",           oc  => "occitan (apr\xE8s 1500)",           oci => "occitan (apr\xE8s 1500)",           oj  => "ojibwa",           oji => "ojibwa",           om  => "galla",           or  => "oriya",           ori => "oriya",           orm => "galla",           os  => "oss\xE8te",           osa => "osage",           oss => "oss\xE8te",           ota => "turc ottoman (1500-1928)",           oto => "otomi, langues",           pa  => "pendjabi",           paa => "papoues, langues",           pag => "pangasinan",           pal => "pahlavi",           pam => "pampangan",           pan => "pendjabi",           pap => "papiamento",           pau => "palau",           peo => "perse, vieux (ca. 600-400 av. J.-C.)",           per => "persan",           phi => "philippines, langues",           phn => "ph\xE9nicien",           pi  => "pali",           pl  => "polonais",           pli => "pali",           pol => "polonais",           pon => "pohnpei",           por => "portugais",           pra => "pr\xE2krit, langues",           pro => "proven\xE7al ancien (jusqu'\xE0 1500); occitan ancien (jusqu'\xE0 1500)",           ps  => "pachto",           pt  => "portugais",           pus => "pachto",           qu  => "quechua",           que => "quechua",           raj => "rajasthani",           rap => "rapanui",           rar => "rarotonga; maori des \xEEles Cook",           rm  => "romanche",           rn  => "rundi",           ro  => "roumain; moldave",           roa => "romanes, langues",           roh => "romanche",           rom => "tsigane",           ron => "roumain; moldave",           ru  => "russe",           rum => "roumain; moldave",           run => "rundi",           rup => "aroumain; mac\xE9do-roumain",           rus => "russe",           rw  => "rwanda",           sa  => "sanskrit",           sad => "sandawe",           sag => "sango",           sah => "iakoute",           sai => "sud-am\xE9rindiennes, langues",           sal => "salishennes, langues",           sam => "samaritain",           san => "sanskrit",           sas => "sasak",           sat => "santal",           sc  => "sarde",           scn => "sicilien",           sco => "\xE9cossais",           sd  => "sindhi",           se  => "sami du Nord",           sel => "selkoupe",           sem => "s\xE9mitiques, langues",           sg  => "sango",           sga => "irlandais ancien (jusqu'\xE0 900)",           sgn => "langues des signes",           shn => "chan",           si  => "singhalais",           sid => "sidamo",           sin => "singhalais",           sio => "sioux, langues",           sit => "sino-tib\xE9taines, langues",           sk  => "slovaque",           sl  => "slov\xE8ne",           sla => "slaves, langues",           slk => "slovaque",           slo => "slovaque",           slv => "slov\xE8ne",           sm  => "samoan",           sma => "sami du Sud",           sme => "sami du Nord",           smi => "sames, langues",           smj => "sami de Lule",           smn => "sami d'Inari",           smo => "samoan",           sms => "sami skolt",           sn  => "shona",           sna => "shona",           snd => "sindhi",           snk => "sonink\xE9",           so  => "somali",           sog => "sogdien",           som => "somali",           son => "songhai, langues",           sot => "sotho du Sud",           spa => "espagnol; castillan",           sq  => "albanais",           sqi => "albanais",           sr  => "serbe",           srd => "sarde",           srn => "sranan tongo",           srp => "serbe",           srr => "s\xE9r\xE8re",           ss  => "swati",           ssa => "nilo-sahariennes, langues",           ssw => "swati",           st  => "sotho du Sud",           su  => "soundanais",           suk => "sukuma",           sun => "soundanais",           sus => "soussou",           sux => "sum\xE9rien",           sv  => "su\xE9dois",           sw  => "swahili",           swa => "swahili",           swe => "su\xE9dois",           syc => "syriaque classique",           syr => "syriaque",           ta  => "tamoul",           tah => "tahitien",           tai => "tai, langues",           tam => "tamoul",           tat => "tatar",           te  => "t\xE9lougou",           tel => "t\xE9lougou",           tem => "temne",           ter => "tereno",           tet => "tetum",           tg  => "tadjik",           tgk => "tadjik",           tgl => "tagalog",           th  => "tha\xEF",           tha => "tha\xEF",           ti  => "tigrigna",           tib => "tib\xE9tain",           tig => "tigr\xE9",           tir => "tigrigna",           tiv => "tiv",           tk  => "turkm\xE8ne",           tkl => "tokelau",           tl  => "tagalog",           tlh => "klingon",           tli => "tlingit",           tmh => "tamacheq",           tn  => "tswana",           to  => "tongan (\xCEles Tonga)",           tog => "tonga (Nyasa)",           ton => "tongan (\xCEles Tonga)",           tpi => "tok pisin",           tr  => "turc",           ts  => "tsonga",           tsi => "tsimshian",           tsn => "tswana",           tso => "tsonga",           tt  => "tatar",           tuk => "turkm\xE8ne",           tum => "tumbuka",           tup => "tupi, langues",           tur => "turc",           tut => "alta\xEFques, langues",           tvl => "tuvalu",           tw  => "twi",           twi => "twi",           ty  => "tahitien",           tyv => "touva",           udm => "oudmourte",           ug  => "ou\xEFgour",           uga => "ougaritique",           uig => "ou\xEFgour",           uk  => "ukrainien",           ukr => "ukrainien",           umb => "umbundu",           und => "ind\xE9termin\xE9e",           ur  => "ourdou",           urd => "ourdou",           uz  => "ouszbek",           uzb => "ouszbek",           vai => "va\xEF",           ve  => "venda",           ven => "venda",           vi  => "vietnamien",           vie => "vietnamien",           vo  => "volap\xFCk",           vol => "volap\xFCk",           vot => "vote",           wa  => "wallon",           wak => "wakashanes, langues",           wal => "wolaitta; wolaytta",           war => "waray",           was => "washo",           wel => "gallois",           wen => "sorabes, langues",           wln => "wallon",           wo  => "wolof",           wol => "wolof",           xal => "kalmouk; o\xEFrat",           xh  => "xhosa",           xho => "xhosa",           yao => "yao",           yap => "yapois",           yi  => "yiddish",           yid => "yiddish",           yo  => "yoruba",           yor => "yoruba",           ypk => "yupik, langues",           za  => "zhuang; chuang",           zap => "zapot\xE8que",           zbl => "symboles Bliss; Bliss",           zen => "zenaga",           zgh => "amazighe standard marocain",           zh  => "chinois",           zha => "zhuang; chuang",           zho => "chinois",           znd => "zand\xE9, langues",           zu  => "zoulou",           zul => "zoulou",           zun => "zuni",           zxx => "pas de contenu linguistique; non applicable",           zza => "zaza; dimili; dimli; kirdki; kirmanjki; zazaki",         }, }}
sub languageFromCode2{{   "Abkhazian"                                                                        => "ab",   "Afar"                                                                             => "aa",   "Afrikaans"                                                                        => "af",   "Akan"                                                                             => "ak",   "Albanian"                                                                         => "sq",   "Amharic"                                                                          => "am",   "Arabic"                                                                           => "ar",   "Aragonese"                                                                        => "an",   "Armenian"                                                                         => "hy",   "Assamese"                                                                         => "as",   "Avaric"                                                                           => "av",   "Avestan"                                                                          => "ae",   "Aymara"                                                                           => "ay",   "Azerbaijani"                                                                      => "az",   "Bambara"                                                                          => "bm",   "Bashkir"                                                                          => "ba",   "Basque"                                                                           => "eu",   "Belarusian"                                                                       => "be",   "Bengali"                                                                          => "bn",   "Bihari languages"                                                                 => "bh",   "Bislama"                                                                          => "bi",   "Bosnian"                                                                          => "bs",   "Breton"                                                                           => "br",   "Bulgarian"                                                                        => "bg",   "Burmese"                                                                          => "my",   "Catalan; Valencian"                                                               => "ca",   "Central Khmer"                                                                    => "km",   "Chamorro"                                                                         => "ch",   "Chechen"                                                                          => "ce",   "Chichewa; Chewa; Nyanja"                                                          => "ny",   "Chinese"                                                                          => "zh",   "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic" => "cu",   "Chuvash"                                                                          => "cv",   "Cornish"                                                                          => "kw",   "Corsican"                                                                         => "co",   "Cree"                                                                             => "cr",   "Croatian"                                                                         => "hr",   "Czech"                                                                            => "cs",   "Danish"                                                                           => "da",   "Divehi; Dhivehi; Maldivian"                                                       => "dv",   "Dutch"                                                                            => "nl",   "Dzongkha"                                                                         => "dz",   "English"                                                                          => "en",   "Esperanto"                                                                        => "eo",   "Estonian"                                                                         => "et",   "Ewe"                                                                              => "ee",   "Faroese"                                                                          => "fo",   "Fijian"                                                                           => "fj",   "Finnish"                                                                          => "fi",   "French"                                                                           => "fr",   "Fulah"                                                                            => "ff",   "Gaelic; Scottish Gaelic"                                                          => "gd",   "Galician"                                                                         => "gl",   "Ganda"                                                                            => "lg",   "Georgian"                                                                         => "ka",   "German"                                                                           => "de",   "Greek, Modern (1453-)"                                                            => "el",   "Guarani"                                                                          => "gn",   "Gujarati"                                                                         => "gu",   "Haitian; Haitian Creole"                                                          => "ht",   "Hausa"                                                                            => "ha",   "Hebrew"                                                                           => "he",   "Herero"                                                                           => "hz",   "Hindi"                                                                            => "hi",   "Hiri Motu"                                                                        => "ho",   "Hungarian"                                                                        => "hu",   "Icelandic"                                                                        => "is",   "Ido"                                                                              => "io",   "Igbo"                                                                             => "ig",   "Indonesian"                                                                       => "id",   "Interlingua (International Auxiliary Language Association)"                       => "ia",   "Interlingue; Occidental"                                                          => "ie",   "Inuktitut"                                                                        => "iu",   "Inupiaq"                                                                          => "ik",   "Irish"                                                                            => "ga",   "Italian"                                                                          => "it",   "Japanese"                                                                         => "ja",   "Javanese"                                                                         => "jv",   "Kalaallisut; Greenlandic"                                                         => "kl",   "Kannada"                                                                          => "kn",   "Kanuri"                                                                           => "kr",   "Kashmiri"                                                                         => "ks",   "Kazakh"                                                                           => "kk",   "Kikuyu; Gikuyu"                                                                   => "ki",   "Kinyarwanda"                                                                      => "rw",   "Kirghiz; Kyrgyz"                                                                  => "ky",   "Komi"                                                                             => "kv",   "Kongo"                                                                            => "kg",   "Korean"                                                                           => "ko",   "Kuanyama; Kwanyama"                                                               => "kj",   "Kurdish"                                                                          => "ku",   "Lao"                                                                              => "lo",   "Latin"                                                                            => "la",   "Latvian"                                                                          => "lv",   "Limburgan; Limburger; Limburgish"                                                 => "li",   "Lingala"                                                                          => "ln",   "Lithuanian"                                                                       => "lt",   "Luba-Katanga"                                                                     => "lu",   "Luxembourgish; Letzeburgesch"                                                     => "lb",   "Macedonian"                                                                       => "mk",   "Malagasy"                                                                         => "mg",   "Malay"                                                                            => "ms",   "Malayalam"                                                                        => "ml",   "Maltese"                                                                          => "mt",   "Manx"                                                                             => "gv",   "Maori"                                                                            => "mi",   "Marathi"                                                                          => "mr",   "Marshallese"                                                                      => "mh",   "Mongolian"                                                                        => "mn",   "Nauru"                                                                            => "na",   "Navajo; Navaho"                                                                   => "nv",   "Ndebele, North; North Ndebele"                                                    => "nd",   "Ndebele, South; South Ndebele"                                                    => "nr",   "Ndonga"                                                                           => "ng",   "Nepali"                                                                           => "ne",   "Northern Sami"                                                                    => "se",   "Norwegian"                                                                        => "nb",   "Norwegian Nynorsk; Nynorsk, Norwegian"                                            => "nn",   "Occitan (post 1500)"                                                              => "oc",   "Ojibwa"                                                                           => "oj",   "Oriya"                                                                            => "or",   "Oromo"                                                                            => "om",   "Ossetian; Ossetic"                                                                => "os",   "Pali"                                                                             => "pi",   "Panjabi; Punjabi"                                                                 => "pa",   "Persian"                                                                          => "fa",   "Polish"                                                                           => "pl",   "Portuguese"                                                                       => "pt",   "Pushto; Pashto"                                                                   => "ps",   "Quechua"                                                                          => "qu",   "Romanian"                                                                         => "ro",   "Romansh"                                                                          => "rm",   "Rundi"                                                                            => "rn",   "Russian"                                                                          => "ru",   "Samoan"                                                                           => "sm",   "Sango"                                                                            => "sg",   "Sanskrit"                                                                         => "sa",   "Sardinian"                                                                        => "sc",   "Serbian"                                                                          => "sr",   "Shona"                                                                            => "sn",   "Sichuan Yi; Nuosu"                                                                => "ii",   "Sindhi"                                                                           => "sd",   "Sinhala; Sinhalese"                                                               => "si",   "Slovak"                                                                           => "sk",   "Slovenian"                                                                        => "sl",   "Somali"                                                                           => "so",   "Sotho, Southern"                                                                  => "st",   "Spanish"                                                                          => "es",   "Sundanese"                                                                        => "su",   "Swahili"                                                                          => "sw",   "Swati"                                                                            => "ss",   "Swedish"                                                                          => "sv",   "Tagalog"                                                                          => "tl",   "Tahitian"                                                                         => "ty",   "Tajik"                                                                            => "tg",   "Tamil"                                                                            => "ta",   "Tatar"                                                                            => "tt",   "Telugu"                                                                           => "te",   "Thai"                                                                             => "th",   "Tibetan"                                                                          => "bo",   "Tigrinya"                                                                         => "ti",   "Tonga (Tonga Islands)"                                                            => "to",   "Tsonga"                                                                           => "ts",   "Tswana"                                                                           => "tn",   "Turkish"                                                                          => "tr",   "Turkmen"                                                                          => "tk",   "Twi"                                                                              => "tw",   "Uighur; Uyghur"                                                                   => "ug",   "Ukrainian"                                                                        => "uk",   "Urdu"                                                                             => "ur",   "Uzbek"                                                                            => "uz",   "Venda"                                                                            => "ve",   "Vietnamese"                                                                       => "vi",   "Volap\xFCk"                                                                       => "vo",   "Walloon"                                                                          => "wa",   "Welsh"                                                                            => "cy",   "Western Frisian"                                                                  => "fy",   "Wolof"                                                                            => "wo",   "Xhosa"                                                                            => "xh",   "Yiddish"                                                                          => "yi",   "Yoruba"                                                                           => "yo",   "Zhuang; Chuang"                                                                   => "za",   "Zulu"                                                                             => "zu", }}
sub languageFromCode3{{   "Abkhazian"                                                                        => "abk",   "Achinese"                                                                         => "ace",   "Acoli"                                                                            => "ach",   "Adangme"                                                                          => "ada",   "Adyghe; Adygei"                                                                   => "ady",   "Afar"                                                                             => "aar",   "Afrihili"                                                                         => "afh",   "Afrikaans"                                                                        => "afr",   "Afro-Asiatic languages"                                                           => "afa",   "Ainu"                                                                             => "ain",   "Akan"                                                                             => "aka",   "Akkadian"                                                                         => "akk",   "Albanian"                                                                         => "alb",   "Aleut"                                                                            => "ale",   "Algonquian languages"                                                             => "alg",   "Altaic languages"                                                                 => "tut",   "Amharic"                                                                          => "amh",   "Angika"                                                                           => "anp",   "Apache languages"                                                                 => "apa",   "Arabic"                                                                           => "ara",   "Aragonese"                                                                        => "arg",   "Arapaho"                                                                          => "arp",   "Arawak"                                                                           => "arw",   "Armenian"                                                                         => "arm",   "Aromanian; Arumanian; Macedo-Romanian"                                            => "rup",   "Artificial languages"                                                             => "art",   "Assamese"                                                                         => "asm",   "Asturian; Bable; Leonese; Asturleonese"                                           => "ast",   "Athapascan languages"                                                             => "ath",   "Australian languages"                                                             => "aus",   "Austronesian languages"                                                           => "map",   "Avaric"                                                                           => "ava",   "Avestan"                                                                          => "ave",   "Awadhi"                                                                           => "awa",   "Aymara"                                                                           => "aym",   "Azerbaijani"                                                                      => "aze",   "Balinese"                                                                         => "ban",   "Baltic languages"                                                                 => "bat",   "Baluchi"                                                                          => "bal",   "Bambara"                                                                          => "bam",   "Bamileke languages"                                                               => "bai",   "Banda languages"                                                                  => "bad",   "Bantu languages"                                                                  => "bnt",   "Basa"                                                                             => "bas",   "Bashkir"                                                                          => "bak",   "Basque"                                                                           => "baq",   "Batak languages"                                                                  => "btk",   "Beja; Bedawiyet"                                                                  => "bej",   "Belarusian"                                                                       => "bel",   "Bemba"                                                                            => "bem",   "Bengali"                                                                          => "ben",   "Berber languages"                                                                 => "ber",   "Bhojpuri"                                                                         => "bho",   "Bihari languages"                                                                 => "bih",   "Bikol"                                                                            => "bik",   "Bini; Edo"                                                                        => "bin",   "Bislama"                                                                          => "bis",   "Blin; Bilin"                                                                      => "byn",   "Blissymbols; Blissymbolics; Bliss"                                                => "zbl",   "Bosnian"                                                                          => "bos",   "Braj"                                                                             => "bra",   "Breton"                                                                           => "bre",   "Buginese"                                                                         => "bug",   "Bulgarian"                                                                        => "bul",   "Buriat"                                                                           => "bua",   "Burmese"                                                                          => "bur",   "Caddo"                                                                            => "cad",   "Catalan; Valencian"                                                               => "cat",   "Caucasian languages"                                                              => "cau",   "Cebuano"                                                                          => "ceb",   "Celtic languages"                                                                 => "cel",   "Central American Indian languages"                                                => "cai",   "Central Khmer"                                                                    => "khm",   "Chagatai"                                                                         => "chg",   "Chamic languages"                                                                 => "cmc",   "Chamorro"                                                                         => "cha",   "Chechen"                                                                          => "che",   "Cherokee"                                                                         => "chr",   "Cheyenne"                                                                         => "chy",   "Chibcha"                                                                          => "chb",   "Chichewa; Chewa; Nyanja"                                                          => "nya",   "Chinese"                                                                          => "chi",   "Chinook jargon"                                                                   => "chn",   "Chipewyan; Dene Suline"                                                           => "chp",   "Choctaw"                                                                          => "cho",   "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic" => "chu",   "Chuukese"                                                                         => "chk",   "Chuvash"                                                                          => "chv",   "Classical Newari; Old Newari; Classical Nepal Bhasa"                              => "nwc",   "Classical Syriac"                                                                 => "syc",   "Coptic"                                                                           => "cop",   "Cornish"                                                                          => "cor",   "Corsican"                                                                         => "cos",   "Cree"                                                                             => "cre",   "Creek"                                                                            => "mus",   "Creoles and pidgins"                                                              => "crp",   "Creoles and pidgins, English based"                                               => "cpe",   "Creoles and pidgins, French-based"                                                => "cpf",   "Creoles and pidgins, Portuguese-based"                                            => "cpp",   "Crimean Tatar; Crimean Turkish"                                                   => "crh",   "Croatian"                                                                         => "hrv",   "Cushitic languages"                                                               => "cus",   "Czech"                                                                            => "ces",   "Dakota"                                                                           => "dak",   "Danish"                                                                           => "dan",   "Dargwa"                                                                           => "dar",   "Delaware"                                                                         => "del",   "Dinka"                                                                            => "din",   "Divehi; Dhivehi; Maldivian"                                                       => "div",   "Dogri"                                                                            => "doi",   "Dogrib"                                                                           => "dgr",   "Dravidian languages"                                                              => "dra",   "Duala"                                                                            => "dua",   "Dutch"                                                                            => "nld",   "Dutch, Middle (ca.1050-1350)"                                                     => "dum",   "Dyula"                                                                            => "dyu",   "Dzongkha"                                                                         => "dzo",   "Eastern Frisian"                                                                  => "frs",   "Efik"                                                                             => "efi",   "Egyptian (Ancient)"                                                               => "egy",   "Ekajuk"                                                                           => "eka",   "Elamite"                                                                          => "elx",   "English"                                                                          => "eng",   "English, Middle (1100-1500)"                                                      => "enm",   "English, Old (ca.450-1100)"                                                       => "ang",   "Erzya"                                                                            => "myv",   "Esperanto"                                                                        => "epo",   "Estonian"                                                                         => "est",   "Ewe"                                                                              => "ewe",   "Ewondo"                                                                           => "ewo",   "Fang"                                                                             => "fan",   "Fanti"                                                                            => "fat",   "Faroese"                                                                          => "fao",   "Fijian"                                                                           => "fij",   "Filipino; Pilipino"                                                               => "fil",   "Finnish"                                                                          => "fin",   "Finno-Ugrian languages"                                                           => "fiu",   "Fon"                                                                              => "fon",   "French"                                                                           => "fra",   "French, Middle (ca.1400-1600)"                                                    => "frm",   "French, Old (842-ca.1400)"                                                        => "fro",   "Friulian"                                                                         => "fur",   "Fulah"                                                                            => "ful",   "Ga"                                                                               => "gaa",   "Gaelic; Scottish Gaelic"                                                          => "gla",   "Galibi Carib"                                                                     => "car",   "Galician"                                                                         => "glg",   "Ganda"                                                                            => "lug",   "Gayo"                                                                             => "gay",   "Gbaya"                                                                            => "gba",   "Geez"                                                                             => "gez",   "Georgian"                                                                         => "geo",   "German"                                                                           => "ger",   "German, Middle High (ca.1050-1500)"                                               => "gmh",   "German, Old High (ca.750-1050)"                                                   => "goh",   "Germanic languages"                                                               => "gem",   "Gilbertese"                                                                       => "gil",   "Gondi"                                                                            => "gon",   "Gorontalo"                                                                        => "gor",   "Gothic"                                                                           => "got",   "Grebo"                                                                            => "grb",   "Greek, Ancient (to 1453)"                                                         => "grc",   "Greek, Modern (1453-)"                                                            => "ell",   "Guarani"                                                                          => "grn",   "Gujarati"                                                                         => "guj",   "Gwich'in"                                                                         => "gwi",   "Haida"                                                                            => "hai",   "Haitian; Haitian Creole"                                                          => "hat",   "Hausa"                                                                            => "hau",   "Hawaiian"                                                                         => "haw",   "Hebrew"                                                                           => "heb",   "Herero"                                                                           => "her",   "Hiligaynon"                                                                       => "hil",   "Himachali languages; Western Pahari languages"                                    => "him",   "Hindi"                                                                            => "hin",   "Hiri Motu"                                                                        => "hmo",   "Hittite"                                                                          => "hit",   "Hmong; Mong"                                                                      => "hmn",   "Hungarian"                                                                        => "hun",   "Hupa"                                                                             => "hup",   "Iban"                                                                             => "iba",   "Icelandic"                                                                        => "ice",   "Ido"                                                                              => "ido",   "Igbo"                                                                             => "ibo",   "Ijo languages"                                                                    => "ijo",   "Iloko"                                                                            => "ilo",   "Inari Sami"                                                                       => "smn",   "Indic languages"                                                                  => "inc",   "Indo-European languages"                                                          => "ine",   "Indonesian"                                                                       => "ind",   "Ingush"                                                                           => "inh",   "Interlingua (International Auxiliary Language Association)"                       => "ina",   "Interlingue; Occidental"                                                          => "ile",   "Inuktitut"                                                                        => "iku",   "Inupiaq"                                                                          => "ipk",   "Iranian languages"                                                                => "ira",   "Irish"                                                                            => "gle",   "Irish, Middle (900-1200)"                                                         => "mga",   "Irish, Old (to 900)"                                                              => "sga",   "Iroquoian languages"                                                              => "iro",   "Italian"                                                                          => "ita",   "Japanese"                                                                         => "jpn",   "Javanese"                                                                         => "jav",   "Judeo-Arabic"                                                                     => "jrb",   "Judeo-Persian"                                                                    => "jpr",   "Kabardian"                                                                        => "kbd",   "Kabyle"                                                                           => "kab",   "Kachin; Jingpho"                                                                  => "kac",   "Kalaallisut; Greenlandic"                                                         => "kal",   "Kalmyk; Oirat"                                                                    => "xal",   "Kamba"                                                                            => "kam",   "Kannada"                                                                          => "kan",   "Kanuri"                                                                           => "kau",   "Kara-Kalpak"                                                                      => "kaa",   "Karachay-Balkar"                                                                  => "krc",   "Karelian"                                                                         => "krl",   "Karen languages"                                                                  => "kar",   "Kashmiri"                                                                         => "kas",   "Kashubian"                                                                        => "csb",   "Kawi"                                                                             => "kaw",   "Kazakh"                                                                           => "kaz",   "Khasi"                                                                            => "kha",   "Khoisan languages"                                                                => "khi",   "Khotanese; Sakan"                                                                 => "kho",   "Kikuyu; Gikuyu"                                                                   => "kik",   "Kimbundu"                                                                         => "kmb",   "Kinyarwanda"                                                                      => "kin",   "Kirghiz; Kyrgyz"                                                                  => "kir",   "Klingon; tlhIngan-Hol"                                                            => "tlh",   "Komi"                                                                             => "kom",   "Kongo"                                                                            => "kon",   "Konkani"                                                                          => "kok",   "Korean"                                                                           => "kor",   "Kosraean"                                                                         => "kos",   "Kpelle"                                                                           => "kpe",   "Kru languages"                                                                    => "kro",   "Kuanyama; Kwanyama"                                                               => "kua",   "Kumyk"                                                                            => "kum",   "Kurdish"                                                                          => "kur",   "Kurukh"                                                                           => "kru",   "Kutenai"                                                                          => "kut",   "Ladino"                                                                           => "lad",   "Lahnda"                                                                           => "lah",   "Lamba"                                                                            => "lam",   "Land Dayak languages"                                                             => "day",   "Lao"                                                                              => "lao",   "Latin"                                                                            => "lat",   "Latvian"                                                                          => "lav",   "Lezghian"                                                                         => "lez",   "Limburgan; Limburger; Limburgish"                                                 => "lim",   "Lingala"                                                                          => "lin",   "Lithuanian"                                                                       => "lit",   "Lojban"                                                                           => "jbo",   "Low German; Low Saxon; German, Low; Saxon, Low"                                   => "nds",   "Lower Sorbian"                                                                    => "dsb",   "Lozi"                                                                             => "loz",   "Luba-Katanga"                                                                     => "lub",   "Luba-Lulua"                                                                       => "lua",   "Luiseno"                                                                          => "lui",   "Lule Sami"                                                                        => "smj",   "Lunda"                                                                            => "lun",   "Luo (Kenya and Tanzania)"                                                         => "luo",   "Lushai"                                                                           => "lus",   "Luxembourgish; Letzeburgesch"                                                     => "ltz",   "Macedonian"                                                                       => "mac",   "Madurese"                                                                         => "mad",   "Magahi"                                                                           => "mag",   "Maithili"                                                                         => "mai",   "Makasar"                                                                          => "mak",   "Malagasy"                                                                         => "mlg",   "Malay"                                                                            => "msa",   "Malayalam"                                                                        => "mal",   "Maltese"                                                                          => "mlt",   "Manchu"                                                                           => "mnc",   "Mandar"                                                                           => "mdr",   "Mandingo"                                                                         => "man",   "Manipuri"                                                                         => "mni",   "Manobo languages"                                                                 => "mno",   "Manx"                                                                             => "glv",   "Maori"                                                                            => "mri",   "Mapudungun; Mapuche"                                                              => "arn",   "Marathi"                                                                          => "mar",   "Mari"                                                                             => "chm",   "Marshallese"                                                                      => "mah",   "Marwari"                                                                          => "mwr",   "Masai"                                                                            => "mas",   "Mayan languages"                                                                  => "myn",   "Mende"                                                                            => "men",   "Mi'kmaq; Micmac"                                                                  => "mic",   "Minangkabau"                                                                      => "min",   "Mirandese"                                                                        => "mwl",   "Mohawk"                                                                           => "moh",   "Moksha"                                                                           => "mdf",   "Mon-Khmer languages"                                                              => "mkh",   "Mongo"                                                                            => "lol",   "Mongolian"                                                                        => "mon",   "Mossi"                                                                            => "mos",   "Multiple languages"                                                               => "mul",   "Munda languages"                                                                  => "mun",   "N'Ko"                                                                             => "nqo",   "Nahuatl languages"                                                                => "nah",   "Nauru"                                                                            => "nau",   "Navajo; Navaho"                                                                   => "nav",   "Ndebele, North; North Ndebele"                                                    => "nde",   "Ndebele, South; South Ndebele"                                                    => "nbl",   "Ndonga"                                                                           => "ndo",   "Neapolitan"                                                                       => "nap",   "Nepal Bhasa; Newari"                                                              => "new",   "Nepali"                                                                           => "nep",   "Nias"                                                                             => "nia",   "Niger-Kordofanian languages"                                                      => "nic",   "Nilo-Saharan languages"                                                           => "ssa",   "Niuean"                                                                           => "niu",   "No linguistic content; Not applicable"                                            => "zxx",   "Nogai"                                                                            => "nog",   "Norse, Old"                                                                       => "non",   "North American Indian languages"                                                  => "nai",   "Northern Frisian"                                                                 => "frr",   "Northern Sami"                                                                    => "sme",   "Norwegian"                                                                        => "nob",   "Norwegian Nynorsk; Nynorsk, Norwegian"                                            => "nno",   "Nubian languages"                                                                 => "nub",   "Nyamwezi"                                                                         => "nym",   "Nyankole"                                                                         => "nyn",   "Nyoro"                                                                            => "nyo",   "Nzima"                                                                            => "nzi",   "Occitan (post 1500)"                                                              => "oci",   "Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)"                   => "arc",   "Ojibwa"                                                                           => "oji",   "Oriya"                                                                            => "ori",   "Oromo"                                                                            => "orm",   "Osage"                                                                            => "osa",   "Ossetian; Ossetic"                                                                => "oss",   "Otomian languages"                                                                => "oto",   "Pahlavi"                                                                          => "pal",   "Palauan"                                                                          => "pau",   "Pali"                                                                             => "pli",   "Pampanga; Kapampangan"                                                            => "pam",   "Pangasinan"                                                                       => "pag",   "Panjabi; Punjabi"                                                                 => "pan",   "Papiamento"                                                                       => "pap",   "Papuan languages"                                                                 => "paa",   "Pedi; Sepedi; Northern Sotho"                                                     => "nso",   "Persian"                                                                          => "fas",   "Persian, Old (ca.600-400 B.C.)"                                                   => "peo",   "Philippine languages"                                                             => "phi",   "Phoenician"                                                                       => "phn",   "Pohnpeian"                                                                        => "pon",   "Polish"                                                                           => "pol",   "Portuguese"                                                                       => "por",   "Prakrit languages"                                                                => "pra",   "Proven\xE7al, Old (to 1500);Occitan, Old (to 1500)"                               => "pro",   "Pushto; Pashto"                                                                   => "pus",   "Quechua"                                                                          => "que",   "Rajasthani"                                                                       => "raj",   "Rapanui"                                                                          => "rap",   "Rarotongan; Cook Islands Maori"                                                   => "rar",   "Romance languages"                                                                => "roa",   "Romanian"                                                                         => "ron",   "Romansh"                                                                          => "roh",   "Romany"                                                                           => "rom",   "Rundi"                                                                            => "run",   "Russian"                                                                          => "rus",   "Salishan languages"                                                               => "sal",   "Samaritan Aramaic"                                                                => "sam",   "Sami languages"                                                                   => "smi",   "Samoan"                                                                           => "smo",   "Sandawe"                                                                          => "sad",   "Sango"                                                                            => "sag",   "Sanskrit"                                                                         => "san",   "Santali"                                                                          => "sat",   "Sardinian"                                                                        => "srd",   "Sasak"                                                                            => "sas",   "Scots"                                                                            => "sco",   "Selkup"                                                                           => "sel",   "Semitic languages"                                                                => "sem",   "Serbian"                                                                          => "srp",   "Serer"                                                                            => "srr",   "Shan"                                                                             => "shn",   "Shona"                                                                            => "sna",   "Sichuan Yi; Nuosu"                                                                => "iii",   "Sicilian"                                                                         => "scn",   "Sidamo"                                                                           => "sid",   "Sign Languages"                                                                   => "sgn",   "Siksika"                                                                          => "bla",   "Sindhi"                                                                           => "snd",   "Sinhala; Sinhalese"                                                               => "sin",   "Sino-Tibetan languages"                                                           => "sit",   "Siouan languages"                                                                 => "sio",   "Skolt Sami"                                                                       => "sms",   "Slave (Athapascan)"                                                               => "den",   "Slavic languages"                                                                 => "sla",   "Slovak"                                                                           => "slk",   "Slovenian"                                                                        => "slv",   "Sogdian"                                                                          => "sog",   "Somali"                                                                           => "som",   "Songhai languages"                                                                => "son",   "Soninke"                                                                          => "snk",   "Sorbian languages"                                                                => "wen",   "Sotho, Southern"                                                                  => "sot",   "South American Indian languages"                                                  => "sai",   "Southern Altai"                                                                   => "alt",   "Southern Sami"                                                                    => "sma",   "Spanish"                                                                          => "spa",   "Sranan Tongo"                                                                     => "srn",   "Standard Moroccan Tamazight"                                                      => "zgh",   "Sukuma"                                                                           => "suk",   "Sumerian"                                                                         => "sux",   "Sundanese"                                                                        => "sun",   "Susu"                                                                             => "sus",   "Swahili"                                                                          => "swa",   "Swati"                                                                            => "ssw",   "Swedish"                                                                          => "swe",   "Swiss German; Alemannic; Alsatian"                                                => "gsw",   "Syriac"                                                                           => "syr",   "Tagalog"                                                                          => "tgl",   "Tahitian"                                                                         => "tah",   "Tai languages"                                                                    => "tai",   "Tajik"                                                                            => "tgk",   "Tamashek"                                                                         => "tmh",   "Tamil"                                                                            => "tam",   "Tatar"                                                                            => "tat",   "Telugu"                                                                           => "tel",   "Tereno"                                                                           => "ter",   "Tetum"                                                                            => "tet",   "Thai"                                                                             => "tha",   "Tibetan"                                                                          => "bod",   "Tigre"                                                                            => "tig",   "Tigrinya"                                                                         => "tir",   "Timne"                                                                            => "tem",   "Tiv"                                                                              => "tiv",   "Tlingit"                                                                          => "tli",   "Tok Pisin"                                                                        => "tpi",   "Tokelau"                                                                          => "tkl",   "Tonga (Nyasa)"                                                                    => "tog",   "Tonga (Tonga Islands)"                                                            => "ton",   "Tsimshian"                                                                        => "tsi",   "Tsonga"                                                                           => "tso",   "Tswana"                                                                           => "tsn",   "Tumbuka"                                                                          => "tum",   "Tupi languages"                                                                   => "tup",   "Turkish"                                                                          => "tur",   "Turkish, Ottoman (1500-1928)"                                                     => "ota",   "Turkmen"                                                                          => "tuk",   "Tuvalu"                                                                           => "tvl",   "Tuvinian"                                                                         => "tyv",   "Twi"                                                                              => "twi",   "Udmurt"                                                                           => "udm",   "Ugaritic"                                                                         => "uga",   "Uighur; Uyghur"                                                                   => "uig",   "Ukrainian"                                                                        => "ukr",   "Umbundu"                                                                          => "umb",   "Uncoded languages"                                                                => "mis",   "Undetermined"                                                                     => "und",   "Upper Sorbian"                                                                    => "hsb",   "Urdu"                                                                             => "urd",   "Uzbek"                                                                            => "uzb",   "Vai"                                                                              => "vai",   "Venda"                                                                            => "ven",   "Vietnamese"                                                                       => "vie",   "Volap\xFCk"                                                                       => "vol",   "Votic"                                                                            => "vot",   "Wakashan languages"                                                               => "wak",   "Walloon"                                                                          => "wln",   "Waray"                                                                            => "war",   "Washo"                                                                            => "was",   "Welsh"                                                                            => "cym",   "Western Frisian"                                                                  => "fry",   "Wolaitta; Wolaytta"                                                               => "wal",   "Wolof"                                                                            => "wol",   "Xhosa"                                                                            => "xho",   "Yakut"                                                                            => "sah",   "Yao"                                                                              => "yao",   "Yapese"                                                                           => "yap",   "Yiddish"                                                                          => "yid",   "Yoruba"                                                                           => "yor",   "Yupik languages"                                                                  => "ypk",   "Zande languages"                                                                  => "znd",   "Zapotec"                                                                          => "zap",   "Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki"                                   => "zza",   "Zenaga"                                                                           => "zen",   "Zhuang; Chuang"                                                                   => "zha",   "Zulu"                                                                             => "zul",   "Zuni"                                                                             => "zun", }}

# Raw data from inside table goes here
sub raw {<<END}
  </tr><tr valign="top">
    <td scope="row">aar</td>
    <td>aa</td>
    <td>Afar</td>
    <td>afar</td>
    <td>Danakil-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">abk</td>
    <td>ab</td>
    <td>Abkhazian</td>
    <td>abkhaze</td>
    <td>Abchasisch</td>
    </tr><tr valign="top">
    <td scope="row">ace</td>
    <td>&nbsp;</td>
    <td>Achinese</td>
    <td>aceh</td>
    <td>Aceh-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ach</td>
    <td>&nbsp;</td>
    <td>Acoli</td>
    <td>acoli</td>
    <td>Acholi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ada</td>
    <td>&nbsp;</td>
    <td>Adangme</td>
    <td>adangme</td>
    <td>Adangme-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ady</td>
    <td>&nbsp;</td>
    <td>Adyghe; Adygei</td>
    <td>adyghé</td>
    <td>Adygisch</td>
    </tr><tr valign="top">
    <td scope="row">afa</td>
    <td>&nbsp;</td>
    <td>Afro-Asiatic languages</td>
    <td>afro-asiatiques, langues</td>
    <td>Hamitosemitische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">afh</td>
    <td>&nbsp;</td>
    <td>Afrihili</td>
    <td>afrihili</td>
    <td>Afrihili</td>
    </tr><tr valign="top">
    <td scope="row">afr</td>
    <td>af</td>
    <td>Afrikaans</td>
    <td>afrikaans</td>
    <td>Afrikaans</td>
    </tr><tr valign="top">
    <td scope="row">ain</td>
    <td>&nbsp;</td>
    <td>Ainu</td>
    <td>aïnou</td>
    <td>Ainu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">aka</td>
    <td>ak</td>
    <td>Akan</td>
    <td>akan</td>
    <td>Akan-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">akk</td>
    <td>&nbsp;</td>
    <td>Akkadian</td>
    <td>akkadien</td>
    <td>Akkadisch</td>
    </tr><tr valign="top">
    <td scope="row">alb (B)<br>sqi (T)</td>
    <td>sq</td>
    <td>Albanian</td>
    <td>albanais</td>
    <td>Albanisch</td>
    </tr><tr valign="top">
    <td scope="row">ale</td>
    <td>&nbsp;</td>
    <td>Aleut</td>
    <td>aléoute</td>
    <td>Aleutisch</td>
    </tr><tr valign="top">
    <td scope="row">alg</td>
    <td>&nbsp;</td>
    <td>Algonquian languages</td>
    <td>algonquines, langues</td>
    <td>Algonkin-Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">alt</td>
    <td>&nbsp;</td>
    <td>Southern Altai</td>
    <td>altai du Sud</td>
    <td>Altaisch</td>
    </tr><tr valign="top">
    <td scope="row">amh</td>
    <td>am</td>
    <td>Amharic</td>
    <td>amharique</td>
    <td>Amharisch</td>
    </tr><tr valign="top">
    <td scope="row">ang</td>
    <td>&nbsp;</td>
    <td>English, Old (ca.450-1100)</td>
    <td>anglo-saxon (ca.450-1100)</td>
    <td>Altenglisch</td>
    </tr><tr valign="top">
    <td scope="row">anp</td>
    <td>&nbsp;</td>
    <td>Angika</td>
    <td>angika</td>
    <td>Anga-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">apa</td>
    <td>&nbsp;</td>
    <td>Apache languages</td>
    <td>apaches, langues</td>
    <td>Apachen-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">ara</td>
    <td>ar</td>
    <td>Arabic</td>
    <td>arabe</td>
    <td>Arabisch</td>
    </tr><tr valign="top">
    <td scope="row">arc</td>
    <td>&nbsp;</td>
    <td>Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)</td>
    <td>araméen d'empire (700-300 BCE)</td>
    <td>Aramäisch</td>
    </tr><tr valign="top">
    <td scope="row">arg</td>
    <td>an</td>
    <td>Aragonese</td>
    <td>aragonais</td>
    <td>Aragonesisch</td>
    </tr><tr valign="top">
    <td scope="row">arm (B)<br>hye (T)</td>
    <td>hy</td>
    <td>Armenian</td>
    <td>arménien</td>
    <td>Armenisch</td>
    </tr><tr valign="top">
    <td scope="row">arn</td>
    <td>&nbsp;</td>
    <td>Mapudungun; Mapuche</td>
    <td>mapudungun; mapuche; mapuce</td>
    <td>Arauka-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">arp</td>
    <td>&nbsp;</td>
    <td>Arapaho</td>
    <td>arapaho</td>
    <td>Arapaho-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">art</td>
    <td>&nbsp;</td>
    <td>Artificial languages</td>
    <td>artificielles, langues</td>
    <td>Kunstsprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">arw</td>
    <td>&nbsp;</td>
    <td>Arawak</td>
    <td>arawak</td>
    <td>Arawak-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">asm</td>
    <td>as</td>
    <td>Assamese</td>
    <td>assamais</td>
    <td>Assamesisch</td>
    </tr><tr valign="top">
    <td scope="row">ast</td>
    <td>&nbsp;</td>
    <td>Asturian; Bable; Leonese; Asturleonese</td>
    <td>asturien; bable; léonais; asturoléonais</td>
    <td>Asturisch</td>
    </tr><tr valign="top">
    <td scope="row">ath</td>
    <td>&nbsp;</td>
    <td>Athapascan languages</td>
    <td>athapascanes, langues</td>
    <td>Athapaskische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">aus</td>
    <td>&nbsp;</td>
    <td>Australian languages</td>
    <td>australiennes, langues</td>
    <td>Australische Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">ava</td>
    <td>av</td>
    <td>Avaric</td>
    <td>avar</td>
    <td>Awarisch</td>
    </tr><tr valign="top">
    <td scope="row">ave</td>
    <td>ae</td>
    <td>Avestan</td>
    <td>avestique</td>
    <td>Avestisch</td>
    </tr><tr valign="top">
    <td scope="row">awa</td>
    <td>&nbsp;</td>
    <td>Awadhi</td>
    <td>awadhi</td>
    <td>Awadhi</td>
    </tr><tr valign="top">
    <td scope="row">aym</td>
    <td>ay</td>
    <td>Aymara</td>
    <td>aymara</td>
    <td>Aymará-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">aze</td>
    <td>az</td>
    <td>Azerbaijani</td>
    <td>azéri</td>
    <td>Aserbeidschanisch</td>
    </tr><tr valign="top">
    <td scope="row">bad</td>
    <td>&nbsp;</td>
    <td>Banda languages</td>
    <td>banda, langues</td>
    <td>Banda-Sprachen (Ubangi-Sprachen)</td>
    </tr><tr valign="top">
    <td scope="row">bai</td>
    <td>&nbsp;</td>
    <td>Bamileke languages</td>
    <td>bamiléké, langues</td>
    <td>Bamileke-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">bak</td>
    <td>ba</td>
    <td>Bashkir</td>
    <td>bachkir</td>
    <td>Baschkirisch</td>
    </tr><tr valign="top">
    <td scope="row">bal</td>
    <td>&nbsp;</td>
    <td>Baluchi</td>
    <td>baloutchi</td>
    <td>Belutschisch</td>
    </tr><tr valign="top">
    <td scope="row">bam</td>
    <td>bm</td>
    <td>Bambara</td>
    <td>bambara</td>
    <td>Bambara-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ban</td>
    <td>&nbsp;</td>
    <td>Balinese</td>
    <td>balinais</td>
    <td>Balinesisch</td>
    </tr><tr valign="top">
    <td scope="row">baq (B)<br>eus (T)</td>
    <td>eu</td>
    <td>Basque</td>
    <td>basque</td>
    <td>Baskisch</td>
    </tr><tr valign="top">
    <td scope="row">bas</td>
    <td>&nbsp;</td>
    <td>Basa</td>
    <td>basa</td>
    <td>Basaa-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bat</td>
    <td>&nbsp;</td>
    <td>Baltic languages</td>
    <td>baltes, langues</td>
    <td>Baltische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">bej</td>
    <td>&nbsp;</td>
    <td>Beja; Bedawiyet</td>
    <td>bedja</td>
    <td>Bedauye</td>
    </tr><tr valign="top">
    <td scope="row">bel</td>
    <td>be</td>
    <td>Belarusian</td>
    <td>biélorusse</td>
    <td>Weißrussisch</td>
    </tr><tr valign="top">
    <td scope="row">bem</td>
    <td>&nbsp;</td>
    <td>Bemba</td>
    <td>bemba</td>
    <td>Bemba-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ben</td>
    <td>bn</td>
    <td>Bengali</td>
    <td>bengali</td>
    <td>Bengali</td>
    </tr><tr valign="top">
    <td scope="row">ber</td>
    <td>&nbsp;</td>
    <td>Berber languages</td>
    <td>berbères, langues</td>
    <td>Berbersprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">bho</td>
    <td>&nbsp;</td>
    <td>Bhojpuri</td>
    <td>bhojpuri</td>
    <td>Bhojpuri</td>
    </tr><tr valign="top">
    <td scope="row">bih</td>
    <td>bh</td>
    <td>Bihari languages</td>
    <td>langues biharis</td>
    <td>Bihari (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">bik</td>
    <td>&nbsp;</td>
    <td>Bikol</td>
    <td>bikol</td>
    <td>Bikol-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bin</td>
    <td>&nbsp;</td>
    <td>Bini; Edo</td>
    <td>bini; edo</td>
    <td>Edo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bis</td>
    <td>bi</td>
    <td>Bislama</td>
    <td>bichlamar</td>
    <td>Beach-la-mar</td>
    </tr><tr valign="top">
    <td scope="row">bla</td>
    <td>&nbsp;</td>
    <td>Siksika</td>
    <td>blackfoot</td>
    <td>Blackfoot-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bnt</td>
    <td>&nbsp;</td>
    <td>Bantu languages</td>
    <td>bantou, langues</td>
    <td>Bantusprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">tib (B)<br>bod (T)</td>
    <td>bo</td>
    <td>Tibetan</td>
    <td>tibétain</td>
    <td>Tibetisch</td>
    </tr><tr valign="top">
    <td scope="row">bos</td>
    <td>bs</td>
    <td>Bosnian</td>
    <td>bosniaque</td>
    <td>Bosnisch</td>
    </tr><tr valign="top">
    <td scope="row">bra</td>
    <td>&nbsp;</td>
    <td>Braj</td>
    <td>braj</td>
    <td>Braj-Bhakha</td>
    </tr><tr valign="top">
    <td scope="row">bre</td>
    <td>br</td>
    <td>Breton</td>
    <td>breton</td>
    <td>Bretonisch</td>
    </tr><tr valign="top">
    <td scope="row">btk</td>
    <td>&nbsp;</td>
    <td>Batak languages</td>
    <td>batak, langues</td>
    <td>Batak-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bua</td>
    <td>&nbsp;</td>
    <td>Buriat</td>
    <td>bouriate</td>
    <td>Burjatisch</td>
    </tr><tr valign="top">
    <td scope="row">bug</td>
    <td>&nbsp;</td>
    <td>Buginese</td>
    <td>bugi</td>
    <td>Bugi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">bul</td>
    <td>bg</td>
    <td>Bulgarian</td>
    <td>bulgare</td>
    <td>Bulgarisch</td>
    </tr><tr valign="top">
    <td scope="row">bur (B)<br>mya (T)</td>
    <td>my</td>
    <td>Burmese</td>
    <td>birman</td>
    <td>Birmanisch</td>
    </tr><tr valign="top">
    <td scope="row">byn</td>
    <td>&nbsp;</td>
    <td>Blin; Bilin</td>
    <td>blin; bilen</td>
    <td>Bilin-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">cad</td>
    <td>&nbsp;</td>
    <td>Caddo</td>
    <td>caddo</td>
    <td>Caddo-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">cai</td>
    <td>&nbsp;</td>
    <td>Central American Indian languages</td>
    <td>amérindiennes de l'Amérique centrale,  langues</td>
    <td>Indianersprachen, Zentralamerika (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">car</td>
    <td>&nbsp;</td>
    <td>Galibi Carib</td>
    <td>karib; galibi; carib</td>
    <td>Karibische Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">cat</td>
    <td>ca</td>
    <td>Catalan; Valencian</td>
    <td>catalan; valencien</td>
    <td>Katalanisch</td>
    </tr><tr valign="top">
    <td scope="row">cau</td>
    <td>&nbsp;</td>
    <td>Caucasian languages</td>
    <td>caucasiennes, langues</td>
    <td>Kaukasische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">ceb</td>
    <td>&nbsp;</td>
    <td>Cebuano</td>
    <td>cebuano</td>
    <td>Cebuano</td>
    </tr><tr valign="top">
    <td scope="row">cel</td>
    <td>&nbsp;</td>
    <td>Celtic languages</td>
    <td>celtiques, langues; celtes, langues</td>
    <td>Keltische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">cze (B)<br>ces (T)</td>
    <td>cs</td>
    <td>Czech</td>
    <td>tchèque</td>
    <td>Tschechisch</td>
    </tr><tr valign="top">
    <td scope="row">cha</td>
    <td>ch</td>
    <td>Chamorro</td>
    <td>chamorro</td>
    <td>Chamorro-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">chb</td>
    <td>&nbsp;</td>
    <td>Chibcha</td>
    <td>chibcha</td>
    <td>Chibcha-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">che</td>
    <td>ce</td>
    <td>Chechen</td>
    <td>tchétchène</td>
    <td>Tschetschenisch</td>
    </tr><tr valign="top">
    <td scope="row">chg</td>
    <td>&nbsp;</td>
    <td>Chagatai</td>
    <td>djaghataï</td>
    <td>Tschagataisch</td>
    </tr><tr valign="top">
    <td scope="row">chi (B)<br>zho (T)</td>
    <td>zh</td>
    <td>Chinese</td>
    <td>chinois</td>
    <td>Chinesisch</td>
    </tr><tr valign="top">
    <td scope="row">chk</td>
    <td>&nbsp;</td>
    <td>Chuukese</td>
    <td>chuuk</td>
    <td>Trukesisch</td>
    </tr><tr valign="top">
    <td scope="row">chm</td>
    <td>&nbsp;</td>
    <td>Mari</td>
    <td>mari</td>
    <td>Tscheremissisch</td>
    </tr><tr valign="top">
    <td scope="row">chn</td>
    <td>&nbsp;</td>
    <td>Chinook jargon</td>
    <td>chinook, jargon</td>
    <td>Chinook-Jargon</td>
    </tr><tr valign="top">
    <td scope="row">cho</td>
    <td>&nbsp;</td>
    <td>Choctaw</td>
    <td>choctaw</td>
    <td>Choctaw-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">chp</td>
    <td>&nbsp;</td>
    <td>Chipewyan; Dene Suline</td>
    <td>chipewyan</td>
    <td>Chipewyan-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">chr</td>
    <td>&nbsp;</td>
    <td>Cherokee</td>
    <td>cherokee</td>
    <td>Cherokee-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">chu</td>
    <td>cu</td>
    <td>Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic</td>
    <td>slavon d'église; vieux slave; slavon liturgique; vieux bulgare</td>
    <td>Kirchenslawisch</td>
    </tr><tr valign="top">
    <td scope="row">chv</td>
    <td>cv</td>
    <td>Chuvash</td>
    <td>tchouvache</td>
    <td>Tschuwaschisch</td>
    </tr><tr valign="top">
    <td scope="row">chy</td>
    <td>&nbsp;</td>
    <td>Cheyenne</td>
    <td>cheyenne</td>
    <td>Cheyenne-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">cmc</td>
    <td>&nbsp;</td>
    <td>Chamic languages</td>
    <td>chames, langues</td>
    <td>Cham-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">cop</td>
    <td>&nbsp;</td>
    <td>Coptic</td>
    <td>copte</td>
    <td>Koptisch</td>
    </tr><tr valign="top">
    <td scope="row">cor</td>
    <td>kw</td>
    <td>Cornish</td>
    <td>cornique</td>
    <td>Kornisch</td>
    </tr><tr valign="top">
    <td scope="row">cos</td>
    <td>co</td>
    <td>Corsican</td>
    <td>corse</td>
    <td>Korsisch</td>
    </tr><tr valign="top">
    <td scope="row">cpe</td>
    <td>&nbsp;</td>
    <td>Creoles and pidgins, English based</td>
    <td>créoles et pidgins basés sur l'anglais</td>
    <td>Kreolisch-Englisch (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">cpf</td>
    <td>&nbsp;</td>
    <td>Creoles and pidgins, French-based</td>
    <td>créoles et pidgins basés sur le français</td>
    <td>Kreolisch-Französisch (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">cpp</td>
    <td>&nbsp;</td>
    <td>Creoles and pidgins, Portuguese-based</td>
    <td>créoles et pidgins basés sur le portugais</td>
    <td>Kreolisch-Portugiesisch (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">cre</td>
    <td>cr</td>
    <td>Cree</td>
    <td>cree</td>
    <td>Cree-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">crh</td>
    <td>&nbsp;</td>
    <td>Crimean Tatar; Crimean Turkish</td>
    <td>tatar de Crimé</td>
    <td>Krimtatarisch</td>
    </tr><tr valign="top">
    <td scope="row">crp</td>
    <td>&nbsp;</td>
    <td>Creoles and pidgins</td>
    <td>créoles et pidgins</td>
    <td>Kreolische Sprachen; Pidginsprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">csb</td>
    <td>&nbsp;</td>
    <td>Kashubian</td>
    <td>kachoube</td>
    <td>Kaschubisch</td>
    </tr><tr valign="top">
    <td scope="row">cus</td>
    <td>&nbsp;</td>
    <td>Cushitic languages</td>
    <td>couchitiques,  langues</td>
    <td>Kuschitische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">wel (B)<br>cym (T)</td>
    <td>cy</td>
    <td>Welsh</td>
    <td>gallois</td>
    <td>Kymrisch</td>
    </tr><tr valign="top">
    <td scope="row">cze (B)<br>ces (T)</td>
    <td>cs</td>
    <td>Czech</td>
    <td>tchèque</td>
    <td>Tschechisch</td>
    </tr><tr valign="top">
    <td scope="row">dak</td>
    <td>&nbsp;</td>
    <td>Dakota</td>
    <td>dakota</td>
    <td>Dakota-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">dan</td>
    <td>da</td>
    <td>Danish</td>
    <td>danois</td>
    <td>Dänisch</td>
    </tr><tr valign="top">
    <td scope="row">dar</td>
    <td>&nbsp;</td>
    <td>Dargwa</td>
    <td>dargwa</td>
    <td>Darginisch</td>
    </tr><tr valign="top">
    <td scope="row">day</td>
    <td>&nbsp;</td>
    <td>Land Dayak languages</td>
    <td>dayak, langues</td>
    <td>Dajakisch</td>
    </tr><tr valign="top">
    <td scope="row">del</td>
    <td>&nbsp;</td>
    <td>Delaware</td>
    <td>delaware</td>
    <td>Delaware-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">den</td>
    <td>&nbsp;</td>
    <td>Slave (Athapascan)</td>
    <td>esclave (athapascan)</td>
    <td>Slave-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ger (B)<br>deu (T)</td>
    <td>de</td>
    <td>German</td>
    <td>allemand</td>
    <td>Deutsch</td>
    </tr><tr valign="top">
    <td scope="row">dgr</td>
    <td>&nbsp;</td>
    <td>Dogrib</td>
    <td>dogrib</td>
    <td>Dogrib-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">din</td>
    <td>&nbsp;</td>
    <td>Dinka</td>
    <td>dinka</td>
    <td>Dinka-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">div</td>
    <td>dv</td>
    <td>Divehi; Dhivehi; Maldivian</td>
    <td>maldivien</td>
    <td>Maledivisch</td>
    </tr><tr valign="top">
    <td scope="row">doi</td>
    <td>&nbsp;</td>
    <td>Dogri</td>
    <td>dogri</td>
    <td>Dogri</td>
    </tr><tr valign="top">
    <td scope="row">dra</td>
    <td>&nbsp;</td>
    <td>Dravidian languages</td>
    <td>dravidiennes,  langues</td>
    <td>Drawidische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">dsb</td>
    <td>&nbsp;</td>
    <td>Lower Sorbian</td>
    <td>bas-sorabe</td>
    <td>Niedersorbisch</td>
    </tr><tr valign="top">
    <td scope="row">dua</td>
    <td>&nbsp;</td>
    <td>Duala</td>
    <td>douala</td>
    <td>Duala-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">dum</td>
    <td>&nbsp;</td>
    <td>Dutch, Middle (ca.1050-1350)</td>
    <td>néerlandais moyen (ca. 1050-1350)</td>
    <td>Mittelniederländisch</td>
    </tr><tr valign="top">
    <td scope="row">dut (B)<br>nld (T)</td>
    <td>nl</td>
    <td>Dutch; Flemish</td>
    <td>néerlandais; flamand</td>
    <td>Niederländisch</td>
    </tr><tr valign="top">
    <td scope="row">dyu</td>
    <td>&nbsp;</td>
    <td>Dyula</td>
    <td>dioula</td>
    <td>Dyula-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">dzo</td>
    <td>dz</td>
    <td>Dzongkha</td>
    <td>dzongkha</td>
    <td>Dzongkha</td>
    </tr><tr valign="top">
    <td scope="row">efi</td>
    <td>&nbsp;</td>
    <td>Efik</td>
    <td>efik</td>
    <td>Efik</td>
    </tr><tr valign="top">
    <td scope="row">egy</td>
    <td>&nbsp;</td>
    <td>Egyptian (Ancient)</td>
    <td>égyptien</td>
    <td>Ägyptisch</td>
    </tr><tr valign="top">
    <td scope="row">eka</td>
    <td>&nbsp;</td>
    <td>Ekajuk</td>
    <td>ekajuk</td>
    <td>Ekajuk</td>
    </tr><tr valign="top">
    <td scope="row">gre (B)<br>ell (T)</td>
    <td>el</td>
    <td>Greek, Modern (1453-)</td>
    <td>grec moderne (après 1453)</td>
    <td>Neugriechisch</td>
    </tr><tr valign="top">
    <td scope="row">elx</td>
    <td>&nbsp;</td>
    <td>Elamite</td>
    <td>élamite</td>
    <td>Elamisch</td>
    </tr><tr valign="top">
    <td scope="row">eng</td>
    <td>en</td>
    <td>English</td>
    <td>anglais</td>
    <td>Englisch</td>
    </tr><tr valign="top">
    <td scope="row">enm</td>
    <td>&nbsp;</td>
    <td>English, Middle (1100-1500)</td>
    <td>anglais moyen (1100-1500)</td>
    <td>Mittelenglisch</td>
    </tr><tr valign="top">
    <td scope="row">epo</td>
    <td>eo</td>
    <td>Esperanto</td>
    <td>espéranto</td>
    <td>Esperanto</td>
    </tr><tr valign="top">
    <td scope="row">est</td>
    <td>et</td>
    <td>Estonian</td>
    <td>estonien</td>
    <td>Estnisch</td>
    </tr><tr valign="top">
    <td scope="row">baq (B)<br>eus (T)</td>
    <td>eu</td>
    <td>Basque</td>
    <td>basque</td>
    <td>Baskisch</td>
    </tr><tr valign="top">
    <td scope="row">ewe</td>
    <td>ee</td>
    <td>Ewe</td>
    <td>éwé</td>
    <td>Ewe-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ewo</td>
    <td>&nbsp;</td>
    <td>Ewondo</td>
    <td>éwondo</td>
    <td>Ewondo</td>
    </tr><tr valign="top">
    <td scope="row">fan</td>
    <td>&nbsp;</td>
    <td>Fang</td>
    <td>fang</td>
    <td>Pangwe-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">fao</td>
    <td>fo</td>
    <td>Faroese</td>
    <td>féroïen</td>
    <td>Färöisch</td>
    </tr><tr valign="top">
    <td scope="row">per (B)<br>fas (T)</td>
    <td>fa</td>
    <td>Persian</td>
    <td>persan</td>
    <td>Persisch</td>
    </tr><tr valign="top">
    <td scope="row">fat</td>
    <td>&nbsp;</td>
    <td>Fanti</td>
    <td>fanti</td>
    <td>Fante-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">fij</td>
    <td>fj</td>
    <td>Fijian</td>
    <td>fidjien</td>
    <td>Fidschi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">fil</td>
    <td>&nbsp;</td>
    <td>Filipino; Pilipino</td>
    <td>filipino; pilipino</td>
    <td>Pilipino</td>
    </tr><tr valign="top">
    <td scope="row">fin</td>
    <td>fi</td>
    <td>Finnish</td>
    <td>finnois</td>
    <td>Finnisch</td>
    </tr><tr valign="top">
    <td scope="row">fiu</td>
    <td>&nbsp;</td>
    <td>Finno-Ugrian languages</td>
    <td>finno-ougriennes,  langues</td>
    <td>Finnougrische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">fon</td>
    <td>&nbsp;</td>
    <td>Fon</td>
    <td>fon</td>
    <td>Fon-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">fre (B)<br>fra (T)</td>
    <td>fr</td>
    <td>French</td>
    <td>français</td>
    <td>Französisch</td>
    </tr><tr valign="top">
    <td scope="row">fre (B)<br>fra (T)</td>
    <td>fr</td>
    <td>French</td>
    <td>français</td>
    <td>Französisch</td>
    </tr><tr valign="top">
    <td scope="row">frm</td>
    <td>&nbsp;</td>
    <td>French, Middle (ca.1400-1600)</td>
    <td>français moyen (1400-1600)</td>
    <td>Mittelfranzösisch</td>
    </tr><tr valign="top">
    <td scope="row">fro</td>
    <td>&nbsp;</td>
    <td>French, Old (842-ca.1400)</td>
    <td>français ancien (842-ca.1400)</td>
    <td>Altfranzösisch</td>
    </tr><tr valign="top">
    <td scope="row">frr</td>
    <td>&nbsp;</td>
    <td>Northern Frisian</td>
    <td>frison septentrional</td>
    <td>Nordfriesisch</td>
    </tr><tr valign="top">
    <td scope="row">frs</td>
    <td>&nbsp;</td>
    <td>Eastern Frisian</td>
    <td>frison oriental</td>
    <td>Ostfriesisch</td>
    </tr><tr valign="top">
    <td scope="row">fry</td>
    <td>fy</td>
    <td>Western Frisian</td>
    <td>frison occidental</td>
    <td>Friesisch</td>
    </tr><tr valign="top">
    <td scope="row">ful</td>
    <td>ff</td>
    <td>Fulah</td>
    <td>peul</td>
    <td>Ful</td>
    </tr><tr valign="top">
    <td scope="row">fur</td>
    <td>&nbsp;</td>
    <td>Friulian</td>
    <td>frioulan</td>
    <td>Friulisch</td>
    </tr><tr valign="top">
    <td scope="row">gaa</td>
    <td>&nbsp;</td>
    <td>Ga</td>
    <td>ga</td>
    <td>Ga-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gay</td>
    <td>&nbsp;</td>
    <td>Gayo</td>
    <td>gayo</td>
    <td>Gayo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gba</td>
    <td>&nbsp;</td>
    <td>Gbaya</td>
    <td>gbaya</td>
    <td>Gbaya-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gem</td>
    <td>&nbsp;</td>
    <td>Germanic languages</td>
    <td>germaniques, langues</td>
    <td>Germanische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">geo (B)<br>kat (T)</td>
    <td>ka</td>
    <td>Georgian</td>
    <td>géorgien</td>
    <td>Georgisch</td>
    </tr><tr valign="top">
    <td scope="row">ger (B)<br>deu (T)</td>
    <td>de</td>
    <td>German</td>
    <td>allemand</td>
    <td>Deutsch</td>
    </tr><tr valign="top">
    <td scope="row">gez</td>
    <td>&nbsp;</td>
    <td>Geez</td>
    <td>guèze</td>
    <td>Altäthiopisch</td>
    </tr><tr valign="top">
    <td scope="row">gil</td>
    <td>&nbsp;</td>
    <td>Gilbertese</td>
    <td>kiribati</td>
    <td>Gilbertesisch</td>
    </tr><tr valign="top">
    <td scope="row">gla</td>
    <td>gd</td>
    <td>Gaelic; Scottish Gaelic</td>
    <td>gaélique; gaélique écossais</td>
    <td>Gälisch-Schottisch</td>
    </tr><tr valign="top">
    <td scope="row">gle</td>
    <td>ga</td>
    <td>Irish</td>
    <td>irlandais</td>
    <td>Irisch</td>
    </tr><tr valign="top">
    <td scope="row">glg</td>
    <td>gl</td>
    <td>Galician</td>
    <td>galicien</td>
    <td>Galicisch</td>
    </tr><tr valign="top">
    <td scope="row">glv</td>
    <td>gv</td>
    <td>Manx</td>
    <td>manx; mannois</td>
    <td>Manx</td>
    </tr><tr valign="top">
    <td scope="row">gmh</td>
    <td>&nbsp;</td>
    <td>German, Middle High (ca.1050-1500)</td>
    <td>allemand, moyen haut (ca. 1050-1500)</td>
    <td>Mittelhochdeutsch</td>
    </tr><tr valign="top">
    <td scope="row">goh</td>
    <td>&nbsp;</td>
    <td>German, Old High (ca.750-1050)</td>
    <td>allemand, vieux haut (ca. 750-1050)</td>
    <td>Althochdeutsch</td>
    </tr><tr valign="top">
    <td scope="row">gon</td>
    <td>&nbsp;</td>
    <td>Gondi</td>
    <td>gond</td>
    <td>Gondi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gor</td>
    <td>&nbsp;</td>
    <td>Gorontalo</td>
    <td>gorontalo</td>
    <td>Gorontalesisch</td>
    </tr><tr valign="top">
    <td scope="row">got</td>
    <td>&nbsp;</td>
    <td>Gothic</td>
    <td>gothique</td>
    <td>Gotisch</td>
    </tr><tr valign="top">
    <td scope="row">grb</td>
    <td>&nbsp;</td>
    <td>Grebo</td>
    <td>grebo</td>
    <td>Grebo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">grc</td>
    <td>&nbsp;</td>
    <td>Greek, Ancient (to 1453)</td>
    <td>grec ancien (jusqu'à 1453)</td>
    <td>Griechisch</td>
    </tr><tr valign="top">
    <td scope="row">gre (B)<br>ell (T)</td>
    <td>el</td>
    <td>Greek, Modern (1453-)</td>
    <td>grec moderne (après 1453)</td>
    <td>Neugriechisch</td>
    </tr><tr valign="top">
    <td scope="row">grn</td>
    <td>gn</td>
    <td>Guarani</td>
    <td>guarani</td>
    <td>Guaraní-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gsw</td>
    <td>&nbsp;</td>
    <td>Swiss German; Alemannic; Alsatian</td>
    <td>suisse alémanique; alémanique; alsacien</td>
    <td>Schweizerdeutsch</td>
    </tr><tr valign="top">
    <td scope="row">guj</td>
    <td>gu</td>
    <td>Gujarati</td>
    <td>goudjrati</td>
    <td>Gujarati-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">gwi</td>
    <td>&nbsp;</td>
    <td>Gwich'in</td>
    <td>gwich'in</td>
    <td>Kutchin-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">hai</td>
    <td>&nbsp;</td>
    <td>Haida</td>
    <td>haida</td>
    <td>Haida-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">hat</td>
    <td>ht</td>
    <td>Haitian; Haitian Creole</td>
    <td>haïtien; créole haïtien</td>
    <td>Haïtien (Haiti-Kreolisch)</td>
    </tr><tr valign="top">
    <td scope="row">hau</td>
    <td>ha</td>
    <td>Hausa</td>
    <td>haoussa</td>
    <td>Haussa-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">haw</td>
    <td>&nbsp;</td>
    <td>Hawaiian</td>
    <td>hawaïen</td>
    <td>Hawaiisch</td>
    </tr><tr valign="top">
    <td scope="row">heb</td>
    <td>he</td>
    <td>Hebrew</td>
    <td>hébreu</td>
    <td>Hebräisch</td>
    </tr><tr valign="top">
    <td scope="row">her</td>
    <td>hz</td>
    <td>Herero</td>
    <td>herero</td>
    <td>Herero-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">hil</td>
    <td>&nbsp;</td>
    <td>Hiligaynon</td>
    <td>hiligaynon</td>
    <td>Hiligaynon-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">him</td>
    <td>&nbsp;</td>
    <td>Himachali languages; Western Pahari languages</td>
    <td>langues himachalis; langues paharis occidentales</td>
    <td>Himachali</td>
    </tr><tr valign="top">
    <td scope="row">hin</td>
    <td>hi</td>
    <td>Hindi</td>
    <td>hindi</td>
    <td>Hindi</td>
    </tr><tr valign="top">
    <td scope="row">hit</td>
    <td>&nbsp;</td>
    <td>Hittite</td>
    <td>hittite</td>
    <td>Hethitisch</td>
    </tr><tr valign="top">
    <td scope="row">hmn</td>
    <td>&nbsp;</td>
    <td>Hmong; Mong</td>
    <td>hmong</td>
    <td>Miao-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">hmo</td>
    <td>ho</td>
    <td>Hiri Motu</td>
    <td>hiri motu</td>
    <td>Hiri-Motu</td>
    </tr><tr valign="top">
    <td scope="row">hrv</td>
    <td>hr</td>
    <td>Croatian</td>
    <td>croate</td>
    <td>Kroatisch </td>
    </tr><tr valign="top">
    <td scope="row">hsb</td>
    <td>&nbsp;</td>
    <td>Upper Sorbian</td>
    <td>haut-sorabe</td>
    <td>Obersorbisch</td>
    </tr><tr valign="top">
    <td scope="row">hun</td>
    <td>hu</td>
    <td>Hungarian</td>
    <td>hongrois</td>
    <td>Ungarisch</td>
    </tr><tr valign="top">
    <td scope="row">hup</td>
    <td>&nbsp;</td>
    <td>Hupa</td>
    <td>hupa</td>
    <td>Hupa-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">arm (B)<br>hye (T)</td>
    <td>hy</td>
    <td>Armenian</td>
    <td>arménien</td>
    <td>Armenisch</td>
    </tr><tr valign="top">
    <td scope="row">iba</td>
    <td>&nbsp;</td>
    <td>Iban</td>
    <td>iban</td>
    <td>Iban-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ibo</td>
    <td>ig</td>
    <td>Igbo</td>
    <td>igbo</td>
    <td>Ibo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ice (B)<br>isl (T)</td>
    <td>is</td>
    <td>Icelandic</td>
    <td>islandais</td>
    <td>Isländisch</td>
    </tr><tr valign="top">
    <td scope="row">ido</td>
    <td>io</td>
    <td>Ido</td>
    <td>ido</td>
    <td>Ido</td>
    </tr><tr valign="top">
    <td scope="row">iii</td>
    <td>ii</td>
    <td>Sichuan Yi; Nuosu</td>
    <td>yi de Sichuan</td>
    <td>Lalo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ijo</td>
    <td>&nbsp;</td>
    <td>Ijo languages</td>
    <td>ijo, langues</td>
    <td>Ijo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">iku</td>
    <td>iu</td>
    <td>Inuktitut</td>
    <td>inuktitut</td>
    <td>Inuktitut</td>
    </tr><tr valign="top">
    <td scope="row">ile</td>
    <td>ie</td>
    <td>Interlingue; Occidental</td>
    <td>interlingue</td>
    <td>Interlingue</td>
    </tr><tr valign="top">
    <td scope="row">ilo</td>
    <td>&nbsp;</td>
    <td>Iloko</td>
    <td>ilocano</td>
    <td>Ilokano-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ina</td>
    <td>ia</td>
    <td>Interlingua (International Auxiliary Language Association)</td>
    <td>interlingua (langue auxiliaire internationale)</td>
    <td>Interlingua</td>
    </tr><tr valign="top">
    <td scope="row">inc</td>
    <td>&nbsp;</td>
    <td>Indic languages</td>
    <td>indo-aryennes, langues</td>
    <td>Indoarische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">ind</td>
    <td>id</td>
    <td>Indonesian</td>
    <td>indonésien</td>
    <td>Bahasa Indonesia</td>
    </tr><tr valign="top">
    <td scope="row">ine</td>
    <td>&nbsp;</td>
    <td>Indo-European languages</td>
    <td>indo-européennes, langues</td>
    <td>Indogermanische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">inh</td>
    <td>&nbsp;</td>
    <td>Ingush</td>
    <td>ingouche</td>
    <td>Inguschisch</td>
    </tr><tr valign="top">
    <td scope="row">ipk</td>
    <td>ik</td>
    <td>Inupiaq</td>
    <td>inupiaq</td>
    <td>Inupik</td>
    </tr><tr valign="top">
    <td scope="row">ira</td>
    <td>&nbsp;</td>
    <td>Iranian languages</td>
    <td>iraniennes, langues</td>
    <td>Iranische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">iro</td>
    <td>&nbsp;</td>
    <td>Iroquoian languages</td>
    <td>iroquoises, langues</td>
    <td>Irokesische Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">ice (B)<br>isl (T)</td>
    <td>is</td>
    <td>Icelandic</td>
    <td>islandais</td>
    <td>Isländisch</td>
    </tr><tr valign="top">
    <td scope="row">ita</td>
    <td>it</td>
    <td>Italian</td>
    <td>italien</td>
    <td>Italienisch</td>
    </tr><tr valign="top">
    <td scope="row">jav</td>
    <td>jv</td>
    <td>Javanese</td>
    <td>javanais</td>
    <td>Javanisch</td>
    </tr><tr valign="top">
    <td scope="row">jbo</td>
    <td>&nbsp;</td>
    <td>Lojban</td>
    <td>lojban</td>
    <td>Lojban</td>
    </tr><tr valign="top">
    <td scope="row">jpn</td>
    <td>ja</td>
    <td>Japanese</td>
    <td>japonais</td>
    <td>Japanisch</td>
    </tr><tr valign="top">
    <td scope="row">jpr</td>
    <td>&nbsp;</td>
    <td>Judeo-Persian</td>
    <td>judéo-persan</td>
    <td>Jüdisch-Persisch</td>
    </tr><tr valign="top">
    <td scope="row">jrb</td>
    <td>&nbsp;</td>
    <td>Judeo-Arabic</td>
    <td>judéo-arabe</td>
    <td>Jüdisch-Arabisch</td>
    </tr><tr valign="top">
    <td scope="row">kaa</td>
    <td>&nbsp;</td>
    <td>Kara-Kalpak</td>
    <td>karakalpak</td>
    <td>Karakalpakisch</td>
    </tr><tr valign="top">
    <td scope="row">kab</td>
    <td>&nbsp;</td>
    <td>Kabyle</td>
    <td>kabyle</td>
    <td>Kabylisch</td>
    </tr><tr valign="top">
    <td scope="row">kac</td>
    <td>&nbsp;</td>
    <td>Kachin; Jingpho</td>
    <td>kachin; jingpho</td>
    <td>Kachin-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kal</td>
    <td>kl</td>
    <td>Kalaallisut; Greenlandic</td>
    <td>groenlandais</td>
    <td>Grönländisch</td>
    </tr><tr valign="top">
    <td scope="row">kam</td>
    <td>&nbsp;</td>
    <td>Kamba</td>
    <td>kamba</td>
    <td>Kamba-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kan</td>
    <td>kn</td>
    <td>Kannada</td>
    <td>kannada</td>
    <td>Kannada</td>
    </tr><tr valign="top">
    <td scope="row">kar</td>
    <td>&nbsp;</td>
    <td>Karen languages</td>
    <td>karen, langues</td>
    <td>Karenisch</td>
    </tr><tr valign="top">
    <td scope="row">kas</td>
    <td>ks</td>
    <td>Kashmiri</td>
    <td>kashmiri</td>
    <td>Kaschmiri</td>
    </tr><tr valign="top">
    <td scope="row">geo (B)<br>kat (T)</td>
    <td>ka</td>
    <td>Georgian</td>
    <td>géorgien</td>
    <td>Georgisch</td>
    </tr><tr valign="top">
    <td scope="row">kau</td>
    <td>kr</td>
    <td>Kanuri</td>
    <td>kanouri</td>
    <td>Kanuri-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kaw</td>
    <td>&nbsp;</td>
    <td>Kawi</td>
    <td>kawi</td>
    <td>Kawi</td>
    </tr><tr valign="top">
    <td scope="row">kaz</td>
    <td>kk</td>
    <td>Kazakh</td>
    <td>kazakh</td>
    <td>Kasachisch</td>
    </tr><tr valign="top">
    <td scope="row">kbd</td>
    <td>&nbsp;</td>
    <td>Kabardian</td>
    <td>kabardien</td>
    <td>Kabardinisch</td>
    </tr><tr valign="top">
    <td scope="row">kha</td>
    <td>&nbsp;</td>
    <td>Khasi</td>
    <td>khasi</td>
    <td>Khasi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">khi</td>
    <td>&nbsp;</td>
    <td>Khoisan languages</td>
    <td>khoïsan, langues</td>
    <td>Khoisan-Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">khm</td>
    <td>km</td>
    <td>Central Khmer</td>
    <td>khmer central</td>
    <td>Kambodschanisch</td>
    </tr><tr valign="top">
    <td scope="row">kho</td>
    <td>&nbsp;</td>
    <td>Khotanese; Sakan</td>
    <td>khotanais; sakan</td>
    <td>Sakisch</td>
    </tr><tr valign="top">
    <td scope="row">kik</td>
    <td>ki</td>
    <td>Kikuyu; Gikuyu</td>
    <td>kikuyu</td>
    <td>Kikuyu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kin</td>
    <td>rw</td>
    <td>Kinyarwanda</td>
    <td>rwanda</td>
    <td>Rwanda-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kir</td>
    <td>ky</td>
    <td>Kirghiz; Kyrgyz</td>
    <td>kirghiz</td>
    <td>Kirgisisch</td>
    </tr><tr valign="top">
    <td scope="row">kmb</td>
    <td>&nbsp;</td>
    <td>Kimbundu</td>
    <td>kimbundu</td>
    <td>Kimbundu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kok</td>
    <td>&nbsp;</td>
    <td>Konkani</td>
    <td>konkani</td>
    <td>Konkani</td>
    </tr><tr valign="top">
    <td scope="row">kom</td>
    <td>kv</td>
    <td>Komi</td>
    <td>kom</td>
    <td>Komi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kon</td>
    <td>kg</td>
    <td>Kongo</td>
    <td>kongo</td>
    <td>Kongo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kor</td>
    <td>ko</td>
    <td>Korean</td>
    <td>coréen</td>
    <td>Koreanisch</td>
    </tr><tr valign="top">
    <td scope="row">kos</td>
    <td>&nbsp;</td>
    <td>Kosraean</td>
    <td>kosrae</td>
    <td>Kosraeanisch</td>
    </tr><tr valign="top">
    <td scope="row">kpe</td>
    <td>&nbsp;</td>
    <td>Kpelle</td>
    <td>kpellé</td>
    <td>Kpelle-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">krc</td>
    <td>&nbsp;</td>
    <td>Karachay-Balkar</td>
    <td>karatchai balkar</td>
    <td>Karatschaiisch-Balkarisch</td>
    </tr><tr valign="top">
    <td scope="row">krl</td>
    <td>&nbsp;</td>
    <td>Karelian</td>
    <td>carélien</td>
    <td>Karelisch</td>
    </tr><tr valign="top">
    <td scope="row">kro</td>
    <td>&nbsp;</td>
    <td>Kru languages</td>
    <td>krou, langues</td>
    <td>Kru-Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">kru</td>
    <td>&nbsp;</td>
    <td>Kurukh</td>
    <td>kurukh</td>
    <td>Oraon-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kua</td>
    <td>kj</td>
    <td>Kuanyama; Kwanyama</td>
    <td>kuanyama; kwanyama</td>
    <td>Kwanyama-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">kum</td>
    <td>&nbsp;</td>
    <td>Kumyk</td>
    <td>koumyk</td>
    <td>Kumükisch</td>
    </tr><tr valign="top">
    <td scope="row">kur</td>
    <td>ku</td>
    <td>Kurdish</td>
    <td>kurde</td>
    <td>Kurdisch</td>
    </tr><tr valign="top">
    <td scope="row">kut</td>
    <td>&nbsp;</td>
    <td>Kutenai</td>
    <td>kutenai</td>
    <td>Kutenai-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lad</td>
    <td>&nbsp;</td>
    <td>Ladino</td>
    <td>judéo-espagnol</td>
    <td>Judenspanisch</td>
    </tr><tr valign="top">
    <td scope="row">lah</td>
    <td>&nbsp;</td>
    <td>Lahnda</td>
    <td>lahnda</td>
    <td>Lahnda</td>
    </tr><tr valign="top">
    <td scope="row">lam</td>
    <td>&nbsp;</td>
    <td>Lamba</td>
    <td>lamba</td>
    <td>Lamba-Sprache (Bantusprache)</td>
    </tr><tr valign="top">
    <td scope="row">lao</td>
    <td>lo</td>
    <td>Lao</td>
    <td>lao</td>
    <td>Laotisch</td>
    </tr><tr valign="top">
    <td scope="row">lat</td>
    <td>la</td>
    <td>Latin</td>
    <td>latin</td>
    <td>Latein</td>
    </tr><tr valign="top">
    <td scope="row">lav</td>
    <td>lv</td>
    <td>Latvian</td>
    <td>letton</td>
    <td>Lettisch</td>
    </tr><tr valign="top">
    <td scope="row">lez</td>
    <td>&nbsp;</td>
    <td>Lezghian</td>
    <td>lezghien</td>
    <td>Lesgisch</td>
    </tr><tr valign="top">
    <td scope="row">lim</td>
    <td>li</td>
    <td>Limburgan; Limburger; Limburgish</td>
    <td>limbourgeois</td>
    <td>Limburgisch</td>
    </tr><tr valign="top">
    <td scope="row">lin</td>
    <td>ln</td>
    <td>Lingala</td>
    <td>lingala</td>
    <td>Lingala</td>
    </tr><tr valign="top">
    <td scope="row">lit</td>
    <td>lt</td>
    <td>Lithuanian</td>
    <td>lituanien</td>
    <td>Litauisch</td>
    </tr><tr valign="top">
    <td scope="row">lol</td>
    <td>&nbsp;</td>
    <td>Mongo</td>
    <td>mongo</td>
    <td>Mongo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">loz</td>
    <td>&nbsp;</td>
    <td>Lozi</td>
    <td>lozi</td>
    <td>Rotse-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ltz</td>
    <td>lb</td>
    <td>Luxembourgish; Letzeburgesch</td>
    <td>luxembourgeois</td>
    <td>Luxemburgisch</td>
    </tr><tr valign="top">
    <td scope="row">lua</td>
    <td>&nbsp;</td>
    <td>Luba-Lulua</td>
    <td>luba-lulua</td>
    <td>Lulua-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lub</td>
    <td>lu</td>
    <td>Luba-Katanga</td>
    <td>luba-katanga</td>
    <td>Luba-Katanga-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lug</td>
    <td>lg</td>
    <td>Ganda</td>
    <td>ganda</td>
    <td>Ganda-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lui</td>
    <td>&nbsp;</td>
    <td>Luiseno</td>
    <td>luiseno</td>
    <td>Luiseño-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lun</td>
    <td>&nbsp;</td>
    <td>Lunda</td>
    <td>lunda</td>
    <td>Lunda-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">luo</td>
    <td>&nbsp;</td>
    <td>Luo (Kenya and Tanzania)</td>
    <td>luo (Kenya et Tanzanie)</td>
    <td>Luo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">lus</td>
    <td>&nbsp;</td>
    <td>Lushai</td>
    <td>lushai</td>
    <td>Lushai-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mac (B)<br>mkd (T)</td>
    <td>mk</td>
    <td>Macedonian</td>
    <td>macédonien</td>
    <td>Makedonisch</td>
    </tr><tr valign="top">
    <td scope="row">mad</td>
    <td>&nbsp;</td>
    <td>Madurese</td>
    <td>madourais</td>
    <td>Maduresisch</td>
    </tr><tr valign="top">
    <td scope="row">mag</td>
    <td>&nbsp;</td>
    <td>Magahi</td>
    <td>magahi</td>
    <td>Khotta</td>
    </tr><tr valign="top">
    <td scope="row">mah</td>
    <td>mh</td>
    <td>Marshallese</td>
    <td>marshall</td>
    <td>Marschallesisch</td>
    </tr><tr valign="top">
    <td scope="row">mai</td>
    <td>&nbsp;</td>
    <td>Maithili</td>
    <td>maithili</td>
    <td>Maithili</td>
    </tr><tr valign="top">
    <td scope="row">mak</td>
    <td>&nbsp;</td>
    <td>Makasar</td>
    <td>makassar</td>
    <td>Makassarisch</td>
    </tr><tr valign="top">
    <td scope="row">mal</td>
    <td>ml</td>
    <td>Malayalam</td>
    <td>malayalam</td>
    <td>Malayalam</td>
    </tr><tr valign="top">
    <td scope="row">man</td>
    <td>&nbsp;</td>
    <td>Mandingo</td>
    <td>mandingue</td>
    <td>Malinke-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mao (B)<br>mri (T)</td>
    <td>mi</td>
    <td>Maori</td>
    <td>maori</td>
    <td>Maori-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">map</td>
    <td>&nbsp;</td>
    <td>Austronesian languages</td>
    <td>austronésiennes, langues</td>
    <td>Austronesische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">mar</td>
    <td>mr</td>
    <td>Marathi</td>
    <td>marathe</td>
    <td>Marathi</td>
    </tr><tr valign="top">
    <td scope="row">mas</td>
    <td>&nbsp;</td>
    <td>Masai</td>
    <td>massaï</td>
    <td>Massai-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">may (B)<br>msa (T)</td>
    <td>ms</td>
    <td>Malay</td>
    <td>malais</td>
    <td>Malaiisch</td>
    </tr><tr valign="top">
    <td scope="row">mdf</td>
    <td>&nbsp;</td>
    <td>Moksha</td>
    <td>moksa</td>
    <td>Mokscha-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mdr</td>
    <td>&nbsp;</td>
    <td>Mandar</td>
    <td>mandar</td>
    <td>Mandaresisch</td>
    </tr><tr valign="top">
    <td scope="row">men</td>
    <td>&nbsp;</td>
    <td>Mende</td>
    <td>mendé</td>
    <td>Mende-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mga</td>
    <td>&nbsp;</td>
    <td>Irish, Middle (900-1200)</td>
    <td>irlandais moyen (900-1200)</td>
    <td>Mittelirisch</td>
    </tr><tr valign="top">
    <td scope="row">mic</td>
    <td>&nbsp;</td>
    <td>Mi'kmaq; Micmac</td>
    <td>mi'kmaq; micmac</td>
    <td>Micmac-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">min</td>
    <td>&nbsp;</td>
    <td>Minangkabau</td>
    <td>minangkabau</td>
    <td>Minangkabau-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mis</td>
    <td>&nbsp;</td>
    <td>Uncoded languages</td>
    <td>langues non codées</td>
    <td>Einzelne andere Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">mac (B)<br>mkd (T)</td>
    <td>mk</td>
    <td>Macedonian</td>
    <td>macédonien</td>
    <td>Makedonisch</td>
    </tr><tr valign="top">
    <td scope="row">mkh</td>
    <td>&nbsp;</td>
    <td>Mon-Khmer languages</td>
    <td>môn-khmer, langues</td>
    <td>Mon-Khmer-Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">mlg</td>
    <td>mg</td>
    <td>Malagasy</td>
    <td>malgache</td>
    <td>Malagassi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mlt</td>
    <td>mt</td>
    <td>Maltese</td>
    <td>maltais</td>
    <td>Maltesisch</td>
    </tr><tr valign="top">
    <td scope="row">mnc</td>
    <td>&nbsp;</td>
    <td>Manchu</td>
    <td>mandchou</td>
    <td>Mandschurisch</td>
    </tr><tr valign="top">
    <td scope="row">mni</td>
    <td>&nbsp;</td>
    <td>Manipuri</td>
    <td>manipuri</td>
    <td>Meithei-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mno</td>
    <td>&nbsp;</td>
    <td>Manobo languages</td>
    <td>manobo, langues</td>
    <td>Manobo-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">moh</td>
    <td>&nbsp;</td>
    <td>Mohawk</td>
    <td>mohawk</td>
    <td>Mohawk-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mon</td>
    <td>mn</td>
    <td>Mongolian</td>
    <td>mongol</td>
    <td>Mongolisch</td>
    </tr><tr valign="top">
    <td scope="row">mos</td>
    <td>&nbsp;</td>
    <td>Mossi</td>
    <td>moré</td>
    <td>Mossi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">mao (B)<br>mri (T)</td>
    <td>mi</td>
    <td>Maori</td>
    <td>maori</td>
    <td>Maori-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">may (B)<br>msa (T)</td>
    <td>ms</td>
    <td>Malay</td>
    <td>malais</td>
    <td>Malaiisch</td>
    </tr><tr valign="top">
    <td scope="row">mul</td>
    <td>&nbsp;</td>
    <td>Multiple languages</td>
    <td>multilingue</td>
    <td>Mehrere Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">mun</td>
    <td>&nbsp;</td>
    <td>Munda languages</td>
    <td>mounda, langues</td>
    <td>Mundasprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">mus</td>
    <td>&nbsp;</td>
    <td>Creek</td>
    <td>muskogee</td>
    <td>Muskogisch</td>
    </tr><tr valign="top">
    <td scope="row">mwl</td>
    <td>&nbsp;</td>
    <td>Mirandese</td>
    <td>mirandais</td>
    <td>Mirandesisch</td>
    </tr><tr valign="top">
    <td scope="row">mwr</td>
    <td>&nbsp;</td>
    <td>Marwari</td>
    <td>marvari</td>
    <td>Marwari</td>
    </tr><tr valign="top">
    <td scope="row">bur (B)<br>mya (T)</td>
    <td>my</td>
    <td>Burmese</td>
    <td>birman</td>
    <td>Birmanisch</td>
    </tr><tr valign="top">
    <td scope="row">myn</td>
    <td>&nbsp;</td>
    <td>Mayan languages</td>
    <td>maya, langues</td>
    <td>Maya-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">myv</td>
    <td>&nbsp;</td>
    <td>Erzya</td>
    <td>erza</td>
    <td>Erza-Mordwinisch</td>
    </tr><tr valign="top">
    <td scope="row">nah</td>
    <td>&nbsp;</td>
    <td>Nahuatl languages</td>
    <td>nahuatl, langues</td>
    <td>Nahuatl</td>
    </tr><tr valign="top">
    <td scope="row">nai</td>
    <td>&nbsp;</td>
    <td>North American Indian languages</td>
    <td>nord-amérindiennes, langues</td>
    <td>Indianersprachen, Nordamerika (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">nap</td>
    <td>&nbsp;</td>
    <td>Neapolitan</td>
    <td>napolitain</td>
    <td>Neapel / Mundart</td>
    </tr><tr valign="top">
    <td scope="row">nau</td>
    <td>na</td>
    <td>Nauru</td>
    <td>nauruan</td>
    <td>Nauruanisch</td>
    </tr><tr valign="top">
    <td scope="row">nav</td>
    <td>nv</td>
    <td>Navajo; Navaho</td>
    <td>navaho</td>
    <td>Navajo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nbl</td>
    <td>nr</td>
    <td>Ndebele, South; South Ndebele</td>
    <td>ndébélé du Sud</td>
    <td>Ndebele-Sprache (Transvaal)</td>
    </tr><tr valign="top">
    <td scope="row">nde</td>
    <td>nd</td>
    <td>Ndebele, North; North Ndebele</td>
    <td>ndébélé du Nord</td>
    <td>Ndebele-Sprache (Simbabwe)</td>
    </tr><tr valign="top">
    <td scope="row">ndo</td>
    <td>ng</td>
    <td>Ndonga</td>
    <td>ndonga</td>
    <td>Ndonga</td>
    </tr><tr valign="top">
    <td scope="row">nds</td>
    <td>&nbsp;</td>
    <td>Low German; Low Saxon; German, Low; Saxon, Low</td>
    <td>bas allemand; bas saxon; allemand, bas; saxon, bas</td>
    <td>Niederdeutsch</td>
    </tr><tr valign="top">
    <td scope="row">nep</td>
    <td>ne</td>
    <td>Nepali</td>
    <td>népalais</td>
    <td>Nepali</td>
    </tr><tr valign="top">
    <td scope="row">new</td>
    <td>&nbsp;</td>
    <td>Nepal Bhasa; Newari</td>
    <td>nepal bhasa; newari</td>
    <td>Newari</td>
    </tr><tr valign="top">
    <td scope="row">nia</td>
    <td>&nbsp;</td>
    <td>Nias</td>
    <td>nias</td>
    <td>Nias-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nic</td>
    <td>&nbsp;</td>
    <td>Niger-Kordofanian languages</td>
    <td>nigéro-kordofaniennes, langues</td>
    <td>Nigerkordofanische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">niu</td>
    <td>&nbsp;</td>
    <td>Niuean</td>
    <td>niué</td>
    <td>Niue-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">dut (B)<br>nld (T)</td>
    <td>nl</td>
    <td>Dutch; Flemish</td>
    <td>néerlandais; flamand</td>
    <td>Niederländisch</td>
    </tr><tr valign="top">
    <td scope="row">nno</td>
    <td>nn</td>
    <td>Norwegian Nynorsk; Nynorsk, Norwegian</td>
    <td>norvégien nynorsk; nynorsk, norvégien</td>
    <td>Nynorsk</td>
    </tr><tr valign="top">
    <td scope="row">nob</td>
    <td>nb</td>
    <td>Bokmål, Norwegian; Norwegian Bokmål</td>
    <td>norvégien bokmål</td>
    <td>Bokmål</td>
    </tr><tr valign="top">
    <td scope="row">nog</td>
    <td>&nbsp;</td>
    <td>Nogai</td>
    <td>nogaï; nogay</td>
    <td>Nogaisch</td>
    </tr><tr valign="top">
    <td scope="row">non</td>
    <td>&nbsp;</td>
    <td>Norse, Old</td>
    <td>norrois, vieux</td>
    <td>Altnorwegisch</td>
    </tr><tr valign="top">
    <td scope="row">nor</td>
    <td>no</td>
    <td>Norwegian</td>
    <td>norvégien</td>
    <td>Norwegisch</td>
    </tr><tr valign="top">
    <td scope="row">nqo</td>
    <td>&nbsp;</td>
    <td>N'Ko</td>
    <td>n'ko</td>
    <td>N'Ko</td>
    </tr><tr valign="top">
    <td scope="row">nso</td>
    <td>&nbsp;</td>
    <td>Pedi; Sepedi; Northern Sotho</td>
    <td>pedi; sepedi; sotho du Nord</td>
    <td>Pedi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nub</td>
    <td>&nbsp;</td>
    <td>Nubian languages</td>
    <td>nubiennes, langues</td>
    <td>Nubische Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">nwc</td>
    <td>&nbsp;</td>
    <td>Classical Newari; Old Newari; Classical Nepal Bhasa</td>
    <td>newari classique</td>
    <td>Alt-Newari</td>
    </tr><tr valign="top">
    <td scope="row">nya</td>
    <td>ny</td>
    <td>Chichewa; Chewa; Nyanja</td>
    <td>chichewa; chewa; nyanja</td>
    <td>Nyanja-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nym</td>
    <td>&nbsp;</td>
    <td>Nyamwezi</td>
    <td>nyamwezi</td>
    <td>Nyamwezi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nyn</td>
    <td>&nbsp;</td>
    <td>Nyankole</td>
    <td>nyankolé</td>
    <td>Nkole-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nyo</td>
    <td>&nbsp;</td>
    <td>Nyoro</td>
    <td>nyoro</td>
    <td>Nyoro-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">nzi</td>
    <td>&nbsp;</td>
    <td>Nzima</td>
    <td>nzema</td>
    <td>Nzima-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">oci</td>
    <td>oc</td>
    <td>Occitan (post 1500)</td>
    <td>occitan (après 1500)</td>
    <td>Okzitanisch</td>
    </tr><tr valign="top">
    <td scope="row">oji</td>
    <td>oj</td>
    <td>Ojibwa</td>
    <td>ojibwa</td>
    <td>Ojibwa-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ori</td>
    <td>or</td>
    <td>Oriya</td>
    <td>oriya</td>
    <td>Oriya-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">orm</td>
    <td>om</td>
    <td>Oromo</td>
    <td>galla</td>
    <td>Galla-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">osa</td>
    <td>&nbsp;</td>
    <td>Osage</td>
    <td>osage</td>
    <td>Osage-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">oss</td>
    <td>os</td>
    <td>Ossetian; Ossetic</td>
    <td>ossète</td>
    <td>Ossetisch</td>
    </tr><tr valign="top">
    <td scope="row">ota</td>
    <td>&nbsp;</td>
    <td>Turkish, Ottoman (1500-1928)</td>
    <td>turc ottoman (1500-1928)</td>
    <td>Osmanisch</td>
    </tr><tr valign="top">
    <td scope="row">oto</td>
    <td>&nbsp;</td>
    <td>Otomian languages</td>
    <td>otomi, langues</td>
    <td>Otomangue-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">paa</td>
    <td>&nbsp;</td>
    <td>Papuan languages</td>
    <td>papoues, langues</td>
    <td>Papuasprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">pag</td>
    <td>&nbsp;</td>
    <td>Pangasinan</td>
    <td>pangasinan</td>
    <td>Pangasinan-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">pal</td>
    <td>&nbsp;</td>
    <td>Pahlavi</td>
    <td>pahlavi</td>
    <td>Mittelpersisch</td>
    </tr><tr valign="top">
    <td scope="row">pam</td>
    <td>&nbsp;</td>
    <td>Pampanga; Kapampangan</td>
    <td>pampangan</td>
    <td>Pampanggan-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">pan</td>
    <td>pa</td>
    <td>Panjabi; Punjabi</td>
    <td>pendjabi</td>
    <td>Pandschabi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">pap</td>
    <td>&nbsp;</td>
    <td>Papiamento</td>
    <td>papiamento</td>
    <td>Papiamento</td>
    </tr><tr valign="top">
    <td scope="row">pau</td>
    <td>&nbsp;</td>
    <td>Palauan</td>
    <td>palau</td>
    <td>Palau-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">peo</td>
    <td>&nbsp;</td>
    <td>Persian, Old (ca.600-400 B.C.)</td>
    <td>perse, vieux (ca. 600-400 av. J.-C.)</td>
    <td>Altpersisch</td>
    </tr><tr valign="top">
    <td scope="row">per (B)<br>fas (T)</td>
    <td>fa</td>
    <td>Persian</td>
    <td>persan</td>
    <td>Persisch</td>
    </tr><tr valign="top">
    <td scope="row">phi</td>
    <td>&nbsp;</td>
    <td>Philippine languages</td>
    <td>philippines, langues</td>
    <td>Philippinisch-Austronesisch (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">phn</td>
    <td>&nbsp;</td>
    <td>Phoenician</td>
    <td>phénicien</td>
    <td>Phönikisch</td>
    </tr><tr valign="top">
    <td scope="row">pli</td>
    <td>pi</td>
    <td>Pali</td>
    <td>pali</td>
    <td>Pali</td>
    </tr><tr valign="top">
    <td scope="row">pol</td>
    <td>pl</td>
    <td>Polish</td>
    <td>polonais</td>
    <td>Polnisch</td>
    </tr><tr valign="top">
    <td scope="row">pon</td>
    <td>&nbsp;</td>
    <td>Pohnpeian</td>
    <td>pohnpei</td>
    <td>Ponapeanisch</td>
    </tr><tr valign="top">
    <td scope="row">por</td>
    <td>pt</td>
    <td>Portuguese</td>
    <td>portugais</td>
    <td>Portugiesisch</td>
    </tr><tr valign="top">
    <td scope="row">pra</td>
    <td>&nbsp;</td>
    <td>Prakrit languages</td>
    <td>prâkrit, langues</td>
    <td>Prakrit</td>
    </tr><tr valign="top">
    <td scope="row">pro</td>
    <td>&nbsp;</td>
    <td>Provençal, Old (to 1500);Occitan, Old (to 1500)</td>
    <td>provençal ancien (jusqu'à 1500); occitan ancien (jusqu'à 1500)</td>
    <td>Altokzitanisch</td>
    </tr><tr valign="top">
    <td scope="row">pus</td>
    <td>ps</td>
    <td>Pushto; Pashto</td>
    <td>pachto</td>
    <td>Paschtu</td>
    </tr><tr valign="top">
    <td scope="row">qaa-qtz</td>
    <td>&nbsp;</td>
    <td>Reserved for local use</td>
    <td>réservée à l'usage local</td>
    <td>Reserviert für lokale Verwendung</td>
    </tr><tr valign="top">
    <td scope="row">que</td>
    <td>qu</td>
    <td>Quechua</td>
    <td>quechua</td>
    <td>Quechua-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">raj</td>
    <td>&nbsp;</td>
    <td>Rajasthani</td>
    <td>rajasthani</td>
    <td>Rajasthani</td>
    </tr><tr valign="top">
    <td scope="row">rap</td>
    <td>&nbsp;</td>
    <td>Rapanui</td>
    <td>rapanui</td>
    <td>Osterinsel-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">rar</td>
    <td>&nbsp;</td>
    <td>Rarotongan; Cook Islands Maori</td>
    <td>rarotonga; maori des îles Cook</td>
    <td>Rarotonganisch</td>
    </tr><tr valign="top">
    <td scope="row">roa</td>
    <td>&nbsp;</td>
    <td>Romance languages</td>
    <td>romanes, langues</td>
    <td>Romanische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">roh</td>
    <td>rm</td>
    <td>Romansh</td>
    <td>romanche</td>
    <td>Rätoromanisch</td>
    </tr><tr valign="top">
    <td scope="row">rom</td>
    <td>&nbsp;</td>
    <td>Romany</td>
    <td>tsigane</td>
    <td>Romani (Sprache)</td>
    </tr><tr valign="top">
    <td scope="row">rum (B)<br>ron (T)</td>
    <td>ro</td>
    <td>Romanian; Moldavian; Moldovan</td>
    <td>roumain; moldave</td>
    <td>Rumänisch</td>
    </tr><tr valign="top">
    <td scope="row">rum (B)<br>ron (T)</td>
    <td>ro</td>
    <td>Romanian; Moldavian; Moldovan</td>
    <td>roumain; moldave</td>
    <td>Rumänisch</td>
    </tr><tr valign="top">
    <td scope="row">run</td>
    <td>rn</td>
    <td>Rundi</td>
    <td>rundi</td>
    <td>Rundi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">rup</td>
    <td>&nbsp;</td>
    <td>Aromanian; Arumanian; Macedo-Romanian</td>
    <td>aroumain; macédo-roumain</td>
    <td>Aromunisch</td>
    </tr><tr valign="top">
    <td scope="row">rus</td>
    <td>ru</td>
    <td>Russian</td>
    <td>russe</td>
    <td>Russisch</td>
    </tr><tr valign="top">
    <td scope="row">sad</td>
    <td>&nbsp;</td>
    <td>Sandawe</td>
    <td>sandawe</td>
    <td>Sandawe-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sag</td>
    <td>sg</td>
    <td>Sango</td>
    <td>sango</td>
    <td>Sango-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sah</td>
    <td>&nbsp;</td>
    <td>Yakut</td>
    <td>iakoute</td>
    <td>Jakutisch</td>
    </tr><tr valign="top">
    <td scope="row">sai</td>
    <td>&nbsp;</td>
    <td>South American Indian languages</td>
    <td>sud-amérindiennes, langues</td>
    <td>Indianersprachen, Südamerika (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">sal</td>
    <td>&nbsp;</td>
    <td>Salishan languages</td>
    <td>salishennes, langues</td>
    <td>Salish-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sam</td>
    <td>&nbsp;</td>
    <td>Samaritan Aramaic</td>
    <td>samaritain</td>
    <td>Samaritanisch</td>
    </tr><tr valign="top">
    <td scope="row">san</td>
    <td>sa</td>
    <td>Sanskrit</td>
    <td>sanskrit</td>
    <td>Sanskrit</td>
    </tr><tr valign="top">
    <td scope="row">sas</td>
    <td>&nbsp;</td>
    <td>Sasak</td>
    <td>sasak</td>
    <td>Sasak</td>
    </tr><tr valign="top">
    <td scope="row">sat</td>
    <td>&nbsp;</td>
    <td>Santali</td>
    <td>santal</td>
    <td>Santali</td>
    </tr><tr valign="top">
    <td scope="row">scn</td>
    <td>&nbsp;</td>
    <td>Sicilian</td>
    <td>sicilien</td>
    <td>Sizilianisch</td>
    </tr><tr valign="top">
    <td scope="row">sco</td>
    <td>&nbsp;</td>
    <td>Scots</td>
    <td>écossais</td>
    <td>Schottisch</td>
    </tr><tr valign="top">
    <td scope="row">sel</td>
    <td>&nbsp;</td>
    <td>Selkup</td>
    <td>selkoupe</td>
    <td>Selkupisch</td>
    </tr><tr valign="top">
    <td scope="row">sem</td>
    <td>&nbsp;</td>
    <td>Semitic languages</td>
    <td>sémitiques, langues</td>
    <td>Semitische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">sga</td>
    <td>&nbsp;</td>
    <td>Irish, Old (to 900)</td>
    <td>irlandais ancien (jusqu'à 900)</td>
    <td>Altirisch</td>
    </tr><tr valign="top">
    <td scope="row">sgn</td>
    <td>&nbsp;</td>
    <td>Sign Languages</td>
    <td>langues des signes</td>
    <td>Zeichensprachen</td>
    </tr><tr valign="top">
    <td scope="row">shn</td>
    <td>&nbsp;</td>
    <td>Shan</td>
    <td>chan</td>
    <td>Schan-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sid</td>
    <td>&nbsp;</td>
    <td>Sidamo</td>
    <td>sidamo</td>
    <td>Sidamo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sin</td>
    <td>si</td>
    <td>Sinhala; Sinhalese</td>
    <td>singhalais</td>
    <td>Singhalesisch</td>
    </tr><tr valign="top">
    <td scope="row">sio</td>
    <td>&nbsp;</td>
    <td>Siouan languages</td>
    <td>sioux, langues</td>
    <td>Sioux-Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">sit</td>
    <td>&nbsp;</td>
    <td>Sino-Tibetan languages</td>
    <td>sino-tibétaines, langues</td>
    <td>Sinotibetische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">sla</td>
    <td>&nbsp;</td>
    <td>Slavic languages</td>
    <td>slaves, langues</td>
    <td>Slawische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">slo (B)<br>slk (T)</td>
    <td>sk</td>
    <td>Slovak</td>
    <td>slovaque</td>
    <td>Slowakisch</td>
    </tr><tr valign="top">
    <td scope="row">slo (B)<br>slk (T)</td>
    <td>sk</td>
    <td>Slovak</td>
    <td>slovaque</td>
    <td>Slowakisch</td>
    </tr><tr valign="top">
    <td scope="row">slv</td>
    <td>sl</td>
    <td>Slovenian</td>
    <td>slovène</td>
    <td>Slowenisch</td>
    </tr><tr valign="top">
    <td scope="row">sma</td>
    <td>&nbsp;</td>
    <td>Southern Sami</td>
    <td>sami du Sud</td>
    <td>Südsaamisch</td>
    </tr><tr valign="top">
    <td scope="row">sme</td>
    <td>se</td>
    <td>Northern Sami</td>
    <td>sami du Nord</td>
    <td>Nordsaamisch</td>
    </tr><tr valign="top">
    <td scope="row">smi</td>
    <td>&nbsp;</td>
    <td>Sami languages</td>
    <td>sames, langues</td>
    <td>Saamisch</td>
    </tr><tr valign="top">
    <td scope="row">smj</td>
    <td>&nbsp;</td>
    <td>Lule Sami</td>
    <td>sami de Lule</td>
    <td>Lulesaamisch</td>
    </tr><tr valign="top">
    <td scope="row">smn</td>
    <td>&nbsp;</td>
    <td>Inari Sami</td>
    <td>sami d'Inari</td>
    <td>Inarisaamisch</td>
    </tr><tr valign="top">
    <td scope="row">smo</td>
    <td>sm</td>
    <td>Samoan</td>
    <td>samoan</td>
    <td>Samoanisch</td>
    </tr><tr valign="top">
    <td scope="row">sms</td>
    <td>&nbsp;</td>
    <td>Skolt Sami</td>
    <td>sami skolt</td>
    <td>Skoltsaamisch</td>
    </tr><tr valign="top">
    <td scope="row">sna</td>
    <td>sn</td>
    <td>Shona</td>
    <td>shona</td>
    <td>Schona-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">snd</td>
    <td>sd</td>
    <td>Sindhi</td>
    <td>sindhi</td>
    <td>Sindhi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">snk</td>
    <td>&nbsp;</td>
    <td>Soninke</td>
    <td>soninké</td>
    <td>Soninke-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sog</td>
    <td>&nbsp;</td>
    <td>Sogdian</td>
    <td>sogdien</td>
    <td>Sogdisch</td>
    </tr><tr valign="top">
    <td scope="row">som</td>
    <td>so</td>
    <td>Somali</td>
    <td>somali</td>
    <td>Somali</td>
    </tr><tr valign="top">
    <td scope="row">son</td>
    <td>&nbsp;</td>
    <td>Songhai languages</td>
    <td>songhai, langues</td>
    <td>Songhai-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sot</td>
    <td>st</td>
    <td>Sotho, Southern</td>
    <td>sotho du Sud</td>
    <td>Süd-Sotho-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">spa</td>
    <td>es</td>
    <td>Spanish; Castilian</td>
    <td>espagnol; castillan</td>
    <td>Spanisch</td>
    </tr><tr valign="top">
    <td scope="row">alb (B)<br>sqi (T)</td>
    <td>sq</td>
    <td>Albanian</td>
    <td>albanais</td>
    <td>Albanisch</td>
    </tr><tr valign="top">
    <td scope="row">srd</td>
    <td>sc</td>
    <td>Sardinian</td>
    <td>sarde</td>
    <td>Sardisch</td>
    </tr><tr valign="top">
    <td scope="row">srn</td>
    <td>&nbsp;</td>
    <td>Sranan Tongo</td>
    <td>sranan tongo</td>
    <td>Sranantongo</td>
    </tr><tr valign="top">
    <td scope="row">srp</td>
    <td>sr</td>
    <td>Serbian</td>
    <td>serbe</td>
    <td>Serbisch </td>
    </tr><tr valign="top">
    <td scope="row">srr</td>
    <td>&nbsp;</td>
    <td>Serer</td>
    <td>sérère</td>
    <td>Serer-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ssa</td>
    <td>&nbsp;</td>
    <td>Nilo-Saharan languages</td>
    <td>nilo-sahariennes, langues</td>
    <td>Nilosaharanische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">ssw</td>
    <td>ss</td>
    <td>Swati</td>
    <td>swati</td>
    <td>Swasi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">suk</td>
    <td>&nbsp;</td>
    <td>Sukuma</td>
    <td>sukuma</td>
    <td>Sukuma-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">sun</td>
    <td>su</td>
    <td>Sundanese</td>
    <td>soundanais</td>
    <td>Sundanesisch</td>
    </tr><tr valign="top">
    <td scope="row">sus</td>
    <td>&nbsp;</td>
    <td>Susu</td>
    <td>soussou</td>
    <td>Susu</td>
    </tr><tr valign="top">
    <td scope="row">sux</td>
    <td>&nbsp;</td>
    <td>Sumerian</td>
    <td>sumérien</td>
    <td>Sumerisch</td>
    </tr><tr valign="top">
    <td scope="row">swa</td>
    <td>sw</td>
    <td>Swahili</td>
    <td>swahili</td>
    <td>Swahili</td>
    </tr><tr valign="top">
    <td scope="row">swe</td>
    <td>sv</td>
    <td>Swedish</td>
    <td>suédois</td>
    <td>Schwedisch</td>
    </tr><tr valign="top">
    <td scope="row">syc</td>
    <td>&nbsp;</td>
    <td>Classical Syriac</td>
    <td>syriaque classique</td>
    <td>Syrisch</td>
    </tr><tr valign="top">
    <td scope="row">syr</td>
    <td>&nbsp;</td>
    <td>Syriac</td>
    <td>syriaque</td>
    <td>Neuostaramäisch</td>
    </tr><tr valign="top">
    <td scope="row">tah</td>
    <td>ty</td>
    <td>Tahitian</td>
    <td>tahitien</td>
    <td>Tahitisch</td>
    </tr><tr valign="top">
    <td scope="row">tai</td>
    <td>&nbsp;</td>
    <td>Tai languages</td>
    <td>tai, langues</td>
    <td>Thaisprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">tam</td>
    <td>ta</td>
    <td>Tamil</td>
    <td>tamoul</td>
    <td>Tamil</td>
    </tr><tr valign="top">
    <td scope="row">tat</td>
    <td>tt</td>
    <td>Tatar</td>
    <td>tatar</td>
    <td>Tatarisch</td>
    </tr><tr valign="top">
    <td scope="row">tel</td>
    <td>te</td>
    <td>Telugu</td>
    <td>télougou</td>
    <td>Telugu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tem</td>
    <td>&nbsp;</td>
    <td>Timne</td>
    <td>temne</td>
    <td>Temne-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ter</td>
    <td>&nbsp;</td>
    <td>Tereno</td>
    <td>tereno</td>
    <td>Tereno-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tet</td>
    <td>&nbsp;</td>
    <td>Tetum</td>
    <td>tetum</td>
    <td>Tetum-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tgk</td>
    <td>tg</td>
    <td>Tajik</td>
    <td>tadjik</td>
    <td>Tadschikisch</td>
    </tr><tr valign="top">
    <td scope="row">tgl</td>
    <td>tl</td>
    <td>Tagalog</td>
    <td>tagalog</td>
    <td>Tagalog</td>
    </tr><tr valign="top">
    <td scope="row">tha</td>
    <td>th</td>
    <td>Thai</td>
    <td>thaï</td>
    <td>Thailändisch</td>
    </tr><tr valign="top">
    <td scope="row">tib (B)<br>bod (T)</td>
    <td>bo</td>
    <td>Tibetan</td>
    <td>tibétain</td>
    <td>Tibetisch</td>
    </tr><tr valign="top">
    <td scope="row">tig</td>
    <td>&nbsp;</td>
    <td>Tigre</td>
    <td>tigré</td>
    <td>Tigre-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tir</td>
    <td>ti</td>
    <td>Tigrinya</td>
    <td>tigrigna</td>
    <td>Tigrinja-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tiv</td>
    <td>&nbsp;</td>
    <td>Tiv</td>
    <td>tiv</td>
    <td>Tiv-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tkl</td>
    <td>&nbsp;</td>
    <td>Tokelau</td>
    <td>tokelau</td>
    <td>Tokelauanisch</td>
    </tr><tr valign="top">
    <td scope="row">tlh</td>
    <td>&nbsp;</td>
    <td>Klingon; tlhIngan-Hol</td>
    <td>klingon</td>
    <td>Klingonisch</td>
    </tr><tr valign="top">
    <td scope="row">tli</td>
    <td>&nbsp;</td>
    <td>Tlingit</td>
    <td>tlingit</td>
    <td>Tlingit-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tmh</td>
    <td>&nbsp;</td>
    <td>Tamashek</td>
    <td>tamacheq</td>
    <td>Tamašeq</td>
    </tr><tr valign="top">
    <td scope="row">tog</td>
    <td>&nbsp;</td>
    <td>Tonga (Nyasa)</td>
    <td>tonga (Nyasa)</td>
    <td>Tonga (Bantusprache, Sambia)</td>
    </tr><tr valign="top">
    <td scope="row">ton</td>
    <td>to</td>
    <td>Tonga (Tonga Islands)</td>
    <td>tongan (Îles Tonga)</td>
    <td>Tongaisch</td>
    </tr><tr valign="top">
    <td scope="row">tpi</td>
    <td>&nbsp;</td>
    <td>Tok Pisin</td>
    <td>tok pisin</td>
    <td>Neumelanesisch</td>
    </tr><tr valign="top">
    <td scope="row">tsi</td>
    <td>&nbsp;</td>
    <td>Tsimshian</td>
    <td>tsimshian</td>
    <td>Tsimshian-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tsn</td>
    <td>tn</td>
    <td>Tswana</td>
    <td>tswana</td>
    <td>Tswana-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tso</td>
    <td>ts</td>
    <td>Tsonga</td>
    <td>tsonga</td>
    <td>Tsonga-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tuk</td>
    <td>tk</td>
    <td>Turkmen</td>
    <td>turkmène</td>
    <td>Turkmenisch</td>
    </tr><tr valign="top">
    <td scope="row">tum</td>
    <td>&nbsp;</td>
    <td>Tumbuka</td>
    <td>tumbuka</td>
    <td>Tumbuka-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tup</td>
    <td>&nbsp;</td>
    <td>Tupi languages</td>
    <td>tupi, langues</td>
    <td>Tupi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tur</td>
    <td>tr</td>
    <td>Turkish</td>
    <td>turc</td>
    <td>Türkisch</td>
    </tr><tr valign="top">
    <td scope="row">tut</td>
    <td>&nbsp;</td>
    <td>Altaic languages</td>
    <td>altaïques, langues</td>
    <td>Altaische Sprachen (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">tvl</td>
    <td>&nbsp;</td>
    <td>Tuvalu</td>
    <td>tuvalu</td>
    <td>Elliceanisch</td>
    </tr><tr valign="top">
    <td scope="row">twi</td>
    <td>tw</td>
    <td>Twi</td>
    <td>twi</td>
    <td>Twi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">tyv</td>
    <td>&nbsp;</td>
    <td>Tuvinian</td>
    <td>touva</td>
    <td>Tuwinisch</td>
    </tr><tr valign="top">
    <td scope="row">udm</td>
    <td>&nbsp;</td>
    <td>Udmurt</td>
    <td>oudmourte</td>
    <td>Udmurtisch</td>
    </tr><tr valign="top">
    <td scope="row">uga</td>
    <td>&nbsp;</td>
    <td>Ugaritic</td>
    <td>ougaritique</td>
    <td>Ugaritisch</td>
    </tr><tr valign="top">
    <td scope="row">uig</td>
    <td>ug</td>
    <td>Uighur; Uyghur</td>
    <td>ouïgour</td>
    <td>Uigurisch</td>
    </tr><tr valign="top">
    <td scope="row">ukr</td>
    <td>uk</td>
    <td>Ukrainian</td>
    <td>ukrainien</td>
    <td>Ukrainisch</td>
    </tr><tr valign="top">
    <td scope="row">umb</td>
    <td>&nbsp;</td>
    <td>Umbundu</td>
    <td>umbundu</td>
    <td>Mbundu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">und</td>
    <td>&nbsp;</td>
    <td>Undetermined</td>
    <td>indéterminée</td>
    <td>Nicht zu entscheiden</td>
    </tr><tr valign="top">
    <td scope="row">urd</td>
    <td>ur</td>
    <td>Urdu</td>
    <td>ourdou</td>
    <td>Urdu</td>
    </tr><tr valign="top">
    <td scope="row">uzb</td>
    <td>uz</td>
    <td>Uzbek</td>
    <td>ouszbek</td>
    <td>Usbekisch</td>
    </tr><tr valign="top">
    <td scope="row">vai</td>
    <td>&nbsp;</td>
    <td>Vai</td>
    <td>vaï</td>
    <td>Vai-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ven</td>
    <td>ve</td>
    <td>Venda</td>
    <td>venda</td>
    <td>Venda-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">vie</td>
    <td>vi</td>
    <td>Vietnamese</td>
    <td>vietnamien</td>
    <td>Vietnamesisch</td>
    </tr><tr valign="top">
    <td scope="row">vol</td>
    <td>vo</td>
    <td>Volapük</td>
    <td>volapük</td>
    <td>Volapük</td>
    </tr><tr valign="top">
    <td scope="row">vot</td>
    <td>&nbsp;</td>
    <td>Votic</td>
    <td>vote</td>
    <td>Wotisch</td>
    </tr><tr valign="top">
    <td scope="row">wak</td>
    <td>&nbsp;</td>
    <td>Wakashan languages</td>
    <td>wakashanes, langues</td>
    <td>Wakash-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">wal</td>
    <td>&nbsp;</td>
    <td>Wolaitta; Wolaytta</td>
    <td>wolaitta; wolaytta</td>
    <td>Walamo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">war</td>
    <td>&nbsp;</td>
    <td>Waray</td>
    <td>waray</td>
    <td>Waray</td>
    </tr><tr valign="top">
    <td scope="row">was</td>
    <td>&nbsp;</td>
    <td>Washo</td>
    <td>washo</td>
    <td>Washo-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">wel (B)<br>cym (T)</td>
    <td>cy</td>
    <td>Welsh</td>
    <td>gallois</td>
    <td>Kymrisch</td>
    </tr><tr valign="top">
    <td scope="row">wen</td>
    <td>&nbsp;</td>
    <td>Sorbian languages</td>
    <td>sorabes, langues</td>
    <td>Sorbisch (Andere)</td>
    </tr><tr valign="top">
    <td scope="row">wln</td>
    <td>wa</td>
    <td>Walloon</td>
    <td>wallon</td>
    <td>Wallonisch</td>
    </tr><tr valign="top">
    <td scope="row">wol</td>
    <td>wo</td>
    <td>Wolof</td>
    <td>wolof</td>
    <td>Wolof-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">xal</td>
    <td>&nbsp;</td>
    <td>Kalmyk; Oirat</td>
    <td>kalmouk; oïrat</td>
    <td>Kalmückisch</td>
    </tr><tr valign="top">
    <td scope="row">xho</td>
    <td>xh</td>
    <td>Xhosa</td>
    <td>xhosa</td>
    <td>Xhosa-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">yao</td>
    <td>&nbsp;</td>
    <td>Yao</td>
    <td>yao</td>
    <td>Yao-Sprache (Bantusprache)</td>
    </tr><tr valign="top">
    <td scope="row">yap</td>
    <td>&nbsp;</td>
    <td>Yapese</td>
    <td>yapois</td>
    <td>Yapesisch</td>
    </tr><tr valign="top">
    <td scope="row">yid</td>
    <td>yi</td>
    <td>Yiddish</td>
    <td>yiddish</td>
    <td>Jiddisch</td>
    </tr><tr valign="top">
    <td scope="row">yor</td>
    <td>yo</td>
    <td>Yoruba</td>
    <td>yoruba</td>
    <td>Yoruba-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">ypk</td>
    <td>&nbsp;</td>
    <td>Yupik languages</td>
    <td>yupik, langues</td>
    <td>Ypik-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">zap</td>
    <td>&nbsp;</td>
    <td>Zapotec</td>
    <td>zapotèque</td>
    <td>Zapotekisch</td>
    </tr><tr valign="top">
    <td scope="row">zbl</td>
    <td>&nbsp;</td>
    <td>Blissymbols; Blissymbolics; Bliss</td>
    <td>symboles Bliss; Bliss</td>
    <td>Bliss-Symbol</td>
    </tr><tr valign="top">
    <td scope="row">zen</td>
    <td>&nbsp;</td>
    <td>Zenaga</td>
    <td>zenaga</td>
    <td>Zenaga</td>
    </tr><tr valign="top">
    <td scope="row">zgh</td>
    <td>&nbsp;</td>
    <td>Standard Moroccan Tamazight</td>
    <td>amazighe standard marocain</td>
    <td></td>
    </tr><tr valign="top">
    <td scope="row">zha</td>
    <td>za</td>
    <td>Zhuang; Chuang</td>
    <td>zhuang; chuang</td>
    <td>Zhuang</td>
    </tr><tr valign="top">
    <td scope="row">chi (B)<br>zho (T)</td>
    <td>zh</td>
    <td>Chinese</td>
    <td>chinois</td>
    <td>Chinesisch</td>
    </tr><tr valign="top">
    <td scope="row">znd</td>
    <td>&nbsp;</td>
    <td>Zande languages</td>
    <td>zandé, langues</td>
    <td>Zande-Sprachen</td>
    </tr><tr valign="top">
    <td scope="row">zul</td>
    <td>zu</td>
    <td>Zulu</td>
    <td>zoulou</td>
    <td>Zulu-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">zun</td>
    <td>&nbsp;</td>
    <td>Zuni</td>
    <td>zuni</td>
    <td>Zuñi-Sprache</td>
    </tr><tr valign="top">
    <td scope="row">zxx</td>
    <td>&nbsp;</td>
    <td>No linguistic content; Not applicable</td>
    <td>pas de contenu linguistique; non applicable</td>
    <td>Kein linguistischer Inhalt</td>
    </tr><tr valign="top">
    <td scope="row">zza</td>
    <td>&nbsp;</td>
    <td>Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki</td>
    <td>zaza; dimili; dimli; kirdki; kirmanjki; zazaki</td>
    <td>Zazaki</td>
END
# podDocumentation

=pod

=encoding utf-8

=head1 Name

ISO::639 - ISO 639 Language codes

=head1 Synopsis

From: L<https://www.loc.gov/standards/iso639-2/php/code_list.php>

 ok ISO::639::English    (chi) eq "Chinese";
 ok ISO::639::anglais    (zho) eq "Chinese";
 ok ISO::639::Englisch   (zh)  eq "Chinese";

 ok ISO::639::French     (chi) eq "chinois";
 ok ISO::639::français   (zho) eq "chinois";
 ok ISO::639::Französisch(zh)  eq "chinois";

 ok ISO::639::German     (chi) eq "Chinesisch";
 ok ISO::639::allemand   (zho) eq "Chinesisch";
 ok ISO::639::Deutsch    (zh)  eq "Chinesisch";

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Language Codes

Language names from ISO 639 2 and 3 digit language codes in English, French, German

=head2 English(*)

Full name in English from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::English


=head2 anglais(*)

Full name in English from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::anglais


=head2 Englisch(*)

Full name in English from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::Englisch


=head2 French(*)

Full name in French from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::French


=head2 français(*)

Full name in French from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::français


=head2 Französisch(*)

Full name in French from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::Französisch


=head2 German(*)

Full name in German from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::German


=head2 allemand(*)

Full name in German from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::allemand


=head2 Deutsch(*)

Full name in German from 2 or 3 digit language code

  1  Parameter  Description    
  2  $code      Language code  

This is a static method and so should be invoked as:

  ISO::639::Deutsch



=head1 Index


1 L<allemand|/allemand>

2 L<anglais|/anglais>

3 L<Deutsch|/Deutsch>

4 L<Englisch|/Englisch>

5 L<English|/English>

6 L<Französisch|/Französisch>

7 L<français|/français>

8 L<French|/French>

9 L<German|/German>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>16;

binModeAllUtf8;

ok ISO::639::English    (wel) eq "Welsh";
ok ISO::639::English    (cym) eq "Welsh";

ok ISO::639::English    (chi) eq "Chinese";
ok ISO::639::anglais    (zho) eq "Chinese";
ok ISO::639::Englisch   (zh)  eq "Chinese";

ok ISO::639::French     (chi) eq "chinois";
ok ISO::639::français   (zho) eq "chinois";
ok ISO::639::Französisch(zh)  eq "chinois";

ok ISO::639::German     (chi) eq "Chinesisch";
ok ISO::639::allemand   (zho) eq "Chinesisch";
ok ISO::639::Deutsch    (zh)  eq "Chinesisch";

ok ISO::639::English    (znd) eq "Zande languages";
ok ISO::639::Französisch(znd) eq "zandé, langues";
ok ISO::639::allemand   (znd) eq "Zande-Sprachen";


ok ISO::639::English    (nb) eq "Norwegian";
ok ISO::639::English    (ro) eq "Romanian";
