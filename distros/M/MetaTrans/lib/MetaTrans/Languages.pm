=head1 NAME

MetaTrans::Languages - Simple "database" of most of the known languages.
Extracted from I<MARC codes for languages>,
L<http://www.loc.gov/marc/languages/>.

=head1 SYNOPSIS

    use MetaTrans::Languages qw(get_lang_by_code get_code_by_lang);

    print get_lang_by_code('afr');       # prints 'Afrikaans'
    print get_code_by_lang('Afrikaans'); # prints 'afr'

=cut

package MetaTrans::Languages;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

$VERSION   = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA       = qw(Exporter);
@EXPORT_OK = qw(is_known_lang get_lang_by_code get_code_by_lang
    get_langs_hash get_langs_hash_rev);

my %Languages;      # code => language
my %RevLanguages;   # language => code

=head1 FUNCTIONS

=over 4

=cut

=item get_lang_by_code($code)

Returns the name of the language with C<$code> or C<undef> if no
language with such a C<$code> is known.

=cut

sub get_lang_by_code
{
    my $code = shift;
    return $Languages{$code};
}

=item get_code_by_lang($language)

Returns the code of the C<$language> or C<undef> if the language
is unknown.

=cut

sub get_code_by_lang
{
    my $code = shift;
    return $RevLanguages{$code};
}

=item is_known_lang($code)

Returns C<true> if the language with C<$code> exists in the "database",
C<false> otherwise.

=cut

sub is_known_lang
{
    my $code = shift;
    return exists $Languages{$code};
}

=item get_langs_hash

Returns the C<< {code_1 => language_1, code_2 => language_2, ...} >>
hash containing all known languages and their codes.

=cut

sub get_langs_hash
{
    return %Languages;
}

=item get_langs_hash_rev

Returns the C<< {language_1 => code_1, language_2 => code_2, ...} >>
hash containing all known languages and their codes.

=cut

sub get_langs_hash_rev
{
    return %RevLanguages;
}

=back

=cut

