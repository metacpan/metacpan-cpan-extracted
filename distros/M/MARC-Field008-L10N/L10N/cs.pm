package MARC::Field008::L10N::cs;

use base qw(MARC::Field008::L10N);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.01;

our %Lexicon = (

	# Common terms.
	'Date entered on file' => decode_utf8('Datum uložení do souboru'),
	'Type of date/Publication status' => decode_utf8('Typ data/publikační status'),
	'Date 1' => decode_utf8('Datum 1'),
	'Date 2' => decode_utf8('Datum 2'),
	'Place of publication, production, or execution' => decode_utf8('Místo vydání, produkce nebo realizace'),
	'Material' => decode_utf8('Materiál'),
	'Language' => 'Jazyk dokumentu',
	'Modified record' => decode_utf8('Modifikace záznamu'),
	'Cataloging source' => 'Zdroj katalogizace',

	# Type of date.
	'type_of_date.b' => decode_utf8('data neuvedena - datum před n.l.'),
	'type_of_date.c' => decode_utf8('průběžně vydávaný'),
	'type_of_date.d' => decode_utf8('s ukončeným vydáváním'),
	'type_of_date.e' => decode_utf8('podrobné datum'),
	'type_of_date.i' => decode_utf8('data zahrnutá ve sbírce'),
	'type_of_date.k' => decode_utf8('data většiny sbírky'),
	'type_of_date.m' => decode_utf8('rozmezí dat (u vícedílných popisných jednotek)'),
	'type_of_date.n' => decode_utf8('neznámá data'),
	'type_of_date.p' => decode_utf8('datum distribuce/zveřejnění/vydání a datum produkce/nahrávky, pokud jsou odlišná'),
	'type_of_date.q' => decode_utf8('nejisté datum'),
	'type_of_date.r' => decode_utf8('datum reprintu/reedice a datum původního vydání'),
	'type_of_date.s' => decode_utf8('jedno známé/pravděpodobné datum'),
	'type_of_date.t' => decode_utf8('datum vydání a datum copyrightu'),
	'type_of_date.u' => decode_utf8('status není znám (datum zahájení a/nebo ukončení vydávání není známo)'),
	'type_of_date.|' => decode_utf8('kód se neuvádí'),

	# Modified record.
	'modified_record._' => decode_utf8('nemodifikován'),
	'modified_record.d' => decode_utf8('vynechán podrobný rozpis'),
	'modified_record.o' => decode_utf8('plně v latince/tisk lístků v latince'),
	'modified_record.r' => decode_utf8('plně v latince/tisk lístků v nelatinkovém písmu'),
	'modified_record.s' => decode_utf8('zkrácený'),
	'modified_record.x' => decode_utf8('vynechané znaky'),
	'modified_record.|' => decode_utf8('kód se neuvádí'),

	# Cataloging source.
	'cataloging_source._' => decode_utf8('národní bibliografická agentura'),
	'cataloging_source.c' => decode_utf8('program kooperativní katalogizace'),
	'cataloging_source.d' => decode_utf8('jiný zdroj'),
	'cataloging_source.u' => decode_utf8('není znám'),
	'cataloging_source.|' => decode_utf8('kód se neuvádí'),

	# Common material terms.
	'Form of item' => decode_utf8('Forma popisné jednotky'),
	'Government publication' => decode_utf8('Vládní publikace'),
	'Index' => decode_utf8('Rejstřík'),
	'Target audience' => decode_utf8('Uživatelské určení'),
	'Undefined' => decode_utf8('Nedefinován'),

	# books
	'Illustrations' => 'Ilustrace',
	# Target audience
	# Form of item
	'Nature of contents' => decode_utf8('Povaha obsahu'),
	# Government publication
	'Conference publication' => decode_utf8('Publikace z konference'),
	'Festschrift' => decode_utf8('Jubilejní sborník'),
	# Index
	# Undefined
	'Literary form' => decode_utf8('Literární forma'),
	'Biography' => 'Biografie',

	# common material - Target audience.
	'target_audience._' => decode_utf8('není znám nebo specifikován'),
	'target_audience.a' => decode_utf8('předškolní'),
	'target_audience.b' => decode_utf8('mladší děti'),
	'target_audience.c' => decode_utf8('starší děti'),
	'target_audience.d' => decode_utf8('mladiství'),
	'target_audience.e' => decode_utf8('dospělí'),
	'target_audience.f' => decode_utf8('specialisté'),
	'target_audience.g' => decode_utf8('všeobecně'),
	'target_audience.j' => decode_utf8('děti a mládež'),
	'target_audience.|' => decode_utf8('kód se neuvádí'),

	# common material - Government publication.
	'government_publication._' => decode_utf8('nejedná se o vládní publikaci'),
	'government_publication.a' => decode_utf8('autonomní nebo částečně autonomní složka'),
	'government_publication.c' => decode_utf8('působící ve více lokalitách'),
	'government_publication.f' => decode_utf8('federální/národní'),
	'government_publication.i' => decode_utf8('mezinárodní/mezivládní'),
	'government_publication.l' => decode_utf8('lokální'),
	'government_publication.m' => decode_utf8('působící ve více státech'),
	'government_publication.o' => decode_utf8('vládní publikace - neurčitá úroveň'),
	'government_publication.s' => decode_utf8('státní, oblastní, teritoriální atd.'),
	'government_publication.u' => decode_utf8('není známo, zda se jedná o vládní publikaci'),
	'government_publication.z' => decode_utf8('jiný'),
	'government_publication.|' => decode_utf8('kód se neuvádí'),

	# book, map, music, continuing resources, visual material, mixed materials - Form of item.
	'form_of_item._' => decode_utf8('žádný z uvedených'),
	'form_of_item.a' => decode_utf8('mikrofilm'),
	'form_of_item.b' => decode_utf8('mikrofiš'),
	'form_of_item.c' => decode_utf8('mikrokarta'),
	'form_of_item.d' => decode_utf8('zvětšené písmo'),
	'form_of_item.f' => decode_utf8('Braille'),
	'form_of_item.o' => decode_utf8('online'),
	'form_of_item.q' => decode_utf8('přímý elektronický přístup'),
	'form_of_item.r' => decode_utf8('reprodukce normálního písma'),
	'form_of_item.s' => decode_utf8('elektronická podoba'),
	'form_of_item.|' => decode_utf8('kód se neuvádí'),

	# book, map - Index.
	'index.0' => decode_utf8('neobsahuje rejstřík'),
	'index.1' => decode_utf8('obsahuje rejstřík'),
	'index.|' => decode_utf8('kód se neuvádí'),

	# book, continuing_resources - Conference publication.
	'conference_publication.0' => decode_utf8('nejedná se o materiál z konference'),
	'conference_publication.1' => decode_utf8('materiál z konference'),
	'conference_publication.|' => decode_utf8('kód se neuvádí'),

	# book, continuing_resources - Nature of contents.
	'nature_of_content._' => decode_utf8('nespecifikován'),
	'nature_of_content.a' => decode_utf8('referáty/resumé'),
	'nature_of_content.b' => decode_utf8('bibliografie'),
	'nature_of_content.c' => decode_utf8('katalogy'),
	'nature_of_content.d' => decode_utf8('slovníky'),
	'nature_of_content.e' => decode_utf8('encyklopedie'),
	'nature_of_content.f' => decode_utf8('příručky'),
	'nature_of_content.g' => decode_utf8('právnické články'),
	'nature_of_content.i' => decode_utf8('rejstříky'),
	'nature_of_content.j' => decode_utf8('patentové dokumenty'),
	'nature_of_content.k' => decode_utf8('diskografie'),
	'nature_of_content.l' => decode_utf8('legislativa'),
	'nature_of_content.m' => decode_utf8('disertace'),
	'nature_of_content.n' => decode_utf8('literární přehledy z určitého vědního oboru'),
	'nature_of_content.o' => decode_utf8('recenze'),
	'nature_of_content.p' => decode_utf8('programové texty'),
	'nature_of_content.q' => decode_utf8('filmografie'),
	'nature_of_content.r' => decode_utf8('adresáře'),
	'nature_of_content.s' => decode_utf8('statistiky'),
	'nature_of_content.t' => decode_utf8('technické zprávy'),
	'nature_of_content.u' => decode_utf8('standardy/specifikace'),
	'nature_of_content.v' => decode_utf8('právnické kauzy a poznámky ke kauzám'),
	'nature_of_content.w' => decode_utf8('přehledy a výběry z právnických materiálů'),
	'nature_of_content.y' => decode_utf8('ročenky'),
	'nature_of_content.z' => decode_utf8('smlouvy'),
	'nature_of_content.2' => decode_utf8('separáty'),
	'nature_of_content.5' => decode_utf8('kalendáře'),
	'nature_of_content.6' => decode_utf8('komiksy/grafické romány'),
	'nature_of_content.|' => decode_utf8('kód se neuvádí'),

	# book - Illustrations.
	'book.illustrations._' => decode_utf8('bez ilustrací'),
	'book.illustrations.a' => decode_utf8('ilustrace'),
	'book.illustrations.b' => decode_utf8('mapy'),
	'book.illustrations.c' => decode_utf8('portréty'),
	'book.illustrations.d' => decode_utf8('grafická znázornění'),
	'book.illustrations.e' => decode_utf8('plány'),
	'book.illustrations.f' => decode_utf8('obrazové přílohy'),
	'book.illustrations.g' => decode_utf8('hudba (noty)'),
	'book.illustrations.h' => decode_utf8('faksimile'),
	'book.illustrations.i' => decode_utf8('erby'),
	'book.illustrations.j' => decode_utf8('genealogické tabulky'),
	'book.illustrations.k' => decode_utf8('formuláře, tiskopisy'),
	'book.illustrations.l' => decode_utf8('ukázky, vzorky'),
	'book.illustrations.m' => decode_utf8('zvukové záznamy'),
	'book.illustrations.o' => decode_utf8('fotografie'),
	'book.illustrations.p' => decode_utf8('iluminace'),
	'book.illustrations.|' => decode_utf8('kód se neuvádí'),

	# book - Festschrift.
	'book.festschrift.0' => decode_utf8('nejedná se o jubilejní sborník'),
	'book.festschrift.1' => decode_utf8('jubilejní sborník'),
	'book.festschrift.|' => decode_utf8('kód se neuvádí'),

	# book - Literary form.
	'book.literary_form.0' => decode_utf8('nejedná se o beletrii (bez další specifikace)'),
	'book.literary_form.1' => decode_utf8('beletrie (bez další specifikace)'),
	'book.literary_form.d' => decode_utf8('dramata'),
	'book.literary_form.e' => decode_utf8('eseje'),
	'book.literary_form.f' => decode_utf8('romány'),
	'book.literary_form.h' => decode_utf8('humoristická díla, satiry atd.'),
	'book.literary_form.i' => decode_utf8('dopisy'),
	'book.literary_form.j' => decode_utf8('povídky'),
	'book.literary_form.m' => decode_utf8('smíšené formy'),
	'book.literary_form.p' => decode_utf8('poezie'),
	'book.literary_form.s' => decode_utf8('projevy'),
	'book.literary_form.u' => decode_utf8('není znám'),
	'book.literary_form.|' => decode_utf8('kód se neuvádí'),

	# book - Biography.
	'book.biography._' => decode_utf8('nejedná se o biografii'),
	'book.biography.a' => decode_utf8('autobiografie'),
	'book.biography.b' => decode_utf8('individuální biografie'),
	'book.biography.c' => decode_utf8('skupinová biografie'),
	'book.biography.d' => decode_utf8('obsahuje biografické informace'),
	'book.biography.|' => decode_utf8('kód se neuvádí'),

	# computer files
	# Undefined
	# Target audience
	# Form of item
	# Undefined
	'Type of computer file' => decode_utf8('Typ počítačového souboru'),
	# Undefined
	# Government publication
	# Undefined

	# computer_file - Form of item.
	'computer_file.form_of_item._' => decode_utf8('žádný z uvedených'),
	'computer_file.form_of_item.o' => decode_utf8('online zdroj'),
	'computer_file.form_of_item.q' => decode_utf8('přímo elektronický'),
	'computer_file.form_of_item.|' => decode_utf8('kód se neuvádí'),

	# computer_file - Type of computer file
	'computer_file.type_of_computer_file.a' => decode_utf8('numerická data'),
	'computer_file.type_of_computer_file.b' => decode_utf8('počítačový program'),
	'computer_file.type_of_computer_file.c' => decode_utf8('reprezentační data'),
	'computer_file.type_of_computer_file.d' => decode_utf8('dokument'),
	'computer_file.type_of_computer_file.e' => decode_utf8('bibliografická data'),
	'computer_file.type_of_computer_file.f' => decode_utf8('font'),
	'computer_file.type_of_computer_file.g' => decode_utf8('hra'),
	'computer_file.type_of_computer_file.h' => decode_utf8('zvuk'),
	'computer_file.type_of_computer_file.i' => decode_utf8('interaktivní multimédia'),
	'computer_file.type_of_computer_file.j' => decode_utf8('online systém / služba'),
	'computer_file.type_of_computer_file.m' => decode_utf8('kombinace'),
	'computer_file.type_of_computer_file.u' => decode_utf8('neznámý'),
	'computer_file.type_of_computer_file.z' => decode_utf8('jiný'),
	'computer_file.type_of_computer_file.|' => decode_utf8('kód se neuvádí'),

	# maps
	'Relief' => decode_utf8('Relief'),
	'Projection' => decode_utf8('Kartografická projekce'),
	# Undefined
	'Type of cartographic material' => decode_utf8('Typ kartografického dokumentu'),
	# Undefined
	# Government publication
	# Form of item
	# Undefined
	# Index
	# Undefined
	'Special format characteristics' => decode_utf8('Zvláštní formální charakteristiky'),

	# map - Relief.
	'map.relief._' => decode_utf8('reliéf není znázorněn'),
	'map.relief.a' => decode_utf8('vrstevnice'),
	'map.relief.b' => decode_utf8('stínování'),
	'map.relief.c' => decode_utf8('hypsometrické a batymetrické barevné stupnice'),
	'map.relief.d' => decode_utf8('šrafy'),
	'map.relief.e' => decode_utf8('batymetrie / hloubkové údaje'),
	'map.relief.f' => decode_utf8('tvarové čáry'),
	'map.relief.g' => decode_utf8('kótované výšky'),
	'map.relief.i' => decode_utf8('obrazové znázornění'),
	'map.relief.j' => decode_utf8('tvary reliéfu (geomorfologické prvky)'),
	'map.relief.k' => decode_utf8('batymetrie / izolinie'),
	'map.relief.m' => decode_utf8('kresba skal (skalní kresba)'),
	'map.relief.z' => decode_utf8('jiné'),
	'map.relief.|' => decode_utf8('kód se neuvádí'),

	# map - Projection.
	'map.projection.__' => decode_utf8('projekce neuvedena'),
	'map.projection.aa' => decode_utf8('Aitoffova projekce'),
	'map.projection.ab' => decode_utf8('gnomonická projekce'),
	'map.projection.ac' => decode_utf8('Lambertova azimutální plochojevná projekce'),
	'map.projection.ad' => decode_utf8('ortografická projekce'),
	'map.projection.ae' => decode_utf8('azimutální ekvidistantní projekce'),
	'map.projection.af' => decode_utf8('stereografická projekce'),
	'map.projection.ag' => decode_utf8('obecná vertikální (near-sided) projekce'),
	'map.projection.am' => decode_utf8('modifikovaná stereografická projekce pro Aljašku'),
	'map.projection.an' => decode_utf8('Chamberlinova trimetrická projekce'),
	'map.projection.ap' => decode_utf8('polární stereografická projekce'),
	'map.projection.au' => decode_utf8('azimutální projekce – blíže neurčená'),
	'map.projection.az' => decode_utf8('azimutální projekce – jiná'),
	'map.projection.ba' => decode_utf8('Gallova projekce'),
	'map.projection.bb' => decode_utf8('Goodova homolografická projekce'),
	'map.projection.bc' => decode_utf8('Lambertova válcová plochojevná projekce'),
	'map.projection.bd' => decode_utf8('Mercatorova projekce'),
	'map.projection.be' => decode_utf8('Millerova projekce'),
	'map.projection.bf' => decode_utf8('Mollweideova projekce'),
	'map.projection.bg' => decode_utf8('sinusoidální projekce'),
	'map.projection.bh' => decode_utf8('příčná Mercatorova projekce'),
	'map.projection.bi' => decode_utf8('Gaussova–Krügerova projekce'),
	'map.projection.bj' => decode_utf8('ekvidistantní válcová projekce (equirektangulární)'),
	'map.projection.bk' => decode_utf8('Křovákova projekce'),
	'map.projection.bl' => decode_utf8('Cassiniho–Soldnerova projekce'),
	'map.projection.bo' => decode_utf8('šikmá Mercatorova projekce'),
	'map.projection.br' => decode_utf8('Robinsonova projekce'),
	'map.projection.bs' => decode_utf8('prostorová šikmá Mercatorova projekce'),
	'map.projection.bu' => decode_utf8('válcová projekce – blíže neurčená'),
	'map.projection.bz' => decode_utf8('válcová projekce – jiná'),
	'map.projection.ca' => decode_utf8('Albersova plochojevná kuželová projekce'),
	'map.projection.cb' => decode_utf8('Bonneova projekce'),
	'map.projection.cc' => decode_utf8('Lambertova konformní kuželová projekce'),
	'map.projection.ce' => decode_utf8('ekvidistantní kuželová projekce'),
	'map.projection.cp' => decode_utf8('polykuželová projekce'),
	'map.projection.cu' => decode_utf8('kuželová projekce – blíže neurčená'),
	'map.projection.cz' => decode_utf8('kuželová projekce – jiná'),
	'map.projection.da' => decode_utf8('Armadillo projekce'),
	'map.projection.db' => decode_utf8('Butterfly (motýlí) projekce'),
	'map.projection.dc' => decode_utf8('Eckertova projekce'),
	'map.projection.dd' => decode_utf8('Goodova homolosinová projekce'),
	'map.projection.de' => decode_utf8('Millerova bipolární šikmá konformní kuželová projekce'),
	'map.projection.df' => decode_utf8('Van der Grintenova projekce'),
	'map.projection.dg' => decode_utf8('Dymaxion projekce'),
	'map.projection.dh' => decode_utf8('kordiformní projekce (srdcovitá)'),
	'map.projection.dl' => decode_utf8('Lambertova konformní projekce'),
	'map.projection.zz' => decode_utf8('jiná projekce'),
	'map.projection.||' => decode_utf8('kód se neuvádí'),

	# map - Type of cartographic material.
	'map.type_of_cartographic_material.a' => decode_utf8('samostatná mapa'),
	'map.type_of_cartographic_material.b' => decode_utf8('mapová řada'),
	'map.type_of_cartographic_material.c' => decode_utf8('mapový seriál'),
	'map.type_of_cartographic_material.d' => decode_utf8('glóbus'),
	'map.type_of_cartographic_material.e' => decode_utf8('atlas'),
	'map.type_of_cartographic_material.f' => decode_utf8('samostatná příloha k jinému dílu'),
	'map.type_of_cartographic_material.g' => decode_utf8('součást jiného díla'),
	'map.type_of_cartographic_material.r' => decode_utf8('snímek dálkového průzkumu Země'),
	'map.type_of_cartographic_material.u' => decode_utf8('neznámý'),
	'map.type_of_cartographic_material.z' => decode_utf8('jiný'),
	'map.type_of_cartographic_material.|' => decode_utf8('kód se neuvádí'),

	# map - Special format characteristics.
	'map.special_format_characteristics._' => decode_utf8('žádné zvláštní formální charakteristiky'),
	'map.special_format_characteristics.e' => decode_utf8('rukopis'),
	'map.special_format_characteristics.j' => decode_utf8('obrázková karta, pohlednice'),
	'map.special_format_characteristics.k' => decode_utf8('kalendář'),
	'map.special_format_characteristics.l' => decode_utf8('skládačka (puzzle)'),
	'map.special_format_characteristics.n' => decode_utf8('hra'),
	'map.special_format_characteristics.o' => decode_utf8('nástěnná mapa'),
	'map.special_format_characteristics.p' => decode_utf8('hrací karty'),
	'map.special_format_characteristics.r' => decode_utf8('volné listy'),
	'map.special_format_characteristics.z' => decode_utf8('jiné'),
	'map.special_format_characteristics.|' => decode_utf8('kód se neuvádí'),

	# music
	'Form of composition' => decode_utf8('Forma hudebního díla'),
	'Format of music' => decode_utf8('Hudební zápis'),
	'Music parts' => decode_utf8('Hlasy'),
	# Target audience
	# Form of item
	'Accompanying matter' => decode_utf8('Doprovodný materiál'),
	'Literary text for sound recordings' => decode_utf8('Textová složka zvukového záznamu'),
	# Undefined
	'Transposition and arrangement' => decode_utf8('Transpozice a aranžmá'),
	# Undefined

	# music - Form of composition.
	'music.form_of_composition.an' => decode_utf8('anthemy'),
	'music.form_of_composition.bd' => decode_utf8('balady'),
	'music.form_of_composition.bg' => decode_utf8('bluegrass'),
	'music.form_of_composition.bl' => decode_utf8('blues'),
	'music.form_of_composition.bt' => decode_utf8('balety'),
	'music.form_of_composition.ca' => decode_utf8('chaconny'),
	'music.form_of_composition.cb' => decode_utf8('zpěvy (jiná náboženství)'),
	'music.form_of_composition.cc' => decode_utf8('křesťanský chorál'),
	'music.form_of_composition.cg' => decode_utf8('concerto grosso'),
	'music.form_of_composition.ch' => decode_utf8('chorály'),
	'music.form_of_composition.cl' => decode_utf8('chorální předehry'),
	'music.form_of_composition.cn' => decode_utf8('kánony a ronda'),
	'music.form_of_composition.co' => decode_utf8('koncerty'),
	'music.form_of_composition.cp' => decode_utf8('polyfonní šansony'),
	'music.form_of_composition.cr' => decode_utf8('koledy'),
	'music.form_of_composition.cs' => decode_utf8('aleatorní skladby'),
	'music.form_of_composition.ct' => decode_utf8('kantáty'),
	'music.form_of_composition.cy' => decode_utf8('country hudba'),
	'music.form_of_composition.cz' => decode_utf8('canzony'),
	'music.form_of_composition.df' => decode_utf8('taneční formy'),
	'music.form_of_composition.dv' => decode_utf8('divertimenta, serenády, kasace, divertissementy, nokturna'),
	'music.form_of_composition.fg' => decode_utf8('fugy'),
	'music.form_of_composition.fl' => decode_utf8('flamenco'),
	'music.form_of_composition.fm' => decode_utf8('lidová hudba'),
	'music.form_of_composition.ft' => decode_utf8('fantazie'),
	'music.form_of_composition.gm' => decode_utf8('gospel'),
	'music.form_of_composition.hy' => decode_utf8('hymny'),
	'music.form_of_composition.jz' => decode_utf8('jazz'),
	'music.form_of_composition.mc' => decode_utf8('hudební revue a komedie'),
	'music.form_of_composition.md' => decode_utf8('madrigaly'),
	'music.form_of_composition.mi' => decode_utf8('menuety'),
	'music.form_of_composition.mo' => decode_utf8('moteta'),
	'music.form_of_composition.mp' => decode_utf8('filmová hudba'),
	'music.form_of_composition.mr' => decode_utf8('pochody'),
	'music.form_of_composition.ms' => decode_utf8('mše'),
	'music.form_of_composition.mu' => decode_utf8('více forem'),
	'music.form_of_composition.mz' => decode_utf8('mazurky'),
	'music.form_of_composition.nc' => decode_utf8('nokturna'),
	'music.form_of_composition.nn' => decode_utf8('nelze použít'),
	'music.form_of_composition.op' => decode_utf8('opery'),
	'music.form_of_composition.or' => decode_utf8('oratoria'),
	'music.form_of_composition.ov' => decode_utf8('předehry'),
	'music.form_of_composition.pg' => decode_utf8('programní hudba'),
	'music.form_of_composition.pm' => decode_utf8('pašije'),
	'music.form_of_composition.po' => decode_utf8('polonézy'),
	'music.form_of_composition.pp' => decode_utf8('populární hudba'),
	'music.form_of_composition.pr' => decode_utf8('preludia'),
	'music.form_of_composition.ps' => decode_utf8('passacaglie'),
	'music.form_of_composition.pt' => decode_utf8('vícehlasé písně'),
	'music.form_of_composition.pv' => decode_utf8('pavany'),
	'music.form_of_composition.rc' => decode_utf8('rocková hudba'),
	'music.form_of_composition.rd' => decode_utf8('ronda'),
	'music.form_of_composition.rg' => decode_utf8('ragtime'),
	'music.form_of_composition.ri' => decode_utf8('ricercary'),
	'music.form_of_composition.rp' => decode_utf8('rapsodie'),
	'music.form_of_composition.rq' => decode_utf8('rekviem'),
	'music.form_of_composition.sd' => decode_utf8('square dance'),
	'music.form_of_composition.sg' => decode_utf8('písně'),
	'music.form_of_composition.sn' => decode_utf8('sonáty'),
	'music.form_of_composition.sp' => decode_utf8('symfonické básně'),
	'music.form_of_composition.st' => decode_utf8('studie a cvičení'),
	'music.form_of_composition.su' => decode_utf8('suité'),
	'music.form_of_composition.sy' => decode_utf8('symfonie'),
	'music.form_of_composition.tc' => decode_utf8('toccaty'),
	'music.form_of_composition.tl' => decode_utf8('teatro lirico'),
	'music.form_of_composition.ts' => decode_utf8('triové sonáty'),
	'music.form_of_composition.uu' => decode_utf8('neznámé'),
	'music.form_of_composition.vi' => decode_utf8('villancicos'),
	'music.form_of_composition.vr' => decode_utf8('variace'),
	'music.form_of_composition.wz' => decode_utf8('valčíky'),
	'music.form_of_composition.za' => decode_utf8('zarzuely'),
	'music.form_of_composition.za' => decode_utf8('jiné'),
	'music.form_of_composition.||' => decode_utf8('kód se neuvádí'),

	# music - Format of music.
	'music.format_of_music.a' => decode_utf8('úplná partitura'),
	'music.format_of_music.b' => decode_utf8('zmenšená (studijní) partitura'),
	'music.format_of_music.c' => decode_utf8('doprovod redukovaný pro klávesový nástroj'),
	'music.format_of_music.d' => decode_utf8('vokální partitura bez doprovodu'),
	'music.format_of_music.e' => decode_utf8('zhuštěná partitura / klavírní dirigentská partitura'),
	'music.format_of_music.g' => decode_utf8('uzavřená partitura'),
	'music.format_of_music.h' => decode_utf8('sborová partitura'),
	'music.format_of_music.i' => decode_utf8('zhuštěná partitura'),
	'music.format_of_music.j' => decode_utf8('part pro interpreta-dirigenta'),
	'music.format_of_music.k' => decode_utf8('vokální partitura'),
	'music.format_of_music.l' => decode_utf8('partitura'),
	'music.format_of_music.m' => decode_utf8('více forem zápisu'),
	'music.format_of_music.n' => decode_utf8('nelze použít'),
	'music.format_of_music.p' => decode_utf8('klavírní partitura'),
	'music.format_of_music.u' => decode_utf8('neznámý'),
	'music.format_of_music.z' => decode_utf8('jiný'),
	'music.format_of_music.|' => decode_utf8('kód se neuvádí'),

	# music - Music parts.
	'music.music_parts._' => decode_utf8('hlasy nejsou k dispozici nebo nejsou specifikovány'),
	'music.music_parts.d' => decode_utf8('instrumentální a vokální hlasy'),
	'music.music_parts.e' => decode_utf8('instrumentální hlasy'),
	'music.music_parts.f' => decode_utf8('vokální hlasy'),
	'music.music_parts.n' => decode_utf8('nelze použít'),
	'music.music_parts.u' => decode_utf8('neznámé'),
	'music.music_parts.|' => decode_utf8('kód se neuvádí'),

	# music - Accompanying matter.
	'music.accompanying_matter._' => decode_utf8('bez doprovodného materiálu'),
	'music.accompanying_matter.a' => decode_utf8('diskografie'),
	'music.accompanying_matter.b' => decode_utf8('bibliografie'),
	'music.accompanying_matter.c' => decode_utf8('tematický katalog'),
	'music.accompanying_matter.d' => decode_utf8('libreto nebo text'),
	'music.accompanying_matter.e' => decode_utf8('životopis skladatele nebo autora'),
	'music.accompanying_matter.f' => decode_utf8('životopis interpreta nebo historie souboru'),
	'music.accompanying_matter.g' => decode_utf8('technické a/nebo historické informace o nástrojích'),
	'music.accompanying_matter.h' => decode_utf8('technické informace o hudbě'),
	'music.accompanying_matter.i' => decode_utf8('historické informace'),
	'music.accompanying_matter.k' => decode_utf8('etnologické informace'),
	'music.accompanying_matter.r' => decode_utf8('instruktážní materiály'),
	'music.accompanying_matter.s' => decode_utf8('hudba (notový materiál jako doplněk)'),
	'music.accompanying_matter.z' => decode_utf8('jiné'),
	'music.accompanying_matter.|' => decode_utf8('kód se neuvádí'),

	# music - Literary text for sound recordings.
	'music.literary_text_for_sound_recordings._' => decode_utf8('hudební zvukový záznam'),
	'music.literary_text_for_sound_recordings.a' => decode_utf8('autobiografie'),
	'music.literary_text_for_sound_recordings.b' => decode_utf8('biografie'),
	'music.literary_text_for_sound_recordings.c' => decode_utf8('sborník z konference'),
	'music.literary_text_for_sound_recordings.d' => decode_utf8('drama'),
	'music.literary_text_for_sound_recordings.e' => decode_utf8('eseje'),
	'music.literary_text_for_sound_recordings.f' => decode_utf8('beletrie'),
	'music.literary_text_for_sound_recordings.g' => decode_utf8('zpravodajství / reportáže'),
	'music.literary_text_for_sound_recordings.h' => decode_utf8('historie'),
	'music.literary_text_for_sound_recordings.i' => decode_utf8('instruktáž / výuka'),
	'music.literary_text_for_sound_recordings.j' => decode_utf8('jazyková výuka'),
	'music.literary_text_for_sound_recordings.k' => decode_utf8('komedie'),
	'music.literary_text_for_sound_recordings.l' => decode_utf8('přednášky, projevy'),
	'music.literary_text_for_sound_recordings.m' => decode_utf8('paměti'),
	'music.literary_text_for_sound_recordings.n' => decode_utf8('nelze použít'),
	'music.literary_text_for_sound_recordings.o' => decode_utf8('lidové pohádky'),
	'music.literary_text_for_sound_recordings.p' => decode_utf8('poezie'),
	'music.literary_text_for_sound_recordings.r' => decode_utf8('zkoušky'),
	'music.literary_text_for_sound_recordings.s' => decode_utf8('zvuky'),
	'music.literary_text_for_sound_recordings.t' => decode_utf8('rozhovory'),
	'music.literary_text_for_sound_recordings.z' => decode_utf8('jiné'),
	'music.literary_text_for_sound_recordings.|' => decode_utf8('kód se neuvádí'),

	# music - Transposition and arrangement.
	'music.transposition_and_arrangement._' => decode_utf8('nejde o transpozici ani aranžmá'),
	'music.transposition_and_arrangement.a' => decode_utf8('transpozice'),
	'music.transposition_and_arrangement.b' => decode_utf8('aranžmá'),
	'music.transposition_and_arrangement.c' => decode_utf8('transpozice i aranžmá'),
	'music.transposition_and_arrangement.n' => decode_utf8('nelze použít'),
	'music.transposition_and_arrangement.u' => decode_utf8('neznámé'),
	'music.transposition_and_arrangement.|' => decode_utf8('kód se neuvádí'),

	# continuing resources
	'Frequency' => decode_utf8('Periodicita'),
	'Regularity' => decode_utf8('Pravidelnost'),
	# Undefined
	'Type of continuing resource' => decode_utf8('Typ pokračujícího zdroje'),
	'Form of original item' => decode_utf8('Forma původního dokumentu'),
	# Form of item
	'Nature of entire work' => decode_utf8('Charakter celého díla'),
	# Nature of contents
	# Government publication
	# Conference publication
	# Undefined
	'Original alphabet or script of title' => decode_utf8('Původní abeceda nebo písmo názvu'),
	'Entry convention' => decode_utf8('Konvence záhlaví'),

	# continuing_resources - Frequency.
	'continuing_resource.frequency._' => decode_utf8('nelze určit periodicitu'),
	'continuing_resource.frequency.a' => decode_utf8('ročně'),
	'continuing_resource.frequency.b' => decode_utf8('dvouměsíčně'),
	'continuing_resource.frequency.c' => decode_utf8('dvakrát týdně'),
	'continuing_resource.frequency.d' => decode_utf8('denně'),
	'continuing_resource.frequency.e' => decode_utf8('jednou za dva týdny'),
	'continuing_resource.frequency.f' => decode_utf8('pololetně'),
	'continuing_resource.frequency.g' => decode_utf8('jednou za dva roky'),
	'continuing_resource.frequency.h' => decode_utf8('jednou za tři roky'),
	'continuing_resource.frequency.i' => decode_utf8('třikrát týdně'),
	'continuing_resource.frequency.j' => decode_utf8('třikrát měsíčně'),
	'continuing_resource.frequency.k' => decode_utf8('průběžně aktualizováno'),
	'continuing_resource.frequency.m' => decode_utf8('měsíčně'),
	'continuing_resource.frequency.q' => decode_utf8('čtvrtletně'),
	'continuing_resource.frequency.s' => decode_utf8('dvakrát měsíčně'),
	'continuing_resource.frequency.t' => decode_utf8('třikrát ročně'),
	'continuing_resource.frequency.u' => decode_utf8('neznámá periodicita'),
	'continuing_resource.frequency.w' => decode_utf8('týdně'),
	'continuing_resource.frequency.z' => decode_utf8('jiná periodicita'),
	'continuing_resource.frequency.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Regularity.
	'continuing_resource.regularity.n' => decode_utf8('normalizovaně nepravidelná'),
	'continuing_resource.regularity.r' => decode_utf8('pravidelná'),
	'continuing_resource.regularity.u' => decode_utf8('neznámá'),
	'continuing_resource.regularity.x' => decode_utf8('zcela nepravidelná'),
	'continuing_resource.regularity.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Type of continuing resource.
	'continuing_resources.type_of_continuing_resource._' => decode_utf8('žádný z uvedených typů'),
	'continuing_resources.type_of_continuing_resource.d' => decode_utf8('aktualizovaná databáze'),
	'continuing_resources.type_of_continuing_resource.g' => decode_utf8('časopis'),
	'continuing_resources.type_of_continuing_resource.h' => decode_utf8('blog'),
	'continuing_resources.type_of_continuing_resource.j' => decode_utf8('odborný časopis'),
	'continuing_resources.type_of_continuing_resource.l' => decode_utf8('aktualizované volné listy'),
	'continuing_resources.type_of_continuing_resource.m' => decode_utf8('monografická řada'),
	'continuing_resources.type_of_continuing_resource.n' => decode_utf8('noviny'),
	'continuing_resources.type_of_continuing_resource.p' => decode_utf8('periodikum'),
	'continuing_resources.type_of_continuing_resource.r' => decode_utf8('repozitář'),
	'continuing_resources.type_of_continuing_resource.s' => decode_utf8('zpravodaj'),
	'continuing_resources.type_of_continuing_resource.t' => decode_utf8('adresář'),
	'continuing_resources.type_of_continuing_resource.w' => decode_utf8('aktualizovaná webová stránka'),
	'continuing_resources.type_of_continuing_resource.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Form of original item.
	'continuing_resource.form_of_original_item._' => decode_utf8('žádná z uvedených forem'),
	'continuing_resource.form_of_original_item.a' => decode_utf8('mikrofilm'),
	'continuing_resource.form_of_original_item.b' => decode_utf8('mikrofiš'),
	'continuing_resource.form_of_original_item.c' => decode_utf8('mikrotisk'),
	'continuing_resource.form_of_original_item.d' => decode_utf8('velké písmo'),
	'continuing_resource.form_of_original_item.e' => decode_utf8('novinový formát'),
	'continuing_resource.form_of_original_item.f' => decode_utf8('Braillovo písmo'),
	'continuing_resource.form_of_original_item.o' => decode_utf8('online'),
	'continuing_resource.form_of_original_item.q' => decode_utf8('přímo elektronický'),
	'continuing_resource.form_of_original_item.s' => decode_utf8('elektronický'),
	'continuing_resource.form_of_original_item.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Nature of entire work.
	'continuing_resource.nature_of_entire_work._' => decode_utf8('není specifikováno'),
	'continuing_resource.nature_of_entire_work.a' => decode_utf8('abstrakty / souhrny'),
	'continuing_resource.nature_of_entire_work.b' => decode_utf8('bibliografie'),
	'continuing_resource.nature_of_entire_work.c' => decode_utf8('katalogy'),
	'continuing_resource.nature_of_entire_work.d' => decode_utf8('slovníky'),
	'continuing_resource.nature_of_entire_work.e' => decode_utf8('encyklopedie'),
	'continuing_resource.nature_of_entire_work.f' => decode_utf8('příručky'),
	'continuing_resource.nature_of_entire_work.g' => decode_utf8('právní články'),
	'continuing_resource.nature_of_entire_work.h' => decode_utf8('biografie'),
	'continuing_resource.nature_of_entire_work.i' => decode_utf8('rejstříky'),
	'continuing_resource.nature_of_entire_work.k' => decode_utf8('diskografie'),
	'continuing_resource.nature_of_entire_work.l' => decode_utf8('legislativa'),
	'continuing_resource.nature_of_entire_work.m' => decode_utf8('disertace'),
	'continuing_resource.nature_of_entire_work.n' => decode_utf8('přehledy literatury v oboru'),
	'continuing_resource.nature_of_entire_work.o' => decode_utf8('recenze'),
	'continuing_resource.nature_of_entire_work.p' => decode_utf8('programované texty'),
	'continuing_resource.nature_of_entire_work.q' => decode_utf8('filmografie'),
	'continuing_resource.nature_of_entire_work.r' => decode_utf8('adresáře'),
	'continuing_resource.nature_of_entire_work.s' => decode_utf8('statistiky'),
	'continuing_resource.nature_of_entire_work.t' => decode_utf8('technické zprávy'),
	'continuing_resource.nature_of_entire_work.u' => decode_utf8('normy / specifikace'),
	'continuing_resource.nature_of_entire_work.v' => decode_utf8('soudní případy a komentáře k nim'),
	'continuing_resource.nature_of_entire_work.w' => decode_utf8('sbírky rozhodnutí a právní přehledy'),
	'continuing_resource.nature_of_entire_work.y' => decode_utf8('ročenky'),
	'continuing_resource.nature_of_entire_work.z' => decode_utf8('smlouvy'),
	'continuing_resource.nature_of_entire_work.5' => decode_utf8('kalendáře'),
	'continuing_resource.nature_of_entire_work.6' => decode_utf8('komiksy / grafické romány'),
	'continuing_resource.nature_of_entire_work.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Original alphabet or script of title.
	'continuing_resource.original_alphabet_or_script_of_title._' => decode_utf8('není uvedena abeceda/písmo / není klíčový název'),
	'continuing_resource.original_alphabet_or_script_of_title.a' => decode_utf8('základní latinka'),
	'continuing_resource.original_alphabet_or_script_of_title.b' => decode_utf8('rozšířená latinka'),
	'continuing_resource.original_alphabet_or_script_of_title.c' => decode_utf8('cyrilice'),
	'continuing_resource.original_alphabet_or_script_of_title.d' => decode_utf8('japonské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.e' => decode_utf8('čínské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.f' => decode_utf8('arabské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.g' => decode_utf8('řecké písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.h' => decode_utf8('hebrejské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.i' => decode_utf8('thajské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.j' => decode_utf8('dévanágarí'),
	'continuing_resource.original_alphabet_or_script_of_title.k' => decode_utf8('korejské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.l' => decode_utf8('tamilské písmo'),
	'continuing_resource.original_alphabet_or_script_of_title.u' => decode_utf8('neznámé'),
	'continuing_resource.original_alphabet_or_script_of_title.z' => decode_utf8('jiné'),
	'continuing_resource.original_alphabet_or_script_of_title.|' => decode_utf8('kód se neuvádí'),

	# continuing_resources - Entry convention.
	'continuing_resources.entry_convention.0' => decode_utf8('postupné záhlaví'),
	'continuing_resources.entry_convention.1' => decode_utf8('nejnovější záhlaví'),
	'continuing_resources.entry_convention.2' => decode_utf8('integrované záhlaví'),
	'continuing_resources.entry_convention.|' => decode_utf8('kód se neuvádí'),

	# visual materials
	'Running time for motion pictures and videorecordings' => decode_utf8('Délka trvání (filmu / videonahrávky)'),
	# Undefined
	# Target audience
	# Undefined
	# Government publication
	# Form of item
	# Undefined
	'Type of visual material' => decode_utf8('Typ vizuálního dokumentu'),
	'Technique' => decode_utf8('Technika'),

	# visual_material - Running time for motion pictures and videorecordings.
	'visual_material.running_time_for_motion_pictures_and_videorecordings.000' => decode_utf8('délka trvání přesahuje tři znaky'),
	'visual_material.running_time_for_motion_pictures_and_videorecordings.001' => decode_utf8('délka trvání'),
	'visual_material.running_time_for_motion_pictures_and_videorecordings.nnn' => decode_utf8('nelze použít'),
	'visual_material.running_time_for_motion_pictures_and_videorecordings.---' => decode_utf8('neznámá délka trvání'),
	'visual_material.running_time_for_motion_pictures_and_videorecordings.|||' => decode_utf8('kód se neuvádí'),

	# visual_material - Type of visual material.
	'visual_material.type_of_visual_material.a' => decode_utf8('originál výtvarného díla'),
	'visual_material.type_of_visual_material.b' => decode_utf8('soubor'),
	'visual_material.type_of_visual_material.c' => decode_utf8('reprodukce výtvarného díla'),
	'visual_material.type_of_visual_material.d' => decode_utf8('dioráma'),
	'visual_material.type_of_visual_material.f' => decode_utf8('filmový pás'),
	'visual_material.type_of_visual_material.g' => decode_utf8('hra'),
	'visual_material.type_of_visual_material.i' => decode_utf8('obraz'),
	'visual_material.type_of_visual_material.k' => decode_utf8('grafika'),
	'visual_material.type_of_visual_material.l' => decode_utf8('technický výkres'),
	'visual_material.type_of_visual_material.m' => decode_utf8('film'),
	'visual_material.type_of_visual_material.n' => decode_utf8('diagram / schéma'),
	'visual_material.type_of_visual_material.o' => decode_utf8('výukové kartičky'),
	'visual_material.type_of_visual_material.p' => decode_utf8('mikroskopický preparát'),
	'visual_material.type_of_visual_material.q' => decode_utf8('model'),
	'visual_material.type_of_visual_material.r' => decode_utf8('reálie'),
	'visual_material.type_of_visual_material.s' => decode_utf8('diapozitiv'),
	'visual_material.type_of_visual_material.t' => decode_utf8('transparent'),
	'visual_material.type_of_visual_material.v' => decode_utf8('videonahrávka'),
	'visual_material.type_of_visual_material.w' => decode_utf8('hračka'),
	'visual_material.type_of_visual_material.z' => decode_utf8('jiné'),
	'visual_material.type_of_visual_material.|' => decode_utf8('kód se neuvádí'),

	# visual_material - Technique.
	'visual_material.technique.a' => decode_utf8('animace'),
	'visual_material.technique.c' => decode_utf8('animace a hraný film'),
	'visual_material.technique.l' => decode_utf8('hraný film'),
	'visual_material.technique.n' => decode_utf8('nelze použít'),
	'visual_material.technique.u' => decode_utf8('neznámá'),
	'visual_material.technique.z' => decode_utf8('jiná'),
	'visual_material.technique.|' => decode_utf8('kód se neuvádí'),

	# mixed materials
	# Undefined
	# Form of item
	# Undefined

);

1;

__END__