%Languages = (
    afr => "Afrikaans",
    alb => "Albanian",
    arm => "Armenian",
    aze => "Azerbaijani",
    baq => "Basque",
    bel => "Belarusian",
    bos => "Bosnian",
    bul => "Bulgarian",
    cat => "Catalan",
    chi => "Chinese",
    chs => "Chinese (simplified)", # added (not a MARC code)
    scr => "Croatian",
    cze => "Czech",
    dan => "Danish",
    dut => "Dutch",
    egy => "Egyptian",
    eng => "English",
    epo => "Esperanto",
    est => "Estonian",
    gez => "Ethiopic",
    fin => "Finnish",
    fre => "French",
    ger => "German",
    gre => "Greek",
    heb => "Hebrew",
    hun => "Hungarian",
    ice => "Icelandic",
    inc => "Indic",
    ind => "Indonesian",
    ira => "Iranian",
    gle => "Irish",
    ita => "Italian",
    jpn => "Japanese",
    kor => "Korean",
    kur => "Kurdish",
    lat => "Latin",
    lav => "Latvian",
    lit => "Lithuanian",
    mol => "Moldavian",
    nav => "Navajo",
    nor => "Norwegian",
    phi => "Philippine",
    pol => "Polish",
    por => "Portuguese",
    rum => "Romanian",
    rus => "Russian",
    srd => "Sardinian",
    scc => "Serbian",
    slo => "Slovak",
    slv => "Slovenian",
    som => "Somali",
    spa => "Spanish",
    swa => "Swahili",
    swe => "Swedish",
    syr => "Syriac",
    tah => "Tahitian",
    tat => "Tatar",
    tha => "Thai",
    tib => "Tibetan",
    tur => "Turkish",
    ukr => "Ukrainian",
    uzb => "Uzbek",
    vie => "Vietnamese",
    wel => "Welsh",
    yid => "Yiddish",

    abk => "Abkhaz",
    ace => "Achinese",
    ach => "Acoli",
    ada => "Adangme",
    ady => "Adygei",
    aar => "Afar",
    afh => "Afrihili",
    aka => "Akan",
    akk => "Akkadian",
    ale => "Aleut",
    alg => "Algonquian",
    tut => "Altaic",
    amh => "Amharic",
    ara => "Arabic",
    arg => "Aragonese Spanish",
    arc => "Aramaic",
    arp => "Arapaho",
    arw => "Arawak",
    asm => "Assamese",
    ath => "Athapascan",
    map => "Austronesian",
    ava => "Avaric",
    ave => "Avestan",
    awa => "Awadhi",
    aym => "Aymara",
    ast => "Bable",
    ban => "Balinese",
    bat => "Baltic",
    bal => "Baluchi",
    bam => "Bambara",
    bad => "Banda",
    bnt => "Bantu",
    bas => "Basa",
    bak => "Bashkir",
    btk => "Batak",
    bej => "Beja",
    bem => "Bemba",
    ben => "Bengali",
    ber => "Berber",
    bho => "Bhojpuri",
    bih => "Bihari",
    bik => "Bikol",
    bis => "Bislama",
    bra => "Braj",
    bre => "Breton",
    bug => "Bugis",
    bua => "Buriat",
    bur => "Burmese",
    cad => "Caddo",
    car => "Carib",
    cau => "Caucasian",
    ceb => "Cebuano",
    cel => "Celtic",
    cai => "Central American Indian",
    chg => "Chagatai",
    cha => "Chamorro",
    che => "Chechen",
    chr => "Cherokee",
    chy => "Cheyenne",
    chb => "Chibcha",
    chn => "Chinook jargon",
    chp => "Chipewyan",
    cho => "Choctaw",
    chu => "Church Slavic",
    chv => "Chuvash",
    cop => "Coptic",
    cor => "Cornish",
    cos => "Corsican",
    cre => "Cree",
    mus => "Creek",
    crp => "Creoles and Pidgins",
    cpe => "Creoles and Pidgins, English-based",
    cpf => "Creoles and Pidgins, French-based",
    cpp => "Creoles and Pidgins, Portuguese-based",
    crh => "Crimean Tatar",
    cus => "Cushitic",
    dak => "Dakota",
    dar => "Dargwa",
    day => "Dayak",
    del => "Delaware",
    din => "Dinka",
    div => "Divehi",
    doi => "Dogri",
    dgr => "Dogrib",
    dra => "Dravidian",
    dua => "Duala",
    dum => "Dutch, Middle",
    dyu => "Dyula",
    dzo => "Dzongkha",
    bin => "Edo",
    efi => "Efik",
    eka => "Ekajuk",
    elx => "Elamite",
    enm => "English, Middle",
    ang => "English, Old",
    ewe => "Ewe",
    ewo => "Ewondo",
    fan => "Fang",
    fat => "Fanti",
    fao => "Faroese",
    fij => "Fijian",
    fiu => "Finno-Ugrian",
    fon => "Fon",
    frm => "French, Middle",
    fro => "French, Old",
    fry => "Frisian",
    fur => "Friulian",
    ful => "Fula",
    glg => "Galician",
    lug => "Ganda",
    gay => "Gayo",
    gba => "Gbaya",
    geo => "Georgian",
    gmh => "German, Middle High",
    goh => "German, Old High",
    gem => "Germanic",
    gil => "Gilbertese",
    gon => "Gondi",
    gor => "Gorontalo",
    got => "Gothic",
    grb => "Grebo",
    grc => "Greek, Ancient",
    grn => "Guarani",
    guj => "Gujarati",
    hai => "Haida",
    hat => "Haitian French Creole",
    hau => "Hausa",
    haw => "Hawaiian",
    her => "Herero",
    hil => "Hiligaynon",
    him => "Himachali",
    hin => "Hindi",
    hmo => "Hiri Motu",
    hit => "Hittite",
    hmn => "Hmong",
    hup => "Hupa",
    iba => "Iban",
    ido => "Ido",
    ibo => "Igbo",
    ijo => "Ijo",
    ilo => "Iloko",
    smn => "Inari Sami",
    ine => "Indo-European",
    inh => "Ingush",
    ina => "Interlingua",
    ile => "Interlingue",
    iku => "Inuktitut",
    ipk => "Inupiaq",
    mga => "Irish, Middle",
    sga => "Irish, Old",
    iro => "Iroquoian",
    jav => "Javanese",
    jrb => "Judeo-Arabic",
    jpr => "Judeo-Persian",
    kab => "Kabyle",
    kac => "Kachin",
    xal => "Kalmyk",
    kam => "Kamba",
    kan => "Kannada",
    kau => "Kanuri",
    kaa => "Kara-Kalpak",
    kar => "Karen",
    kas => "Kashmiri",
    kaw => "Kawi",
    kaz => "Kazakh",
    kha => "Khasi",
    khm => "Khmer",
    khi => "Khoisan",
    kho => "Khotanese",
    kik => "Kikuyu",
    kmb => "Kimbundu",
    kin => "Kinyarwanda",
    kom => "Komi",
    kon => "Kongo",
    kok => "Konkani",
    kpe => "Kpelle",
    kro => "Kru",
    kua => "Kuanyama",
    kum => "Kumyk",
    kru => "Kurukh",
    kos => "Kusaie",
    kut => "Kutenai",
    kir => "Kyrgyz",
    lad => "Ladino",
    lah => "Lahnda",
    lam => "Lamba",
    lao => "Lao",
    ltz => "Letzeburgesch",
    lez => "Lezgian",
    lim => "Limburgish",
    lin => "Lingala",
    nds => "Low German",
    loz => "Lozi",
    lub => "Luba-Katanga",
    lua => "Luba-Lulua",
    smj => "Lule Sami",
    lun => "Lunda",
    luo => "Luo",
    lus => "Lushai",
    mac => "Macedonian",
    mad => "Madurese",
    mag => "Magahi",
    mai => "Maithili",
    mak => "Makasar",
    mlg => "Malagasy",
    may => "Malay",
    mal => "Malayalam",
    mlt => "Maltese",
    mnc => "Manchu",
    mdr => "Mandar",
    man => "Mandingo",
    mni => "Manipuri",
    glv => "Manx",
    mao => "Maori",
    arn => "Mapuche",
    mar => "Marathi",
    chm => "Mari",
    mah => "Marshallese",
    mwr => "Marwari",
    mas => "Masai",
    men => "Mende",
    mic => "Micmac",
    min => "Minangkabau",
    moh => "Mohawk",
    mkh => "Mon-Khmer",
    lol => "Mongo-Nkundu",
    mon => "Mongolian",
    mun => "Munda",
    nah => "Nahuatl",
    nau => "Nauru",
    nbl => "Ndebele",
    nde => "Ndebele",
    ndo => "Ndonga",
    nap => "Neapolitan Italian",
    nep => "Nepali",
    new => "Newari",
    nia => "Nias",
    nic => "Niger-Kordofanian",
    ssa => "Nilo-Saharan",
    niu => "Niuean",
    nog => "Nogai",
    nai => "North American Indian",
    sme => "Northern Sami",
    nso => "Northern Sotho",
    nym => "Nyamwezi",
    nya => "Nyanja",
    nyn => "Nyankole",
    nyo => "Nyoro",
    nzi => "Nzima",
    oci => "Occitan",
    oji => "Ojibwa",
    non => "Old Norse",
    peo => "Old Persian",
    ori => "Oriya",
    orm => "Oromo",
    osa => "Osage",
    oss => "Ossetic",
    pal => "Pahlavi",
    pau => "Palauan",
    pli => "Pali",
    pam => "Pampanga",
    pag => "Pangasinan",
    pan => "Panjabi",
    pap => "Papiamento",
    paa => "Papuan",
    per => "Persian",
    phn => "Phoenician",
    pon => "Ponape",
    pus => "Pushto",
    que => "Quechua",
    roh => "Raeto-Romance",
    raj => "Rajasthani",
    rap => "Rapanui",
    rar => "Rarotongan",
    roa => "Romance",
    rom => "Romani",
    run => "Rundi",
    sam => "Samaritan Aramaic",
    smi => "Sami",
    smo => "Samoan",
    sad => "Sandawe",
    sag => "Sango",
    san => "Sanskrit",
    sat => "Santali",
    sas => "Sasak",
    sco => "Scots",
    gla => "Scottish Gaelic",
    sel => "Selkup",
    sem => "Semitic",
    srr => "Serer",
    shn => "Shan",
    sna => "Shona",
    iii => "Sichuan Yi",
    sid => "Sidamo",
    bla => "Siksika",
    snd => "Sindhi",
    sin => "Sinhalese",
    sit => "Sino-Tibetan",
    sio => "Siouan",
    sms => "Skolt Sami",
    den => "Slave",
    sla => "Slavic",
    sog => "Sogdian",
    son => "Songhai",
    snk => "Soninke",
    sot => "Sotho",
    sai => "South American Indian",
    sma => "Southern Sami",
    suk => "Sukuma",
    sux => "Sumerian",
    sun => "Sundanese",
    sus => "Susu",
    ssw => "Swazi",
    tgl => "Tagalog",
    tai => "Tai",
    tgk => "Tajik",
    tmh => "Tamashek",
    tam => "Tamil",
    tel => "Telugu",
    tem => "Temne",
    ter => "Terena",
    tet => "Tetum",
    tir => "Tigrinya",
    tiv => "Tiv",
    tli => "Tlingit",
    tpi => "Tok Pisin",
    tkl => "Tokelauan",
    tog => "Tonga",
    ton => "Tongan",
    chk => "Truk",
    tsi => "Tsimshian",
    tso => "Tsonga",
    tsn => "Tswana",
    tum => "Tumbuka",
    ota => "Turkish, Ottoman",
    tuk => "Turkmen",
    tvl => "Tuvaluan",
    tyv => "Tuvinian",
    twi => "Twi",
    udm => "Udmurt",
    uga => "Ugaritic",
    uig => "Uighur",
    umb => "Umbundu",
    und => "Undetermined",
    urd => "Urdu",
    vai => "Vai",
    ven => "Venda",
    vot => "Votic",
    wal => "Walamo",
    wln => "Walloon",
    war => "Waray",
    was => "Washo",
    wol => "Wolof",
    xho => "Xhosa",
    sah => "Yakut",
    yao => "Yao",
    yap => "Yapese",
    yor => "Yoruba",
    znd => "Zande",
    zap => "Zapotec",
    zen => "Zenaga",
    zha => "Zhuang",
    zul => "Zulu",
    zun => "Zuni",
);

foreach my $code (keys %Languages)
{
    $RevLanguages{$Languages{$code}} = $code;
}

1;

__END__

=head1 LANGUAGE CODES

    CODE   LANGUAGE
    ----   ----------------------
    afr    Afrikaans
    alb    Albanian
    arm    Armenian
    aze    Azerbaijani
    baq    Basque
    bel    Belarusian
    bos    Bosnian
    bul    Bulgarian
    cat    Catalan
    chi    Chinese
    chs    Chinese (simplified)
    scr    Croatian
    cze    Czech
    dan    Danish
    dut    Dutch
    egy    Egyptian
    eng    English
    epo    Esperanto
    est    Estonian
    gez    Ethiopic
    fin    Finnish
    fre    French
    ger    German
    gre    Greek
    heb    Hebrew
    hun    Hungarian
    ice    Icelandic
    inc    Indic
    ind    Indonesian
    ira    Iranian
    gle    Irish
    ita    Italian
    jpn    Japanese
    kor    Korean
    kur    Kurdish
    lat    Latin
    lav    Latvian
    lit    Lithuanian
    mol    Moldavian
    nav    Navajo
    nor    Norwegian
    phi    Philippine
    pol    Polish
    por    Portuguese
    rum    Romanian
    rus    Russian
    srd    Sardinian
    scc    Serbian
    slo    Slovak
    slv    Slovenian
    som    Somali
    spa    Spanish
    swa    Swahili
    swe    Swedish
    syr    Syriac
    tah    Tahitian
    tat    Tatar
    tha    Thai
    tib    Tibetan
    tur    Turkish
    ukr    Ukrainian
    uzb    Uzbek
    vie    Vietnamese
    wel    Welsh
    yid    Yiddish

    abk    Abkhaz
    ace    Achinese
    ach    Acoli
    ada    Adangme
    ady    Adygei
    aar    Afar
    afh    Afrihili
    aka    Akan
    akk    Akkadian
    ale    Aleut
    alg    Algonquian
    tut    Altaic
    amh    Amharic
    ara    Arabic
    arg    Aragonese Spanish
    arc    Aramaic
    arp    Arapaho
    arw    Arawak
    asm    Assamese
    ath    Athapascan
    map    Austronesian
    ava    Avaric
    ave    Avestan
    awa    Awadhi
    aym    Aymara
    ast    Bable
    ban    Balinese
    bat    Baltic
    bal    Baluchi
    bam    Bambara
    bad    Banda
    bnt    Bantu
    bas    Basa
    bak    Bashkir
    btk    Batak
    bej    Beja
    bem    Bemba
    ben    Bengali
    ber    Berber
    bho    Bhojpuri
    bih    Bihari
    bik    Bikol
    bis    Bislama
    bra    Braj
    bre    Breton
    bug    Bugis
    bua    Buriat
    bur    Burmese
    cad    Caddo
    car    Carib
    cau    Caucasian
    ceb    Cebuano
    cel    Celtic
    cai    Central American Indian
    chg    Chagatai
    cha    Chamorro
    che    Chechen
    chr    Cherokee
    chy    Cheyenne
    chb    Chibcha
    chn    Chinook jargon
    chp    Chipewyan
    cho    Choctaw
    chu    Church Slavic
    chv    Chuvash
    cop    Coptic
    cor    Cornish
    cos    Corsican
    cre    Cree
    mus    Creek
    crp    Creoles and Pidgins
    cpe    Creoles and Pidgins English-based
    cpf    Creoles and Pidgins French-based
    cpp    Creoles and Pidgins Portuguese-based
    crh    Crimean Tatar
    cus    Cushitic
    dak    Dakota
    dar    Dargwa
    day    Dayak
    del    Delaware
    din    Dinka
    div    Divehi
    doi    Dogri
    dgr    Dogrib
    dra    Dravidian
    dua    Duala
    dum    Dutch Middle
    dyu    Dyula
    dzo    Dzongkha
    bin    Edo
    efi    Efik
    eka    Ekajuk
    elx    Elamite
    enm    English Middle
    ang    English Old
    ewe    Ewe
    ewo    Ewondo
    fan    Fang
    fat    Fanti
    fao    Faroese
    fij    Fijian
    fiu    Finno-Ugrian
    fon    Fon
    frm    French Middle
    fro    French Old
    fry    Frisian
    fur    Friulian
    ful    Fula
    glg    Galician
    lug    Ganda
    gay    Gayo
    gba    Gbaya
    geo    Georgian
    gmh    German Middle High
    goh    German Old High
    gem    Germanic
    gil    Gilbertese
    gon    Gondi
    gor    Gorontalo
    got    Gothic
    grb    Grebo
    grc    Greek Ancient
    grn    Guarani
    guj    Gujarati
    hai    Haida
    hat    Haitian French Creole
    hau    Hausa
    haw    Hawaiian
    her    Herero
    hil    Hiligaynon
    him    Himachali
    hin    Hindi
    hmo    Hiri Motu
    hit    Hittite
    hmn    Hmong
    hup    Hupa
    iba    Iban
    ido    Ido
    ibo    Igbo
    ijo    Ijo
    ilo    Iloko
    smn    Inari Sami
    ine    Indo-European
    inh    Ingush
    ina    Interlingua
    ile    Interlingue
    iku    Inuktitut
    ipk    Inupiaq
    mga    Irish Middle
    sga    Irish Old
    iro    Iroquoian
    jav    Javanese
    jrb    Judeo-Arabic
    jpr    Judeo-Persian
    kab    Kabyle
    kac    Kachin
    xal    Kalmyk
    kam    Kamba
    kan    Kannada
    kau    Kanuri
    kaa    Kara-Kalpak
    kar    Karen
    kas    Kashmiri
    kaw    Kawi
    kaz    Kazakh
    kha    Khasi
    khm    Khmer
    khi    Khoisan
    kho    Khotanese
    kik    Kikuyu
    kmb    Kimbundu
    kin    Kinyarwanda
    kom    Komi
    kon    Kongo
    kok    Konkani
    kpe    Kpelle
    kro    Kru
    kua    Kuanyama
    kum    Kumyk
    kru    Kurukh
    kos    Kusaie
    kut    Kutenai
    kir    Kyrgyz
    lad    Ladino
    lah    Lahnda
    lam    Lamba
    lao    Lao
    ltz    Letzeburgesch
    lez    Lezgian
    lim    Limburgish
    lin    Lingala
    nds    Low German
    loz    Lozi
    lub    Luba-Katanga
    lua    Luba-Lulua
    smj    Lule Sami
    lun    Lunda
    luo    Luo
    lus    Lushai
    mac    Macedonian
    mad    Madurese
    mag    Magahi
    mai    Maithili
    mak    Makasar
    mlg    Malagasy
    may    Malay
    mal    Malayalam
    mlt    Maltese
    mnc    Manchu
    mdr    Mandar
    man    Mandingo
    mni    Manipuri
    glv    Manx
    mao    Maori
    arn    Mapuche
    mar    Marathi
    chm    Mari
    mah    Marshallese
    mwr    Marwari
    mas    Masai
    men    Mende
    mic    Micmac
    min    Minangkabau
    moh    Mohawk
    mkh    Mon-Khmer
    lol    Mongo-Nkundu
    mon    Mongolian
    mun    Munda
    nah    Nahuatl
    nau    Nauru
    nbl    Ndebele
    nde    Ndebele
    ndo    Ndonga
    nap    Neapolitan Italian
    nep    Nepali
    new    Newari
    nia    Nias
    nic    Niger-Kordofanian
    ssa    Nilo-Saharan
    niu    Niuean
    nog    Nogai
    nai    North American Indian
    sme    Northern Sami
    nso    Northern Sotho
    nym    Nyamwezi
    nya    Nyanja
    nyn    Nyankole
    nyo    Nyoro
    nzi    Nzima
    oci    Occitan
    oji    Ojibwa
    non    Old Norse
    peo    Old Persian
    ori    Oriya
    orm    Oromo
    osa    Osage
    oss    Ossetic
    pal    Pahlavi
    pau    Palauan
    pli    Pali
    pam    Pampanga
    pag    Pangasinan
    pan    Panjabi
    pap    Papiamento
    paa    Papuan
    per    Persian
    phn    Phoenician
    pon    Ponape
    pus    Pushto
    que    Quechua
    roh    Raeto-Romance
    raj    Rajasthani
    rap    Rapanui
    rar    Rarotongan
    roa    Romance
    rom    Romani
    run    Rundi
    sam    Samaritan Aramaic
    smi    Sami
    smo    Samoan
    sad    Sandawe
    sag    Sango
    san    Sanskrit
    sat    Santali
    sas    Sasak
    sco    Scots
    gla    Scottish Gaelic
    sel    Selkup
    sem    Semitic
    srr    Serer
    shn    Shan
    sna    Shona
    iii    Sichuan Yi
    sid    Sidamo
    bla    Siksika
    snd    Sindhi
    sin    Sinhalese
    sit    Sino-Tibetan
    sio    Siouan
    sms    Skolt Sami
    den    Slave
    sla    Slavic
    sog    Sogdian
    son    Songhai
    snk    Soninke
    sot    Sotho
    sai    South American Indian
    sma    Southern Sami
    suk    Sukuma
    sux    Sumerian
    sun    Sundanese
    sus    Susu
    ssw    Swazi
    tgl    Tagalog
    tai    Tai
    tgk    Tajik
    tmh    Tamashek
    tam    Tamil
    tel    Telugu
    tem    Temne
    ter    Terena
    tet    Tetum
    tir    Tigrinya
    tiv    Tiv
    tli    Tlingit
    tpi    Tok Pisin
    tkl    Tokelauan
    tog    Tonga
    ton    Tongan
    chk    Truk
    tsi    Tsimshian
    tso    Tsonga
    tsn    Tswana
    tum    Tumbuka
    ota    Turkish Ottoman
    tuk    Turkmen
    tvl    Tuvaluan
    tyv    Tuvinian
    twi    Twi
    udm    Udmurt
    uga    Ugaritic
    uig    Uighur
    umb    Umbundu
    und    Undetermined
    urd    Urdu
    vai    Vai
    ven    Venda
    vot    Votic
    wal    Walamo
    wln    Walloon
    war    Waray
    was    Washo
    wol    Wolof
    xho    Xhosa
    sah    Yakut
    yao    Yao
    yap    Yapese
    yor    Yoruba
    znd    Zande
    zap    Zapotec
    zen    Zenaga
    zha    Zhuang
    zul    Zulu
    zun    Zuni

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metatrans@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jan Pomikalek, C<< <xpomikal@fi.muni.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jan Pomikalek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
