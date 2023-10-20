=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kab - Package for language Kabyle

=cut

package Locale::CLDR::Locales::Kab;
# This file auto generated from Data\common\main\kab.xml
#	on Fri 13 Oct  9:22:54 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'aa' => 'Tafarit',
 				'ab' => 'Tabxazit',
 				'ace' => 'Tačinist',
 				'ada' => 'Tadangmit',
 				'ady' => 'Tadiganit',
 				'af' => 'Tafrikant',
 				'agq' => 'Taghemit',
 				'ain' => 'Taynut',
 				'ak' => 'Takanit',
 				'ale' => 'Taliyut',
 				'alt' => 'Talṭayt n unẓul',
 				'am' => 'Tamahrict',
 				'an' => 'Taṛagunit',
 				'anp' => 'Tangikat',
 				'ar' => 'Taɛrabt',
 				'arn' => 'Tamapuct',
 				'arp' => 'Taṛapahut',
 				'as' => 'Tasamizt',
 				'asa' => 'Tasut',
 				'ast' => 'Tasturit',
 				'av' => 'Tavarikt',
 				'awa' => 'Tawadhit',
 				'ay' => 'Taymarit',
 				'az' => 'Tazerbiǧanit',
 				'az@alt=short' => 'Tazrit',
 				'ba' => 'Tabackirt',
 				'ban' => 'Tabalinit',
 				'bas' => 'Tabasat',
 				'be' => 'Tabilarusit',
 				'bem' => 'Tabimbat',
 				'bez' => 'Tabinat',
 				'bg' => 'Tabulgarit',
 				'bho' => 'Tabujpurit',
 				'bi' => 'Tabislamat',
 				'bin' => 'Tabinit',
 				'bla' => 'Tasiksikat',
 				'bm' => 'Tabambarat',
 				'bn' => 'Tabengalit',
 				'bo' => 'Tatibitant',
 				'br' => 'Tabrutunt',
 				'brx' => 'Tabudut',
 				'bs' => 'Tabusnit',
 				'bug' => 'Tabujinit',
 				'byn' => 'Tablint',
 				'ca' => 'Takaṭalant',
 				'ce' => 'Tačičant',
 				'ceb' => 'Tacibwanit',
 				'cgg' => 'Tacigat',
 				'ch' => 'Tacamuṛut',
 				'chk' => 'Tačukizt',
 				'chm' => 'Tamarit',
 				'cho' => 'Tacuktawt',
 				'chr' => 'Tacirukit',
 				'chy' => 'Taciyant',
 				'ckb' => 'Takurdit Talemmast',
 				'co' => 'Takuṛsit',
 				'crs' => 'Takriyult n Saycal',
 				'cs' => 'Tačikit',
 				'cu' => 'Taslavt n tmezgida',
 				'cv' => 'Tačubact',
 				'cy' => 'Takusit',
 				'da' => 'Tadanit',
 				'dak' => 'Tadakutat',
 				'dar' => 'Tadargwat',
 				'dav' => 'Tataytat',
 				'de' => 'Talmant',
 				'de_AT' => 'Talmanit n Ustriya',
 				'de_CH' => 'Talmanit n Swis',
 				'dgr' => 'Tadugribt',
 				'dje' => 'Tazarmat',
 				'dsb' => 'Taṣurbyant n wadda',
 				'dua' => 'Tadwalat',
 				'dv' => 'Tamaldivit',
 				'dyo' => 'Jula-Funyi',
 				'dz' => 'Tadzungat',
 				'dzg' => 'Tadazagat',
 				'ebu' => 'Tumbut',
 				'ee' => 'Tiwit',
 				'efi' => 'Tafikt',
 				'eka' => 'Takajukt',
 				'el' => 'Tagrikit',
 				'en' => 'Taglizit',
 				'en_AU' => 'Taglizit n Ustṛalya',
 				'en_CA' => 'Taglizit n Kanada',
 				'en_GB' => 'Taglizit n Briṭanya',
 				'en_GB@alt=short' => 'Taglizit n Tgelda Yedduklen',
 				'en_US' => 'Taglizit n Marikan',
 				'en_US@alt=short' => 'Taglizit n US',
 				'eo' => 'Taspirantit',
 				'es' => 'Taspenyulit',
 				'es_419' => 'Taspanit n Temrikt Talaṭinit',
 				'es_ES' => 'Taspanit n Turuft',
 				'es_MX' => 'Taspanit n Miksik',
 				'et' => 'Tasṭunit',
 				'eu' => 'Tabaskit',
 				'ewo' => 'Tawundut',
 				'fa' => 'Tafarisit',
 				'ff' => 'Tafulaht',
 				'fi' => 'Tafinit',
 				'fil' => 'Tafilipant',
 				'fj' => 'Tafiǧit',
 				'fo' => 'Tafirwanit',
 				'fon' => 'Tafunit',
 				'fr' => 'Tafransist',
 				'fr_CA' => 'Tafransist n Kanada',
 				'fr_CH' => 'Tafransist n Swis',
 				'fur' => 'Tafriyulant',
 				'fy' => 'Tafrizunt n umalu',
 				'ga' => 'Tirlandit',
 				'gaa' => 'Tagat',
 				'gd' => 'Tagaylikt n Skuṭland',
 				'gez' => 'Tagizit',
 				'gil' => 'Tajibṛaltart',
 				'gl' => 'Tagalisit',
 				'gn' => 'Tagaranit',
 				'gor' => 'Taguruntalut',
 				'gsw' => 'Talmanit n Swiss',
 				'gu' => 'Taguǧaṛatit',
 				'guz' => 'Tagusit',
 				'gv' => 'Tamanksit',
 				'gwi' => 'Tagwičint',
 				'ha' => 'Tahwasit',
 				'haw' => 'Tahawayt',
 				'he' => 'Taɛebrit',
 				'hi' => 'Tahendit',
 				'hil' => 'Tahiligaynunt',
 				'hmn' => 'Tahmungt',
 				'hr' => 'Takeṛwasit',
 				'hsb' => 'Tasirbit n ufella',
 				'ht' => 'Takriyult n Hayti',
 				'hu' => 'Tahungarit',
 				'hup' => 'Tahupat',
 				'hy' => 'Taṛminit',
 				'hz' => 'Tahiriṛut',
 				'ia' => 'Tutlayt tagraɣlant',
 				'iba' => 'Tibant',
 				'ibb' => 'Tabibyut',
 				'id' => 'Tandunisit',
 				'ig' => 'Tigbut',
 				'ii' => 'Yi-n-Sicwan',
 				'ilo' => 'Tilukanut',
 				'inh' => 'Tinguct',
 				'io' => 'Tidut',
 				'is' => 'Taṣlandit',
 				'it' => 'Taṭalyanit',
 				'iu' => 'Tinuktitut',
 				'ja' => 'Tajapunit',
 				'jbo' => 'Talujbant',
 				'jgo' => 'Tangumbat',
 				'jmc' => 'Tamačamit',
 				'jv' => 'Tajavanit',
 				'ka' => 'Tajyurjit',
 				'kab' => 'Taqbaylit',
 				'kac' => 'Takacint',
 				'kaj' => 'Tajjut',
 				'kam' => 'Takambat',
 				'kbd' => 'Takabardint',
 				'kcg' => 'Tatyapt',
 				'kde' => 'Tamakundit',
 				'kea' => 'Takapverdit',
 				'kfo' => 'Takurut',
 				'kha' => 'Taxasit',
 				'khq' => 'koyra chiini',
 				'ki' => 'Takikuyut',
 				'kj' => 'Takwanyamat',
 				'kk' => 'Takazaxt',
 				'kkj' => 'Takakut',
 				'kl' => 'Tagrinlandit',
 				'kln' => 'Takalinjint',
 				'km' => 'Takemrit',
 				'kmb' => 'Takimbundut',
 				'kn' => 'Takannadat',
 				'ko' => 'Takurit',
 				'kok' => 'Takunkanit',
 				'kpe' => 'Takpilit',
 				'kr' => 'Takanurit',
 				'krc' => 'Takaračayt Tabalkart',
 				'krl' => 'Takarilyant',
 				'kru' => 'Takuruxt',
 				'ks' => 'Takacmirit',
 				'ksb' => 'Tacambalat',
 				'ksf' => 'Tabafyat',
 				'ksh' => 'Takulunyant',
 				'ku' => 'Takurdit',
 				'kum' => 'Takumyakt',
 				'kv' => 'Taklingunit',
 				'kw' => 'Takurnikt',
 				'ky' => 'Takirgizt',
 				'la' => 'Talaṭinit',
 				'lad' => 'Taladinut',
 				'lag' => 'Talangit',
 				'lb' => 'Taluksumburgit',
 				'lez' => 'Talezɣant',
 				'lg' => 'Tagandat',
 				'li' => 'Talimburjwat',
 				'lkt' => 'Talakutat',
 				'ln' => 'Talingalat',
 				'lo' => 'Talawsit',
 				'loz' => 'Taluzit',
 				'lrc' => 'Talurit n ugafa',
 				'lt' => 'Talitwanit',
 				'lu' => 'Talubit-Takatangit',
 				'lua' => 'Talubat n Lulua',
 				'lun' => 'Talundat',
 				'luo' => 'Taluwut',
 				'lus' => 'Talucayt',
 				'luy' => 'Taluhyat',
 				'lv' => 'Talitunit',
 				'mad' => 'Tamadurizt',
 				'mag' => 'Tamagahit',
 				'mai' => 'Tamaytilit',
 				'mak' => 'Tamakassart',
 				'mas' => 'Tamassayt',
 				'mdf' => 'Tamuksat',
 				'men' => 'Tamandit',
 				'mer' => 'Tamirut',
 				'mfe' => 'Takriyult n Muris',
 				'mg' => 'Tamalgact',
 				'mgh' => 'Makhuwa-meetto',
 				'mgo' => 'Tamitat',
 				'mh' => 'Tamaṛcalit',
 				'mi' => 'Tamawrit',
 				'mic' => 'Tamikmakt',
 				'min' => 'Taminangkabut',
 				'mk' => 'Tamasidunit',
 				'ml' => 'Tamalayalamit',
 				'mn' => 'Tamungulit',
 				'mni' => 'Tamanipurit',
 				'moh' => 'Tamuhawkt',
 				'mos' => 'Tamurit',
 				'mr' => 'Tamaṛatit',
 				'ms' => 'Tamalawit',
 				'mt' => 'Tamalṭit',
 				'mua' => 'Tamundangt',
 				'mul' => 'Tugett n tutlayin',
 				'mus' => 'Takrikt',
 				'mwl' => 'Tamirandit',
 				'my' => 'Taburmisit',
 				'myv' => 'Tirzyat',
 				'mzn' => 'Tamazandiranit',
 				'na' => 'Tanurwant',
 				'nap' => 'Tanapolitant',
 				'naq' => 'Tanamat',
 				'nb' => 'Tanurvijit Bukmal',
 				'nd' => 'Tandibilit n Ugafa',
 				'ne' => 'Tanipalit',
 				'new' => 'Taniwarit',
 				'ng' => 'Tandungat',
 				'nia' => 'Tanizt',
 				'niu' => 'Tanyunit',
 				'nl' => 'Tadučit',
 				'nl_BE' => 'Taflamant',
 				'nmg' => 'Takwazyut',
 				'nn' => 'Tanuṛvijt ninuṛsk',
 				'nnh' => 'Tangimbunt',
 				'nog' => 'Tanugayt',
 				'nqo' => 'Tankut',
 				'nr' => 'Tandibilit n unzul',
 				'nso' => 'Talizutut n ugafa',
 				'nus' => 'Tanyurt',
 				'nv' => 'Tanavahut',
 				'ny' => 'Tanyanjat',
 				'nyn' => 'Tanyankulit',
 				'oc' => 'Tuksitant',
 				'om' => 'Turumut',
 				'or' => 'Turyat',
 				'os' => 'Tusitit',
 				'pa' => 'Tapunjabit',
 				'pag' => 'Tapangazinant',
 				'pam' => 'Tapampangant',
 				'pap' => 'Tapapyamintut',
 				'pau' => 'Tapalut',
 				'pcm' => 'Tapidgint n Nijirya',
 				'pl' => 'Tapulunit',
 				'prg' => 'Taprusit',
 				'ps' => 'Tapactut',
 				'pt' => 'Tapurtugalit',
 				'pt_BR' => 'Tapuṛṭugit (Brizil)',
 				'pt_PT' => 'Tapuṛṭugit (Purtugal)',
 				'qu' => 'Takicwit',
 				'quc' => 'Takict',
 				'rap' => 'Tarapanwit',
 				'rar' => 'Tararutungant',
 				'rm' => 'Tarumancit',
 				'rn' => 'Tarundit',
 				'ro' => 'Tarumanit',
 				'ro_MD' => 'Tamuldavt',
 				'rof' => 'Tarumbut',
 				'root' => 'Aẓar',
 				'ru' => 'Tarusit',
 				'rup' => 'Tavalakt',
 				'rw' => 'Taruwandit',
 				'rwk' => 'Tarwat',
 				'sa' => 'Tasanskrit',
 				'sad' => 'Tasandawit',
 				'sah' => 'Tayakut',
 				'saq' => 'Tasamburut',
 				'sat' => 'Tasantalt',
 				'sba' => 'Tangambayt',
 				'sbp' => 'Tasangut',
 				'sc' => 'Tasardinit',
 				'scn' => 'Tasisilit',
 				'sco' => 'Taskutlandit',
 				'sd' => 'Tasinḍit',
 				'se' => 'Tasamt n ugafa',
 				'seh' => 'Tasisinat',
 				'ses' => 'Takuyraburut n Senni',
 				'sg' => 'Tasangit',
 				'shi' => 'Tacelḥit',
 				'shn' => 'Tacant',
 				'si' => 'Tasinhalit',
 				'sk' => 'Tasluvakt',
 				'sl' => 'Tasluvinit',
 				'sm' => 'Taṣamwant',
 				'sma' => 'Tasamit n unzul',
 				'smj' => 'Tasamit n Lule',
 				'smn' => 'Tasami n Inari',
 				'sms' => 'Tasamit n Skolt',
 				'sn' => 'Tacunit',
 				'snk' => 'Tasunikit',
 				'so' => 'Taṣumalit',
 				'sq' => 'Talbanit',
 				'sr' => 'Taṣirbit',
 				'srn' => 'Tasranant n Tongo',
 				'ss' => 'Taswatit',
 				'ssy' => 'Tasahut',
 				'st' => 'Talizutut n Unzul',
 				'su' => 'Tasudanit',
 				'suk' => 'Tasukumat',
 				'sv' => 'Taswidit',
 				'sw' => 'Taswayilit',
 				'sw_CD' => 'Taswayilit n Kungu',
 				'swb' => 'Takumurit',
 				'syr' => 'Tasiryakt',
 				'ta' => 'Taṭamulit',
 				'te' => 'Taluggut',
 				'tem' => 'Tatimnit',
 				'teo' => 'Tatizut',
 				'tet' => 'Tatitumt',
 				'tg' => 'Tatajikt',
 				'th' => 'Taṭaylundit',
 				'ti' => 'Tigrinit',
 				'tig' => 'Tatigrit',
 				'tk' => 'Taturkmant',
 				'tlh' => 'Taklingunt',
 				'tn' => 'Tattwanit',
 				'to' => 'Tatungant',
 				'tpi' => 'Tatukt n Pisin',
 				'tr' => 'Taṭurkit',
 				'trv' => 'Tatarukut',
 				'ts' => 'Ttunga',
 				'tt' => 'Taṭaṭarit',
 				'tum' => 'Tatumbukat',
 				'tvl' => 'Tatuvalut',
 				'twq' => 'Tatasawaqt',
 				'ty' => 'Tahesiant',
 				'tyv' => 'Tatuvat',
 				'tzm' => 'Tamaziɣt n Waṭlas alemmas',
 				'udm' => 'Tudmurt',
 				'ug' => 'Tawigurt',
 				'uk' => 'Tukranit',
 				'umb' => 'Tumbundut',
 				'und' => 'Tutlayt tarussint',
 				'ur' => 'Turdut',
 				'uz' => 'Tuzbikt',
 				'vai' => 'Tavayt',
 				've' => 'Tavendat',
 				'vi' => 'Tabyiṭnamit',
 				'vo' => 'Tavulapukt',
 				'vun' => 'Tavunjut',
 				'wa' => 'Tawalunit',
 				'wae' => 'Tawalsirt',
 				'wal' => 'Tawalamut',
 				'war' => 'Tawarayt',
 				'wo' => 'Tawuluft',
 				'xal' => 'Takalmukt',
 				'xh' => 'Taksuzit',
 				'xog' => 'Tasugat',
 				'yav' => 'Tayangbent',
 				'ybb' => 'Yemba',
 				'yi' => 'Tayiddict',
 				'yo' => 'Tayurubit',
 				'yue' => 'Takantunit',
 				'zgh' => 'Tamaziɣt Tizeɣt Tamerrukit',
 				'zh' => 'Tacinwat, Tamundarint',
 				'zh_Hans' => 'Tacinwat taḥerfit',
 				'zh_Hant' => 'Tacinwat tamensayt',
 				'zu' => 'Tazulut',
 				'zun' => 'Tazunit',
 				'zxx' => 'Ulac agbur utlayan',
 				'zza' => 'Tazazakit',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Arab' => 'Aɛrab',
 			'Armn' => 'Armini',
 			'Beng' => 'Abengali',
 			'Bopo' => 'Abupumufu',
 			'Brai' => 'Bray',
 			'Cyrl' => 'Asirilik',
 			'Deva' => 'Adivangari',
 			'Ethi' => 'Atyupan',
 			'Geor' => 'Agriguri',
 			'Grek' => 'Agrigi',
 			'Gujr' => 'Agujarati',
 			'Guru' => 'Agurmuxi',
 			'Hanb' => 'Ahanbt',
 			'Hang' => 'Ahangul',
 			'Hani' => 'Ahan',
 			'Hans' => 'Aḥerfi',
 			'Hans@alt=stand-alone' => 'Isinugramen iḥerfiyen',
 			'Hant' => 'Amensay',
 			'Hant@alt=stand-alone' => 'Isinugramen imensayen',
 			'Hebr' => 'Aɛebri',
 			'Hira' => 'Ahiragana',
 			'Hrkt' => 'Akatakana n hiragana',
 			'Jamo' => 'Ajamu',
 			'Jpan' => 'Ajapuni',
 			'Kana' => 'Akatakana',
 			'Khmr' => 'Axemri',
 			'Knda' => 'Akannada',
 			'Kore' => 'Akuri',
 			'Laoo' => 'Alawsi',
 			'Latn' => 'Alaṭini',
 			'Mlym' => 'Amalayalam',
 			'Mong' => 'Amungul',
 			'Mymr' => 'Abiṛman',
 			'Orya' => 'Urya',
 			'Sinh' => 'Asingali',
 			'Taml' => 'Aṭamil',
 			'Telu' => 'Tilugut',
 			'Thaa' => 'Athana',
 			'Thai' => 'Ataylan',
 			'Tibt' => 'Atibitan',
 			'Zmth' => 'Tira tusnakt',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Izamulen',
 			'Zxxx' => 'War tira',
 			'Zyyy' => 'Ucrik',
 			'Zzzz' => 'Tira tarussint',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'001' => 'Amaḍal',
 			'002' => 'Tafriqt',
 			'003' => 'Tamrikt n ugafa',
 			'005' => 'Tamrikt n unẓul',
 			'009' => 'Usyanya',
 			'011' => 'Tafriqt n umalu',
 			'013' => 'Tamrikt Talemmast',
 			'014' => 'Tafriqt n usammar',
 			'015' => 'Tafriqt n ugafa',
 			'017' => 'Tafriqt talemmast',
 			'018' => 'Tafriqt n unẓul',
 			'019' => 'Timrikin',
 			'021' => 'Tamrikt Tagafayent',
 			'029' => 'Kaṛayib',
 			'030' => 'Asya n usammar',
 			'034' => 'Asya n unẓul',
 			'035' => 'Asya n unẓul asammar',
 			'039' => 'Turuft n unẓul',
 			'053' => 'Ustṛasya',
 			'054' => 'Milanizya',
 			'057' => 'Tamnaḍt n Mikṛunizya',
 			'061' => 'Pulinizya',
 			'142' => 'Asya',
 			'143' => 'Asya talemmast',
 			'145' => 'Asya n umalu',
 			'150' => 'Turuft',
 			'151' => 'Turuft n usammar',
 			'154' => 'Turuft n ugafa',
 			'155' => 'Turuft n umalu',
 			'419' => 'Tamrikt talaṭinit',
 			'AC' => 'Tigzirt n Aṣunsyun',
 			'AD' => 'Undura',
 			'AE' => 'Tigeldunin Yedduklen Taɛrabin',
 			'AF' => 'Afɣanistan',
 			'AG' => 'Untiga d Barbuda',
 			'AI' => 'Ungiya',
 			'AL' => 'Lalbani',
 			'AM' => 'Arminya',
 			'AO' => 'Ungula',
 			'AQ' => 'Antaṛktik',
 			'AR' => 'Arjuntin',
 			'AS' => 'Samwa Tamarikanit',
 			'AT' => 'Ustriya',
 			'AU' => 'Ustrali',
 			'AW' => 'Aruba',
 			'AX' => 'Tigzirin n Aland',
 			'AZ' => 'Azrabijan',
 			'BA' => 'Busna d Hersek',
 			'BB' => 'Barbadus',
 			'BD' => 'Bangladac',
 			'BE' => 'Belǧik',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Bulgari',
 			'BH' => 'Baḥrin',
 			'BI' => 'Burandi',
 			'BJ' => 'Binin',
 			'BL' => 'Sant Baṛtilimi',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruney',
 			'BO' => 'Bulivi',
 			'BQ' => 'Huland n Kaṛayib',
 			'BR' => 'Brizil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Tigzirin n Buvet',
 			'BW' => 'Bustwana',
 			'BY' => 'Bilarus',
 			'BZ' => 'Biliz',
 			'CA' => 'Kanada',
 			'CC' => 'Tigzirin n Kukus',
 			'CD' => 'Tigduda Tagdudant n Kungu',
 			'CD@alt=variant' => 'Tagduda Tamegdayt n Kungu',
 			'CF' => 'Tigduda n Tefriqt Talemmast',
 			'CG' => 'Kungu',
 			'CG@alt=variant' => 'Kungu (Tagduda)',
 			'CH' => 'Swis',
 			'CI' => 'Kuṭ Divwar',
 			'CI@alt=variant' => 'Kuṭ-D-Ivwaṛ - 2 -',
 			'CK' => 'Tigzirin n Kuk',
 			'CL' => 'Cili',
 			'CM' => 'Kamirun',
 			'CN' => 'Lacin',
 			'CO' => 'Kulumbi',
 			'CP' => 'Tigzirt n Klipirṭun',
 			'CR' => 'Kusta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Tigzirin n yixef azegzaw',
 			'CW' => 'Kuṛaṣaw',
 			'CX' => 'Tigzrin n Kristmaṣ',
 			'CY' => 'Cipr',
 			'CZ' => 'Čček',
 			'CZ@alt=variant' => 'Tagduda n Čik',
 			'DE' => 'Lalman',
 			'DG' => 'Digu Gaṛsya',
 			'DJ' => 'Ǧibuti',
 			'DK' => 'Denmark',
 			'DM' => 'Duminik',
 			'DO' => 'Tigduda Taduminikit',
 			'DZ' => 'Lezzayer',
 			'EA' => 'Sebta d Melilla',
 			'EC' => 'Ikwaṭur',
 			'EE' => 'Istunya',
 			'EG' => 'Maṣr',
 			'EH' => 'Seḥra n umalu',
 			'ER' => 'Iritiria',
 			'ES' => 'Spanya',
 			'ET' => 'Utyupi',
 			'EU' => 'Tiddukla n Turuft',
 			'EZ' => 'Tamnaḍt n Turuft',
 			'FI' => 'Finlund',
 			'FJ' => 'Fiji',
 			'FK' => 'Tigzirin n Falkland',
 			'FK@alt=variant' => 'Tigzirin n Falkland (Islas Malvinas)',
 			'FM' => 'Mikrunizya',
 			'FO' => 'Tigzirin n Faṛwi',
 			'FR' => 'Fransa',
 			'GA' => 'Gabun',
 			'GB' => 'Tagelda Yedduklen',
 			'GB@alt=short' => 'Tag.Yed',
 			'GD' => 'Grunad',
 			'GE' => 'Jiyurji',
 			'GF' => 'Ɣana tafransist',
 			'GG' => 'Girnizi',
 			'GH' => 'Ɣana',
 			'GI' => 'Jibraltar',
 			'GL' => 'Grunland',
 			'GM' => 'Gambya',
 			'GN' => 'Ɣinya',
 			'GP' => 'Gwadalupi',
 			'GQ' => 'Ɣinya Tasebgast',
 			'GR' => 'Lagris',
 			'GS' => 'Tigzirin n Jyuṛjya n Unzul akked Sandwič n Unẓul',
 			'GT' => 'Gwatimala',
 			'GU' => 'Gwam',
 			'GW' => 'Ɣinya-Bisaw',
 			'GY' => 'Guwana',
 			'HK' => 'Tamnaṭ Taqbuṛt Tacinwat n Hung Kung',
 			'HK@alt=short' => 'Hung Kung',
 			'HM' => 'Tigzirin Heard akked McDonald',
 			'HN' => 'Hunduras',
 			'HR' => 'Kerwasya',
 			'HT' => 'Hayti',
 			'HU' => 'Hungri',
 			'IC' => 'Tigzirin Tikanaṛiyin',
 			'ID' => 'Indunizi',
 			'IE' => 'Lirlund',
 			'IL' => 'Izrayil',
 			'IM' => 'Tigzirt n Man',
 			'IN' => 'Lhend',
 			'IO' => 'Akal Aglizi deg Ugaraw Ahendi',
 			'IQ' => 'Lɛiraq',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Ṭelyan',
 			'JE' => 'Jiṛzi',
 			'JM' => 'Jamyika',
 			'JO' => 'Lajurdani',
 			'JP' => 'Jappu',
 			'KE' => 'Kinya',
 			'KG' => 'Kirigistan',
 			'KH' => 'Cambudya',
 			'KI' => 'Kiribati',
 			'KM' => 'Kumur',
 			'KN' => 'San Kits d Nivis',
 			'KP' => 'Kurya, Ufella',
 			'KR' => 'Kurya, Wadda',
 			'KW' => 'Kuwayt',
 			'KY' => 'Tigzirin n Kamyan',
 			'KZ' => 'Kazaxistan',
 			'LA' => 'Laws',
 			'LB' => 'Lubnan',
 			'LC' => 'San Lučya',
 			'LI' => 'Layctenstan',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libirya',
 			'LS' => 'Lizuṭu',
 			'LT' => 'Liṭwanya',
 			'LU' => 'Luksamburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Lmerruk',
 			'MC' => 'Munaku',
 			'MD' => 'Muldabi',
 			'ME' => 'Muntinigru',
 			'MF' => 'San Maṛtan',
 			'MG' => 'Madaɣecqer',
 			'MH' => 'Tigzirin n Marcal',
 			'MK' => 'Masidwan',
 			'MK@alt=variant' => 'Masidunya (Tagduda Taqbuṛt Tayuguslavit n Masidunya)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mungulya',
 			'MO' => 'Tamnaṭ Tudbilt Tuzzigt tacenwit n Makaw',
 			'MO@alt=short' => 'Makaw',
 			'MP' => 'Tigzirin n Maryan Ufella',
 			'MQ' => 'Martinik',
 			'MR' => 'Muriṭanya',
 			'MS' => 'Munsirat',
 			'MT' => 'Malṭ',
 			'MU' => 'Muris',
 			'MV' => 'Maldib',
 			'MW' => 'Malawi',
 			'MX' => 'Meksik',
 			'MY' => 'Malizya',
 			'MZ' => 'Muzembiq',
 			'NA' => 'Namibya',
 			'NC' => 'Kalidunya Tamaynut',
 			'NE' => 'Nijer',
 			'NF' => 'Tigzirin Tinawfukin',
 			'NG' => 'Nijirya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Timura-Yessakesren',
 			'NO' => 'Nurvij',
 			'NP' => 'Nipal',
 			'NR' => 'Nuru',
 			'NU' => 'Niwi',
 			'NZ' => 'Ziland Tamaynut',
 			'OM' => 'Ɛuman',
 			'PA' => 'Panam',
 			'PE' => 'Piru',
 			'PF' => 'Pulunizi tafransist',
 			'PG' => 'Ɣinya Tamaynut Tapaput',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistan',
 			'PL' => 'Pulund',
 			'PM' => 'San Pyar d Miklun',
 			'PN' => 'Pitkarin',
 			'PR' => 'Purtu Riku',
 			'PS' => 'Falisṭin d Ɣezza',
 			'PS@alt=short' => 'Falisṭin',
 			'PT' => 'Purtugal',
 			'PW' => 'Palu',
 			'PY' => 'Paragway',
 			'QA' => 'Qaṭar',
 			'QO' => 'Timnaḍin ibeɛden n Tusyanit',
 			'RE' => 'Timlilit',
 			'RO' => 'Rumani',
 			'RS' => 'Ṣirbya',
 			'RU' => 'Rrus',
 			'RW' => 'Ruwanda',
 			'SA' => 'Suɛudiya Taɛrabt',
 			'SB' => 'Tigzirin n Sulumun',
 			'SC' => 'Seycel',
 			'SD' => 'Sudan',
 			'SE' => 'Swid',
 			'SG' => 'Singafur',
 			'SH' => 'Sant Ilina',
 			'SI' => 'Sluvinya',
 			'SJ' => 'Svalvard d Jan Mayen',
 			'SK' => 'Sluvakya',
 			'SL' => 'Sira Lyun',
 			'SM' => 'San Marinu',
 			'SN' => 'Sinigal',
 			'SO' => 'Ṣumal',
 			'SR' => 'Surinam',
 			'SS' => 'Sudan n unẓul',
 			'ST' => 'Saw Tumi d Pransip',
 			'SV' => 'Salvadur',
 			'SX' => 'San Maṛtan(Tamnaḍt tahulandit)',
 			'SY' => 'Surya',
 			'SZ' => 'Swazilund',
 			'TA' => 'Tristan da Kunha',
 			'TC' => 'Ṭurk d Tegzirin n Kaykus',
 			'TD' => 'Čad',
 			'TF' => 'Timura n umalu tifṛansisiyin',
 			'TG' => 'Ṭugu',
 			'TH' => 'Ṭayland',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Ṭuklu',
 			'TL' => 'Tumur Asamar',
 			'TL@alt=variant' => 'Timur-n-usammar',
 			'TM' => 'Ṭurkmanistan',
 			'TN' => 'Tunes',
 			'TO' => 'Ṭunga',
 			'TR' => 'Ṭurk',
 			'TT' => 'Ṭrindad d Ṭubagu',
 			'TV' => 'Ṭuvalu',
 			'TW' => 'Ṭaywan',
 			'TZ' => 'Ṭanzanya',
 			'UA' => 'Ukran',
 			'UG' => 'Uɣanda',
 			'UM' => 'Tigzirin ibeɛden n Marikan',
 			'UN' => 'Timura Idduklen',
 			'US' => 'WDM',
 			'US@alt=short' => 'US',
 			'UY' => 'Urugway',
 			'UZ' => 'Uzbaxistan',
 			'VA' => 'Awanek n Vatikan',
 			'VC' => 'San Vansu d Grunadin',
 			'VE' => 'Venzwila',
 			'VG' => 'Tigzirin Tiverjiniyin Tigliziyin',
 			'VI' => 'W.D. Tigzirin n Virginya',
 			'VN' => 'Vyeṭnam',
 			'VU' => 'Vanwatu',
 			'WF' => 'Wallis d Futuna',
 			'WS' => 'Samwa',
 			'XK' => 'Kuṣuvu',
 			'YE' => 'Lyamen',
 			'YT' => 'Mayuṭ',
 			'ZA' => 'Tafriqt Wadda',
 			'ZM' => 'Zambya',
 			'ZW' => 'Zimbabwi',
 			'ZZ' => 'Timnaḍin Tirussinin',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Awitay',
 			'cf' => 'Amasal n tedrimt',
 			'collation' => 'Amizzwer deg ufran',
 			'currency' => 'Tadrimt',
 			'hc' => 'Anagraw usrig (12 mgal 24)',
 			'lb' => 'Aɣanib n tuɣalin ar udur',
 			'ms' => 'Anagraw n uktal',
 			'numbers' => 'Imḍanen',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{Awitay abudi},
 				'chinese' => q{Awitay acinwa},
 				'dangi' => q{Awitay n Dangi},
 				'ethiopic' => q{Awitay n Ityupya},
 				'gregorian' => q{Awitay agriguryan},
 				'hebrew' => q{Awitay aɛebri},
 				'islamic' => q{Awitay ineslem},
 				'iso8601' => q{Awitay ISO-8601},
 				'japanese' => q{Awitay ajapuni},
 				'persian' => q{Awitay afarsi},
 				'roc' => q{Awitay agdudan acinwa},
 			},
 			'cf' => {
 				'account' => q{Amasal n tedrimt n tsiḍent},
 				'standard' => q{Amasal n tedrimt izeɣ},
 			},
 			'collation' => {
 				'ducet' => q{Tanila n usmizzwer Unicode amezwer},
 				'search' => q{Anadi amatu},
 				'standard' => q{Amizzwer deg ufran izeɣ},
 			},
 			'hc' => {
 				'h11' => q{Anagraw usrig 12 (0–11)},
 				'h12' => q{Anagraw usrig 12 (1–12)},
 				'h23' => q{Anagraw usrig 24 (0–23)},
 				'h24' => q{Anagraw usrig 24 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Aɣanib n tuɣalin ar udur ilelli},
 				'normal' => q{Aɣanib n tuɣalin ar udur amagnu},
 				'strict' => q{Aɣanib n tuɣalin ar udur uḥriṣ.},
 			},
 			'ms' => {
 				'metric' => q{Anagraw amitran},
 				'uksystem' => q{Anagraw n uktal Impiryal},
 				'ussystem' => q{Anagraw n uktal n Marikan},
 			},
 			'numbers' => {
 				'arab' => q{Izwilen aɛraben},
 				'arabext' => q{Izwilen aɛraben yettwasɣezfen},
 				'armn' => q{Izwilen iṛminiyen},
 				'armnlow' => q{Izwilen iṛminiyen meẓẓiyen},
 				'beng' => q{Izwilen ibingaliyen},
 				'deva' => q{Izwilen idivangariyen},
 				'ethi' => q{Izwilen ityupanen},
 				'fullwide' => q{Izwilen ihrawanen},
 				'geor' => q{Izwilen ijyuṛjiyen},
 				'grek' => q{Izwilen igrikiyen},
 				'greklow' => q{Izwilen igrikiyen imeẓyanen},
 				'gujr' => q{Izwilen iguǧaratiyen},
 				'guru' => q{Izwilen igurmuxiyen},
 				'hanidec' => q{Izwilen imrawen icinwaten},
 				'hans' => q{Izwilen iḥerfiyen icinwaten},
 				'hansfin' => q{Izwilen udrimen iḥerfiyen icinwaten},
 				'hant' => q{Izwilen imensayen icinwaten},
 				'hantfin' => q{Izwilen udrimen iḥerfiyen nicinwaten},
 				'hebr' => q{Izwilen iɛebriyen},
 				'jpan' => q{Izwilen ijapuniyen},
 				'jpanfin' => q{Izwilen udrimen ijjapuniyen},
 				'khmr' => q{Izwilen ixmariyen},
 				'knda' => q{Izwilen n Kannada},
 				'laoo' => q{Izwilen ilawsiyen},
 				'latn' => q{Izwilen n umalu},
 				'mlym' => q{Izwilen n Malayalam},
 				'mymr' => q{Izwilen n Myanmar},
 				'orya' => q{Izwilen uryanen},
 				'roman' => q{Izwilen iṛumanen},
 				'romanlow' => q{Izwilen iṛumanen imeẓyanen},
 				'taml' => q{Izwilen imensayen n ṭamil},
 				'tamldec' => q{Izwilen n Ṭamil},
 				'telu' => q{Izwilen n Tilugu},
 				'thai' => q{Izwilen n Ṭayland},
 				'tibt' => q{Izwilen Itibitanen},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{Amitran},
 			'UK' => q{Aglizi},
 			'US' => q{Amarikan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Tutlayt: {0}',
 			'script' => 'Tira: {0}',
 			'region' => 'Tamnaṭ: {0}',

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[o v]},
			index => ['A', 'B', 'C', 'Č', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', 'Ǧ', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z', 'Ẓ'],
			main => qr{[a b c č d ḍ e ɛ f g ǧ ɣ h ḥ i j k l m n p q r ṛ s ṣ t ṭ u w x y z ẓ]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- , ; \: ! ? . ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', 'Ǧ', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z', 'Ẓ'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(Ikṛan),
						'one' => q({0} n wakṛ),
						'other' => q({0} n ikṛen),
					},
					'astronomical-unit' => {
						'name' => q(iferdisen isnallunen),
						'one' => q({0} aferdis asnallun),
						'other' => q({0} iferdisen isnallunen),
					},
					'bit' => {
						'name' => q(abit),
						'one' => q({0} abit),
						'other' => q({0} ibiten),
					},
					'byte' => {
						'name' => q(aṭamḍan),
						'one' => q({0} aṭamdan),
						'other' => q({0} iṭamḍanen),
					},
					'calorie' => {
						'name' => q(ikaluriyen),
						'one' => q({0} n ukaluri),
						'other' => q({0} n ikaluriyen),
					},
					'centiliter' => {
						'name' => q(isantilitren),
						'one' => q({0} n usantilitr),
						'other' => q({0} n isantilitren),
					},
					'centimeter' => {
						'name' => q(isantimitren),
						'one' => q({0} n usantimitr),
						'other' => q({0} n isantimitren),
						'per' => q({0} deg usantimitr),
					},
					'century' => {
						'name' => q(leqrun),
						'one' => q({0} n lqern),
						'other' => q({0} n leqrun),
					},
					'coordinate' => {
						'east' => q({0} asammar),
						'north' => q({0} agafa),
						'south' => q({0} anẓul),
						'west' => q({0} amalu),
					},
					'cubic-centimeter' => {
						'name' => q(isantimitren uzmir-kraḍ),
						'one' => q({0} n usantimitr uzmir-kraḍ),
						'other' => q({0} n isantimitren uzmir-kraḍ),
						'per' => q({0} deg usantimitr uzmir-kraḍ),
					},
					'cubic-foot' => {
						'name' => q(iḍarren uzmir-kraḍ),
						'one' => q({0} n uḍar uzmir-kraḍ),
						'other' => q({0} n iḍarren uzmir-kraḍ),
					},
					'cubic-inch' => {
						'name' => q(idebbuzen uzmir-kraḍ),
						'one' => q({0} n udebbuz uzmir-kraḍ),
						'other' => q({0} n idebbuzen uzmir-kraḍ),
					},
					'cubic-kilometer' => {
						'name' => q(ikilumitren uzmir-kraḍ),
						'one' => q({0} n ukilumitr uzmir-kraḍ),
						'other' => q({0} n ikilumitren uzmir-kraḍ),
					},
					'cubic-meter' => {
						'name' => q(imitren uzmir-kraḍ),
						'one' => q({0} n umitr uzmir-kraḍ),
						'other' => q({0} n imitren uzmir-kraḍ),
						'per' => q({0} deg umitr uzmir-kraḍ),
					},
					'cubic-mile' => {
						'name' => q(imilen uzmir-kraḍ),
						'one' => q({0} n umil uzmir-kraḍ),
						'other' => q({0} n imilen uzmir-kraḍ),
					},
					'cubic-yard' => {
						'name' => q(iyaṛden uzmir-kraḍ),
						'one' => q({0} n uyaṛd uzmir-kraḍ),
						'other' => q({0} n iyaṛden uzmir-kraḍ),
					},
					'cup-metric' => {
						'name' => q(ifenjalen i mitranen),
						'one' => q({0} n ufenjal amitran),
						'other' => q({0} n ifenjalen imitranen),
					},
					'day' => {
						'name' => q(ussan),
						'one' => q({0} n wass),
						'other' => q({0} n wussan),
						'per' => q({0} deg ass),
					},
					'deciliter' => {
						'name' => q(idisilitren),
						'one' => q({0} n udisilitr),
						'other' => q({0} n idisiltren),
					},
					'decimeter' => {
						'name' => q(idisimitren),
						'one' => q({0} n udisimitr),
						'other' => q({0} n idisimitren),
					},
					'degree' => {
						'name' => q(tafesna),
						'one' => q({0} n tfesna),
						'other' => q({0} n tfesniwin),
					},
					'foodcalorie' => {
						'name' => q(Ikaluriyen),
						'one' => q({0} n ukaluri),
						'other' => q({0} n ikaluriyen),
					},
					'foot' => {
						'name' => q(iḍarren),
						'one' => q({0} n uḍaṛ),
						'other' => q({0} n iḍarren),
						'per' => q({0} deg uḍar),
					},
					'gallon' => {
						'name' => q(Igalunen),
						'one' => q({0} n ugalun),
						'other' => q({0} n igalunen),
						'per' => q({0} deg ugalun),
					},
					'gallon-imperial' => {
						'name' => q(Igalunen Imp.),
						'one' => q({0} n ugalun Imp.),
						'other' => q({0} n igalunen Imp.),
						'per' => q({0} deg ugalun Imp.),
					},
					'gigabit' => {
						'name' => q(igigabiten),
						'one' => q({0} agigabit),
						'other' => q({0} igigabiten),
					},
					'gigabyte' => {
						'name' => q(igigaṭamḍanen),
						'one' => q({0} n ugigaṭamḍan),
						'other' => q({0} n igigaṭamḍanen),
					},
					'gram' => {
						'name' => q(igramen),
						'one' => q({0} n ugram),
						'other' => q({0} n igramen),
						'per' => q({0} deg ugram),
					},
					'hectare' => {
						'name' => q(Ihiktaren),
						'one' => q({0} n uhictar),
						'other' => q({0} n ihiktaren),
					},
					'hectoliter' => {
						'name' => q(ihiktulitren),
						'one' => q({0} n uhiktulitr),
						'other' => q({0} n ihiktulitren),
					},
					'hectopascal' => {
						'name' => q(ihiktupaskalen),
						'one' => q({0} n uhiktupaskal),
						'other' => q({0} n ihiktupaskalen),
					},
					'hour' => {
						'name' => q(isragen),
						'one' => q({0} n usrag),
						'other' => q({0} n isragen),
						'per' => q({0} deg usrag),
					},
					'inch' => {
						'name' => q(idebbuzen),
						'one' => q({0} n udebbuz),
						'other' => q({0} n idebbuzen),
						'per' => q({0} deg udebbuz),
					},
					'joule' => {
						'name' => q(ijulen),
						'one' => q({0} n ujul),
						'other' => q({0} n ijulen),
					},
					'kilobit' => {
						'name' => q(ikilubiten),
						'one' => q({0} akilubit),
						'other' => q({0} ikilubiten),
					},
					'kilobyte' => {
						'name' => q(akiluṭamḍan),
						'one' => q({0} akiluṭamḍan),
						'other' => q({0} ikiluṭamḍanen),
					},
					'kilocalorie' => {
						'name' => q(Ikilukaluriyen),
						'one' => q({0} n ukilukaluri),
						'other' => q({0} n ikilukaluriyen),
					},
					'kilogram' => {
						'name' => q(ikilugramen),
						'one' => q({0} ukilugram),
						'other' => q({0} n ikilugramen),
						'per' => q({0} deg ukilugram),
					},
					'kilojoule' => {
						'name' => q(ikilujulen),
						'one' => q({0} n ukilujul),
						'other' => q({0} n ikilujulen),
					},
					'kilometer' => {
						'name' => q(Ikilumitren),
						'one' => q({0} n ukilumitr),
						'other' => q({0} n ikilumitren),
						'per' => q({0} deg ukilumitr),
					},
					'light-year' => {
						'name' => q(iseggasen n tafat),
						'one' => q({0} n useggas n tfat),
						'other' => q({0} n iseggasen n tafat),
					},
					'liter' => {
						'name' => q(ilitren),
						'one' => q({0} n ulitr),
						'other' => q({0} n ilitren),
						'per' => q({0} deg ulitr),
					},
					'lux' => {
						'name' => q(Aluks),
						'one' => q({0} lks),
						'other' => q({0} lks),
					},
					'megabit' => {
						'name' => q(imigabiten),
						'one' => q({0} amigabit),
						'other' => q({0} imigabiten),
					},
					'megabyte' => {
						'name' => q(imigaṭamḍanen),
						'one' => q({0} amigaṭamdan),
						'other' => q({0} imigaṭamḍanen),
					},
					'megaliter' => {
						'name' => q(imigalitren),
						'one' => q({0} n umigalitr),
						'other' => q({0} n imigalitren),
					},
					'meter' => {
						'name' => q(imitren),
						'one' => q({0} n umitr),
						'other' => q({0} n imitren),
						'per' => q({0} deg umitr),
					},
					'metric-ton' => {
						'name' => q(Iṭunen imitranen),
						'one' => q({0} n uṭun amitran),
						'other' => q({0} n iṭunen imitranen),
					},
					'microgram' => {
						'name' => q(imikrugramen),
						'one' => q({0} n umikrugram),
						'other' => q({0} n imikrugramen),
					},
					'micrometer' => {
						'name' => q(imikrumitren),
						'one' => q({0} n umikrumitr),
						'other' => q({0} n imikrumitren),
					},
					'microsecond' => {
						'name' => q(timikrusinin),
						'one' => q({0} n tmikrusint),
						'other' => q({0} n tmikrusinin),
					},
					'mile' => {
						'name' => q(imilen),
						'one' => q({0} n umil),
						'other' => q({0} n imilen),
					},
					'mile-scandinavian' => {
						'name' => q(amil askandinavi),
						'one' => q({0} n umil askandinavi),
						'other' => q({0} n imilen iskandanaviyen),
					},
					'milligram' => {
						'name' => q(imiligramen),
						'one' => q({0} n umiligram),
						'other' => q({0} n imiligramen),
					},
					'milliliter' => {
						'name' => q(imilitren),
						'one' => q({0} n umilitr),
						'other' => q({0} n imiltren),
					},
					'millimeter' => {
						'name' => q(imilimitren),
						'one' => q({0} n umilimitr),
						'other' => q({0} n imilimitren),
					},
					'millimole-per-liter' => {
						'name' => q(imilimulen deg ulitr),
						'one' => q({0} n umilimul deg ulitr),
						'other' => q({0} n imilimulen deg ulitr),
					},
					'millisecond' => {
						'name' => q(timilisinin),
						'one' => q({0} n tmilisint),
						'other' => q({0} n tmilisinin),
					},
					'minute' => {
						'name' => q(tisdatin),
						'one' => q({0} n tesdat),
						'other' => q({0} n tesdatin),
						'per' => q({0} di tesdat),
					},
					'month' => {
						'name' => q(Ayyuren),
						'one' => q({0} n wayyur),
						'other' => q({0} n wayyuren),
						'per' => q({0} deg ayyur),
					},
					'nanometer' => {
						'name' => q(inanumitren),
						'one' => q({0} n unanumitr),
						'other' => q({0} n inanumitren),
					},
					'nanosecond' => {
						'name' => q(tinanusinin),
						'one' => q({0} n tnanusint),
						'other' => q({0} n tnanusinin),
					},
					'nautical-mile' => {
						'name' => q(imilen iwlalen),
						'one' => q({0} n umil awlal),
						'other' => q({0} imilen iwlilen),
					},
					'parsec' => {
						'name' => q(iparsiken),
						'one' => q({0} n uparsik),
						'other' => q({0} n iparsiken),
					},
					'per' => {
						'1' => q({0} deg {1}),
					},
					'picometer' => {
						'name' => q(ipiktumitren),
						'one' => q({0} n upiktumitr),
						'other' => q({0} n ipiktumitren),
					},
					'pint-metric' => {
						'name' => q(ipinten imitranen),
						'one' => q({0} n upint amitran),
						'other' => q({0} n ipinten imitranen),
					},
					'point' => {
						'name' => q(tineqqiḍin),
						'one' => q({0} n tneqqiṭ),
						'other' => q({0} n tneqqiḍin),
					},
					'pound' => {
						'name' => q(ipawnden),
						'one' => q({0} n upawnd),
						'other' => q({0} ipawnden),
						'per' => q({0} deg upawnd),
					},
					'radian' => {
						'name' => q(irdyanen),
						'one' => q({0} n uṛadyan),
						'other' => q({0} iṛadyanen),
					},
					'second' => {
						'name' => q(tisinin),
						'one' => q({0} n tasint),
						'other' => q({0} n tisinin),
						'per' => q({0} deg tasint),
					},
					'square-centimeter' => {
						'name' => q(isantimitren uzmir-sin),
						'one' => q({0} n usantimitr uzmir-sin),
						'other' => q({0} n isantimitren uzmir-sin),
						'per' => q({0} deg usantimitr uzmir-sin),
					},
					'square-foot' => {
						'name' => q(iḍarren uzmir-sin),
						'one' => q({0} n udar uzmir-sin),
						'other' => q({0} n iḍarren uzmir-sin),
					},
					'square-inch' => {
						'name' => q(idebbuzen uzmir-sin),
						'one' => q({0} n udebbuz uzmir-sin),
						'other' => q({0} n idebbuzen uzmir-sin),
						'per' => q({0} deg udebbuz uzmir-sin),
					},
					'square-kilometer' => {
						'name' => q(ikilumitren uzmir-sin),
						'one' => q({0} n ukilumitr uzmir-sin),
						'other' => q({0} n ikilumitren uzmir-sin),
						'per' => q({0} deg ukilumitr uzmir-sin),
					},
					'square-meter' => {
						'name' => q(imitren uzmir-sin),
						'one' => q({0} n umitr uzmir-sin),
						'other' => q({0} n imitren uzmir-sin),
						'per' => q({0} deg umitr uzmir-sin),
					},
					'square-mile' => {
						'name' => q(imilen uzmir-sin),
						'one' => q({0} n umiluzmir-sin),
						'other' => q({0} n imilen uzmir-sin),
						'per' => q({0} deg umil uzmir-sin),
					},
					'square-yard' => {
						'name' => q(iyaṛden uzmir-sin),
						'one' => q({0} n uyaṛd uzmir-sin),
						'other' => q({0} n iyaṛden uzmir-sin),
					},
					'terabit' => {
						'name' => q(itirabiten),
						'one' => q({0} atirabit),
						'other' => q({0} itirabiten),
					},
					'terabyte' => {
						'name' => q(itiraṭamḍanen),
						'one' => q({0} atiramḍan),
						'other' => q({0} itiramḍanen),
					},
					'ton' => {
						'name' => q(iṭunen),
						'one' => q({0} n uṭun),
						'other' => q({0} n iṭenen),
					},
					'week' => {
						'name' => q(imalasen),
						'one' => q({0} n umalas),
						'other' => q({0} n imalasen),
						'per' => q({0} deg umalas),
					},
					'yard' => {
						'name' => q(iyarden),
						'one' => q({0} n uyard),
						'other' => q({0} n iyarden),
					},
					'year' => {
						'name' => q(iseggasen),
						'one' => q({0} n useggas),
						'other' => q({0} n iseggasen),
						'per' => q({0} deg useggas),
					},
				},
				'narrow' => {
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					'coordinate' => {
						'east' => q({0}SM),
						'north' => q({0}GF),
						'south' => q({0}NZ),
						'west' => q({0}ML),
					},
					'day' => {
						'name' => q(ass),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'gram' => {
						'name' => q(grm),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(asrag),
						'one' => q({0}r),
						'other' => q({0}r),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'liter' => {
						'name' => q(alitr),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(mtsn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					'minute' => {
						'name' => q(tsd),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'month' => {
						'name' => q(ayyur),
						'one' => q({0}y),
						'other' => q({0}y),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(tsn),
						'one' => q({0}n),
						'other' => q({0}n),
					},
					'week' => {
						'name' => q(ml),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'year' => {
						'name' => q(sg),
						'one' => q({0}g),
						'other' => q({0}g),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(Ikṛen),
						'one' => q({0} kṛ),
						'other' => q({0} kṛ),
					},
					'astronomical-unit' => {
						'name' => q(fl),
						'one' => q({0} fl),
						'other' => q({0} fl),
					},
					'bit' => {
						'name' => q(abit),
						'one' => q({0} abit),
						'other' => q({0} abit),
					},
					'byte' => {
						'name' => q(aṭamḍan),
						'one' => q({0} aṭamḍan),
						'other' => q({0} aṭamḍan),
					},
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(q),
						'one' => q({0} q),
						'other' => q({0} q),
					},
					'coordinate' => {
						'east' => q({0} SM),
						'north' => q({0} GF),
						'south' => q({0} NZ),
						'west' => q({0} ML),
					},
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(iḍarren³),
						'one' => q({0} ḍr³),
						'other' => q({0} ḍr³),
					},
					'cubic-inch' => {
						'name' => q(idebbuzen³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(iyaṛden³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup-metric' => {
						'name' => q(fnjl),
						'one' => q({0} fnjl),
						'other' => q({0} fnjl),
					},
					'day' => {
						'name' => q(ussan),
						'one' => q({0} n wass),
						'other' => q({0} n wussan),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(tifesniwin),
						'one' => q({0} fsn),
						'other' => q({0} fsn),
					},
					'foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'foot' => {
						'name' => q(iḍarren),
						'one' => q({0} ḍr),
						'other' => q({0} ḍr),
						'per' => q({0}/ḍr),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal MAR),
					},
					'gallon-imperial' => {
						'name' => q(gal Imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GAṬM),
						'one' => q({0} GAṬ),
						'other' => q({0} GAṬ),
					},
					'gram' => {
						'name' => q(grmn),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ihiktaren),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hour' => {
						'name' => q(isragen),
						'one' => q({0} sr),
						'other' => q({0} sr),
						'per' => q({0}/r),
					},
					'inch' => {
						'name' => q(idebbuzen),
						'one' => q({0} db),
						'other' => q({0} db),
						'per' => q({0}/db),
					},
					'joule' => {
						'name' => q(ijulen),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(KAṬ),
						'one' => q({0} KAṬ),
						'other' => q({0} kAṬ),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilojoule' => {
						'name' => q(akilujul),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'light-year' => {
						'name' => q(sgs n tafat),
						'one' => q({0} gf),
						'other' => q({0} gf),
					},
					'liter' => {
						'name' => q(ilitren),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'lux' => {
						'name' => q(lks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MAṬ),
						'one' => q({0} MAṬ),
						'other' => q({0} MAṬ),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmitr),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μtsn),
						'one' => q({0} μn),
						'other' => q({0} μn),
					},
					'mile' => {
						'name' => q(imilen),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(timilisn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					'minute' => {
						'name' => q(tisd),
						'one' => q({0} tsd),
						'other' => q({0} tsd),
						'per' => q({0}/tsd),
					},
					'month' => {
						'name' => q(ayyuren),
						'one' => q({0} yyr),
						'other' => q({0} yyrn),
						'per' => q({0}/y),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanutsn),
						'one' => q({0} nn),
						'other' => q({0} nn),
					},
					'nautical-mile' => {
						'name' => q(mwl),
						'one' => q({0} mwl),
						'other' => q({0} mwl),
					},
					'parsec' => {
						'name' => q(iparsiken),
						'one' => q({0} ps),
						'other' => q({0} ps),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(tineqqiḍin),
						'one' => q({0} nq),
						'other' => q({0} nq),
					},
					'pound' => {
						'name' => q(ipawnden),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'radian' => {
						'name' => q(iṛadyanen),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'second' => {
						'name' => q(tisn),
						'one' => q({0} tsn),
						'other' => q({0} tsn),
						'per' => q({0}/n),
					},
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					'square-foot' => {
						'name' => q(aḍar uz.sin.),
						'one' => q({0} ḍr zm.sn.),
						'other' => q({0} ḍr zm.sn.),
					},
					'square-inch' => {
						'name' => q(idebbuzen²),
						'one' => q({0} db²),
						'other' => q({0} db²),
						'per' => q({0}/db²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(imlen uz.sin.),
						'one' => q({0} mi uz.sin.),
						'other' => q({0} mi uz.sin.),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(iyaṛden²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TAṬ),
						'other' => q({0} TAṬ),
					},
					'ton' => {
						'name' => q(iṭunen),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'week' => {
						'name' => q(imalasen),
						'one' => q({0} ml),
						'other' => q({0} mls),
						'per' => q({0}/m),
					},
					'yard' => {
						'name' => q(iyarden),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(iseggasen),
						'one' => q({0} sg),
						'other' => q({0} sgn),
						'per' => q({0}/g),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ih|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Uhu|U|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(Z),
			'group' => q( ),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(MdM),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'1000' => {
					'one' => '0G',
					'other' => '0G',
				},
				'10000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000' => {
					'one' => '000G',
					'other' => '000G',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0L',
					'other' => '0L',
				},
				'10000000000' => {
					'one' => '00L',
					'other' => '00L',
				},
				'100000000000' => {
					'one' => '000L',
					'other' => '000L',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 n wagim',
					'other' => '0 n wagimen',
				},
				'10000' => {
					'one' => '00 n wagimen',
					'other' => '00 n wagimen',
				},
				'100000' => {
					'one' => '000 n wagimen',
					'other' => '000 n wagimen',
				},
				'1000000' => {
					'one' => '0 n umilyun',
					'other' => '0 n imelyunen',
				},
				'10000000' => {
					'one' => '00 n imelyunen',
					'other' => '00 n imelyunen',
				},
				'100000000' => {
					'one' => '000 n imelyunen',
					'other' => '000 n imelyunen',
				},
				'1000000000' => {
					'one' => '0 n umelyaṛ',
					'other' => '0 n imelyaṛen',
				},
				'10000000000' => {
					'one' => '00 n imelyaṛen',
					'other' => '00 n imelyaṛen',
				},
				'100000000000' => {
					'one' => '000 n imelyaṛen',
					'other' => '000 n imelyaṛen',
				},
				'1000000000000' => {
					'one' => '0 n utrilyun',
					'other' => '0 n itrilyunen',
				},
				'10000000000000' => {
					'one' => '00 n itrilyunen',
					'other' => '00 n itrilyunen',
				},
				'100000000000000' => {
					'one' => '000 n itrilyunen',
					'other' => '000 n itrilyunen',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0G',
					'other' => '0G',
				},
				'10000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000' => {
					'one' => '000G',
					'other' => '000G',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0L',
					'other' => '0L',
				},
				'10000000000' => {
					'one' => '00L',
					'other' => '00L',
				},
				'100000000000' => {
					'one' => '000L',
					'other' => '000L',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
					'standard' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ADP' => {
			symbol => 'ADP',
			display_name => {
				'currency' => q(Apisetas Anduran),
				'one' => q(Apisetas Anduran),
				'other' => q(Ipisetasen Induranen),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Adirham n Tgeldunin Taɛrabin Yedduklen),
				'one' => q(Adirham n Tigludniwin tiɛrabin idduklen),
				'other' => q(Idirhamen n Tigludniwin tiɛrabin idduklen),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afɣani \(1927–2002\)),
				'one' => q(Afɣani \(1927–2002\)),
				'other' => q(Ifɣaniyen \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afɣani Afɣan),
				'one' => q(Afɣani Afɣan),
				'other' => q(Ifɣaniyen ifɣanen),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(Alek Albani \(1947–1961\)),
				'one' => q(Alek Albani \(1947–1961\)),
				'other' => q(Ilekan Ilbaniyen \(1947–1961\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Alek Albani),
				'one' => q(Alek Albani),
				'other' => q(Ilekan Ilbaniyen),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Adram Armini),
				'one' => q(Adram Armini),
				'other' => q(Idramen Irminiyen),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Afluran n Antilles),
				'one' => q(Afluran n Antilles),
				'other' => q(Ifluranen n Antilles),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Akwanza n Ungula),
				'one' => q(Akwanza n Angula),
				'other' => q(Ikwanzayen n Angula),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(Akwanza n Angula \(1977–1990\)),
				'one' => q(Akwanza n Angula \(1977–1990\)),
				'other' => q(Ikwanzayen n Angula \(1977–1990\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(Akwanza amaynut n Angula \(1990–2000\)),
				'one' => q(Akwanza amaynut n Angula \(1990–2000\)),
				'other' => q(Ikwanzayen imaynuten n Angula \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(Akwanza n Angula yettwaseggmen \(1995–1999\)),
				'one' => q(Akwanza n Angula yettwaseggmen \(1995–1999\)),
				'other' => q(Ikwanzayen n Angula yettwaseggmen \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(Ustral n Arjuntin),
				'one' => q(Ustral n Arjuntin),
				'other' => q(Ustralen n Arjuntin),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(Apisu aẓayan n Arjuntin \(1970–1983\)),
				'one' => q(Apisu aẓayan n Arjuntin \(1970–1983\)),
				'other' => q(Ipisuten iẓayanen n Arjuntin \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(Apisu n Arjuntin \(1881–1970\)),
				'one' => q(Apisu n Arjuntin \(1881–1970\)),
				'other' => q(Ipisuten n Arjuntin \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(Apisu n Arjuntin \(1983–1985\)),
				'one' => q(Apisu n Arjuntin \(1983–1985\)),
				'other' => q(Ipisuten n Arjuntin \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => '$AR',
			display_name => {
				'currency' => q(Apisu n Arjuntin),
				'one' => q(Apisu n Arjuntin),
				'other' => q(Ipisuten n Arjuntin),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Aciling n Ustriya),
				'one' => q(Aciling n Ustriya),
				'other' => q(Icilingen n Ustriya),
			},
		},
		'AUD' => {
			symbol => '$AU',
			display_name => {
				'currency' => q(Adular n Lusṭrali),
				'one' => q(Adulaṛ n Ustriya),
				'other' => q(Idulaṛen n Ustriya),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Afluran n Aruba),
				'one' => q(Afluran n Aruba),
				'other' => q(Ifluranen n Aruba),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(Amanat Aziri \(1993–2006\)),
				'one' => q(Amanat Aziri \(1993–2006\)),
				'other' => q(Imanaten Aziri \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Amanat Aziri),
				'one' => q(Amanat Aziri),
				'other' => q(Imanaten Iziriyen),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Adinar Abusni),
				'one' => q(Adinar Abusni),
				'other' => q(Idinaren Ibusniyen),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Amark yettwaseklaten n Busni),
				'one' => q(Amark yettwaseklaten n Busni),
				'other' => q(Imarken yettwaseklaten n Busni),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Adulaṛ n Barbuda),
				'one' => q(Adulaṛ n Barbuda),
				'other' => q(Idulaṛen n Barbuda),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Ataka n Bingladic),
				'one' => q(Ataka n Bingladic),
				'other' => q(Itakaten n Bingladic),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Afrank n Biljik \(yettwaselkaten\)),
				'one' => q(Afrank n Biljik \(yettwaselkaten\)),
				'other' => q(Ifranken n Biljik \(yettwaselkaten\)),
			},
		},
		'BEF' => {
			symbol => 'FB',
			display_name => {
				'currency' => q(Afrank n Biljik),
				'one' => q(Afrank n Biljik),
				'other' => q(Ifranken n Biljik),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Afrank n Biljik \(adriman\)),
				'one' => q(Afrank n Biljik \(adriman\)),
				'other' => q(Ifranken n Biljik \(idrimanen\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Alev n Bulgar \(1962–1999\)),
				'one' => q(Alev n Bulgar \(1962–1999\)),
				'other' => q(Ilevan n Bulgar \(1962–1999\)),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Alev n Bulgar),
				'one' => q(Alev n Bulgar),
				'other' => q(Ilevan n Bulgar),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Adinar Abaḥrini),
				'one' => q(Adinar n Baḥrayn),
				'other' => q(Idinaren n Baḥrayn),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Afrank Aburandi),
				'one' => q(Afrank n Burundi),
				'other' => q(Ifranken n Burundi),
			},
		},
		'BMD' => {
			symbol => '$BM',
			display_name => {
				'currency' => q(Adulaṛ n Birmud),
				'one' => q(Adulaṛ n Birmud),
				'other' => q(Idularen n Birmud),
			},
		},
		'BND' => {
			symbol => '$BN',
			display_name => {
				'currency' => q(adular n Brunay),
				'one' => q(Adular n Brunay),
				'other' => q(Idularen n Brunay),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Abulivyanu n Bulivi),
				'one' => q(Abulivyanu n Bulivi),
				'other' => q(Ibulivyanen n Bulivi),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(Abulivyanu n Bulivi \(1863–1963\)),
				'one' => q(Abulivyanu n Bulivi \(1863–1963\)),
				'other' => q(Ibulivyanen n Bulivi \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(Apisu n Bulivi),
				'one' => q(Apisu n Bulivi),
				'other' => q(Ipisuten n Bulivi),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(Amevdul n Bulivi),
				'one' => q(Amevdul n Bulivi),
				'other' => q(Imevdulen n Bulivi),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(Akruziru amaynut n Brizil \(1967–1986\)),
				'one' => q(Akruziru amaynut n Brizil \(1967–1986\)),
				'other' => q(Ikruziruyen imaynuten n Brizil \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(Akruzadu n Brizil \(1986–1989\)),
				'one' => q(Akruzadu n Brizil \(1986–1989\)),
				'other' => q(Ikruzaduyen n Brizil \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(Akruziru n Brizil \(1990–1993\)),
				'one' => q(Akruziru n Brizil \(1990–1993\)),
				'other' => q(Ikruziruyen n Brizil \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Ariyal n Brizil),
				'one' => q(Ariyal n Brizil),
				'other' => q(Iriyalen n Brizil),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(Akruzadu amaynut n Brizil),
				'one' => q(Akruzadu amaynut n Brizil \(1989–1990\)),
				'other' => q(Ikruzaduyen imaynuten n Brizil \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(Akruziru),
				'one' => q(Akruziru Ariyal n Brizil\(1993–1994\)),
				'other' => q(Ikruziruyen Iriyalen n Brizil \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(Akruziru n Brizil \(1942–1967\)),
				'one' => q(Akruziru n Brizil \(1942–1967\)),
				'other' => q(Ikruziruyen n Brizil \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => '$BS',
			display_name => {
				'currency' => q(Adular n Bahamas),
				'one' => q(Adular n Bahamas),
				'other' => q(Idularen n Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Angultrum n Butan),
				'one' => q(Angultrum n Butan),
				'other' => q(Ingultrumen n Butan),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(Akyat n Burma),
				'one' => q(Akyat n Burma),
				'other' => q(Ikyaten n Burma),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Apula Abusṭwanan),
				'one' => q(Apula n Butswana),
				'other' => q(Ipula n Butswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Arubl amaynut n Bilarus \(1994–1999\)),
				'one' => q(Arubl amaynut n Bilarus \(1994–1999\)),
				'other' => q(Irublen amaynut n Bilarus \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Arubl n Bilarus),
				'one' => q(Arubl n Bilarus),
				'other' => q(Irublen n Bilarus),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Arubl n Bilarus \(2000–2016\)),
				'one' => q(Arubl n Bilarus \(2000–2016\)),
				'other' => q(Irublen n Bilarus \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => '$BZ',
			display_name => {
				'currency' => q(Adular n Biliz),
				'one' => q(Adular n Biliz),
				'other' => q(Idularen n Biliz),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(Adular Akanadi),
				'one' => q(Adular Akanadi),
				'other' => q(Idularen n Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Afrank Akunguli),
				'one' => q(Afrank n Kungu),
				'other' => q(Ifranken n Kungu),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Uru WIR),
				'one' => q(Uru WIR),
				'other' => q(Uruten WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Afrank Aswis),
				'one' => q(Afrank n Swis),
				'other' => q(Ifranken n Swis),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Afrank WIR),
				'one' => q(Afrank WIR),
				'other' => q(Ifranken WIR),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(Askudu n Cili),
				'one' => q(Askudu n Cili),
				'other' => q(Iskuduyen n Cili),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(Aferdis n Usefti n Cili),
				'one' => q(Aferdis n Usefti n Cili),
				'other' => q(Iferdisen n Usefti n Cili),
			},
		},
		'CLP' => {
			symbol => '$CL',
			display_name => {
				'currency' => q(Apisu n Cili),
				'one' => q(Apisu n Cili),
				'other' => q(Ipisuten n Cili),
			},
		},
		'CNX' => {
			symbol => 'CNX',
			display_name => {
				'currency' => q(Adular n Lbanka Taɣerfant n Tacinwit),
				'one' => q(Adular n Lbanka Taɣerfant n Tacinwit),
				'other' => q(Idularen n Lbanka Taɣerfant n Tacinwit),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(Ayuwan Renminbi Acinwa),
				'one' => q(Ayuan arenminbi acinwi),
				'other' => q(Iyuanen irenminbiyen icinwiyen),
			},
		},
		'COP' => {
			symbol => '$CO',
			display_name => {
				'currency' => q(Apisu n Kulumbi),
				'one' => q(Apisu n Kulumbi),
				'other' => q(Ipisuten n Kulumbi),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(Aferdis n wazal ilaw n Kulumbi),
				'one' => q(Aferdis n wazal ilaw n Kulumbi),
				'other' => q(Iferdisen n wazal ilaw n Kulumbi),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Akulun n Kustarika),
				'one' => q(Akulun n Kustarika),
				'other' => q(Ikulunen n Kustarika),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Adinar n Ṣirbya-Muntinigru),
				'one' => q(Adinar n Ṣirbya-Muntinigru),
				'other' => q(Idinaren n Ṣirbya-Muntinigru),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Akurun iǧehden Ačikusluvak),
				'one' => q(Akurun iǧehden Ačikusluvak),
				'other' => q(Ikurunen iǧehden Ičikusluvaken),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Apisu n Kuba yettwaselkaten),
				'one' => q(Apisu n Kuba yettwaselkaten),
				'other' => q(Ipisuten n Kuba yettwaselkaten),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Apisu n Kuba),
				'one' => q(Apisu n Kuba),
				'other' => q(Ipisuten n Kuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Akabuviradinu Askudi),
				'one' => q(Askudu n Kapvir),
				'other' => q(Iskuduyen n Kapvir),
			},
		},
		'CYP' => {
			symbol => '£CY',
			display_name => {
				'currency' => q(Apawnd n Cipr),
				'one' => q(Apawnd n Cipr),
				'other' => q(Ipawnden n Cipr),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Akurun n Čik),
				'one' => q(Akurun n Čik),
				'other' => q(Ikurunen n Čik),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Amark n Walman n usammar),
				'one' => q(Amark n Walman n usammar),
				'other' => q(Imarken n Walman n usammar),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Amark n Walman),
				'one' => q(Amark n Walman),
				'other' => q(Imarken n Walman),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Afrank Ajibuti),
				'one' => q(Afrank n Ǧibuti),
				'other' => q(Ifranken n Ǧibuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Akurun n Danmark),
				'one' => q(Akurun n Danmark),
				'other' => q(Ikurunen n Danmark),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Apisu n Duminik),
				'one' => q(Apisu n Duminik),
				'other' => q(Ipisuten n Duminik),
			},
		},
		'DZD' => {
			symbol => 'DA',
			display_name => {
				'currency' => q(Adinar Azzayri),
				'one' => q(Adinar n Zzayer),
				'other' => q(Idinaren n Zzayer),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(Asukr n Ikwaṭur),
				'one' => q(Asukr n Ikwaṭur),
				'other' => q(Isukren n Ikwaṭur),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(Aferdis n wazal ameɣlal n Ikwaṭur \(UVC\)),
				'one' => q(Aferdis n wazal ameɣlal n Ikwaṭur \(UVC\)),
				'other' => q(Iferdisen n wazal ameɣlal n Ikwaṭur \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Akurun n Isṭunya),
				'one' => q(Akurun n Isṭunya),
				'other' => q(Ikurunen n Isṭunya),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Apund Amaṣri),
				'one' => q(Ipawnd n Maṣeṛ),
				'other' => q(Ipawnden n Maṣeṛ),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Anakfa Iritiri),
				'one' => q(Anafka n Iritirya),
				'other' => q(Inafkayen n Iritirya),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(Apisetas n Spanya \(amiḍan A\)),
				'one' => q(Apisetas n Spanya \(amiḍan A\)),
				'other' => q(Ipisetasen n Spanya \(amiḍan A\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(Apisetas n Spanya \(amiḍan yettwaselkaten\)),
				'one' => q(Apisetas n Spanya \(amiḍan yettwaselkaten\)),
				'other' => q(Ipisetasen n Spanya \(amiḍan yettwaselkaten\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Apisetas n Spanya),
				'one' => q(Apisetas n Spanya),
				'other' => q(Ipisetasen n Spanya),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Abir Utyupi),
				'one' => q(Abirr n Ityupya),
				'other' => q(Ibirren n Ityupya),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Uru),
				'one' => q(URU),
				'other' => q(URUTEN),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(Amark n Finland),
				'one' => q(Amark n Finland),
				'other' => q(Imarken n Finland),
			},
		},
		'FJD' => {
			symbol => '$FJ',
			display_name => {
				'currency' => q(Adular n Fiǧi),
				'one' => q(Adular n Fiǧi),
				'other' => q(Idularen n Fiǧi),
			},
		},
		'FKP' => {
			symbol => '£FK',
			display_name => {
				'currency' => q(Apawnd n tegzrin n Malwin),
				'one' => q(Apawnd n tegzrin n Malwin),
				'other' => q(Ipawnden n tegzrin n Malwin),
			},
		},
		'FRF' => {
			symbol => 'F',
			display_name => {
				'currency' => q(Afrank n Fṛansa),
				'one' => q(Afrank n Fṛansa),
				'other' => q(Ifranken n Fṛansa),
			},
		},
		'GBP' => {
			symbol => '£GB',
			display_name => {
				'currency' => q(Apund Aglizi),
				'one' => q(Apawnd n Sterling),
				'other' => q(Ipawnden n Sterling),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(Akupun n Larin Jyujya),
				'one' => q(Akupun n Larin Jyujya),
				'other' => q(Ikupunen n Larin Jyujya),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Alari n Jyurjya),
				'one' => q(Alari n Jyurjya),
				'other' => q(Ilariyen n Jyurjya),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Asidi Aɣani),
				'one' => q(Asidi n Ɣana \(1967–2007\)),
				'other' => q(Isidiyen n Ɣana \(1967–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Asidi n Ɣana),
				'one' => q(Asidi n Ɣana),
				'other' => q(Isidiyen n Ɣana),
			},
		},
		'GIP' => {
			symbol => '£GI',
			display_name => {
				'currency' => q(Apawnd n Jibraltar),
				'one' => q(Apawnd n Jibraltar),
				'other' => q(Ipawnden n Jibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Adalasi Agambi),
				'one' => q(Adalasi n Gambya),
				'other' => q(Idalasiyen n Gambya),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Afrank n Ɣinya),
				'one' => q(Afrank n Ɣinya),
				'other' => q(Ifranken n Ɣinya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Afrank Aɣini),
				'one' => q(Azili n Ɣinya),
				'other' => q(Iziliyen n Ɣinya),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(Akwili n Ɣinya Tasebgast),
				'one' => q(Akwili n Ɣinya Tasebgast),
				'other' => q(Akwili n Ɣinya Tasebgast),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(Adrakmi n Grik),
				'one' => q(Adrakmi n Grik),
				'other' => q(Idrakmiyen n Grik),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Aketzal n Gwatimala),
				'one' => q(Aketzal n Gwatimala),
				'other' => q(Iketzalen n Gwatimala),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(Askudu n Ɣinya tapurtugit),
				'one' => q(Askudu n Ɣinya tapurtugit),
				'other' => q(Iskuduyen n Ɣinya tapurtugit),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Apisu n Ɣinya-Bisaw),
				'one' => q(Apisu n Ɣinya-Bisaw),
				'other' => q(Ipisuten n Ɣinya-Bisaw),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Adular n Guyana),
				'one' => q(Adular n Guyana),
				'other' => q(Idularen n Guyana),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Adular n Hung Kung),
				'one' => q(Adular n Hung Kung),
				'other' => q(Idularen n Hung Kung),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Alampir n Hunduras),
				'one' => q(Alampir n Hunduras),
				'other' => q(Ilampiren n Hunduras),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Adinar n Kaṛwasya),
				'one' => q(Adinar n Kaṛwasya),
				'other' => q(Idinaren n Kaṛwasya),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Akuna n Kaṛwasya),
				'one' => q(Akuna n Kaṛwasya),
				'other' => q(Ikunayen n Kaṛwasya),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Agurd n Hayti),
				'one' => q(Agurd n Hayti),
				'other' => q(Igurden n Hayti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Afurint n Hungaṛya),
				'one' => q(Afurint n Hungaṛya),
				'other' => q(Ifurinten n Hungaṛya),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Arupi n Indunisya),
				'one' => q(Arupi n Indunisya),
				'other' => q(Irupiyen n Indunisya),
			},
		},
		'IEP' => {
			symbol => '£IE',
			display_name => {
				'currency' => q(Apawnd n Irland),
				'one' => q(Apawnd n Irland),
				'other' => q(Ipawnden n Irland),
			},
		},
		'ILP' => {
			symbol => '£IL',
			display_name => {
				'currency' => q(Apawnd n Izrayil),
				'one' => q(Apawnd n Izrayil),
				'other' => q(Ipawnden n Izrayil),
			},
		},
		'ILR' => {
			symbol => 'ILR',
			display_name => {
				'currency' => q(Acikil n Izrayil\(1980–1985\)),
				'one' => q(Acikil n Izrayil\(1980–1985\)),
				'other' => q(Icikilen n Izrayil \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Acikil amaynut n Izrayil),
				'one' => q(Acikil amaynut n Izrayil),
				'other' => q(Acikilen amaynut n Izrayil),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Arupi Ahendi),
				'one' => q(Arupi n Hend),
				'other' => q(Irupiyen n Hend),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Adinar n Ɛiṛaq),
				'one' => q(Adinar n Ɛiṛaq),
				'other' => q(Idinaren n Ɛiṛaq),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Ariyal n Iran),
				'one' => q(Ariyal n Iran),
				'other' => q(Iriyalen n Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Akurun n Island),
				'one' => q(Akurun n Island),
				'other' => q(Ikurunen n Island),
			},
		},
		'ITL' => {
			symbol => '₤IT',
			display_name => {
				'currency' => q(Alir n Ṭelyan),
				'one' => q(Alir n Ṭelyan),
				'other' => q(Iliren n Ṭelyan),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Adular n Jamayik),
				'one' => q(Adular n Jamayik),
				'other' => q(Idularen n Jamayik),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Adinar Jurdan),
				'one' => q(Adinar n Jurdan),
				'other' => q(Idinaren n Jurdan),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(Ayen Ajappuni),
				'one' => q(Iyen N Japun),
				'other' => q(Iyenen N Japun),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Aciling Akini),
				'one' => q(Aciling n Kinya),
				'other' => q(Icilingen n Kinya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Asum n Kirigistan),
				'one' => q(Asum n Kirigistan),
				'other' => q(Isumen n Kirigistan),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Ariyil n Kambuj),
				'one' => q(Ariyil n Kambuj),
				'other' => q(Iriyilen n Kambuj),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Afrank Akamiruni),
				'one' => q(Afrank n Kumur),
				'other' => q(Ifranken n Kumur),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Awun n Tkurit n ugafa),
				'one' => q(Awun n Tkurit n ugafa),
				'other' => q(Iwunen n Tkurit n ugafa),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(Ahwan n Tkirit n unẓul \(1953–1962\)),
				'one' => q(Ahwan n Tkirit n unẓul \(1953–1962\)),
				'other' => q(Ihwanen n Tkirit n unẓul \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(Ahwan n Tkirit n unẓul \(1945–1953\)),
				'one' => q(Ahwan n Tkirit n unẓul \(1945–1953\)),
				'other' => q(Ihwanen n Tkirit n unẓul \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Ahwan n Tkirit n unẓul),
				'one' => q(Ahwan n Tkirit n unẓul),
				'other' => q(Ihwanen n Tkirit n unẓul),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Adinarn Kuwayt),
				'one' => q(Adinarn Kuwayt),
				'other' => q(Idinaren n Kuwayt),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Adular n tegzirin Kayman),
				'one' => q(Adular n tegzirin Kayman),
				'other' => q(Idularen n tegzirin Kayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Atunj n Kazaxistan),
				'one' => q(Atunj n Kazaxistan),
				'other' => q(Itunjen n Kazaxistan),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Akip n Laws),
				'one' => q(Akip n Laws),
				'other' => q(Ikipen n Laws),
			},
		},
		'LBP' => {
			symbol => '£LB',
			display_name => {
				'currency' => q(Apawnd n Liban),
				'one' => q(Apawnd n Liban),
				'other' => q(Ipawnden n Liban),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Arupi n Srilanka),
				'one' => q(Arupi n Srilanka),
				'other' => q(Irupiyen n Srilanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Adular Alibiri),
				'one' => q(Adular n libirya),
				'other' => q(Idularen n libirya),
			},
		},
		'LSL' => {
			symbol => 'lLS',
			display_name => {
				'currency' => q(Aluṭi Alizuṭi),
				'one' => q(Aluti n Lizuṭu),
				'other' => q(Ilutiyen n Lizuṭu),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Alitas n Litwanya),
				'one' => q(Alitas n Litwanya),
				'other' => q(Ilitasen n Litwanya),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Atalonas n Litwanya),
				'one' => q(Atalonas n Litwanya),
				'other' => q(Italonasen n Litwanya),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Afrank yettwaseklaten n Luksumburg),
				'one' => q(Afrank yettwaseklaten n Luksumburg),
				'other' => q(Ifranken yettwaseklaten n Luksumburg),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Afrank n Luksumburg),
				'one' => q(Afrank n Luksumburg),
				'other' => q(Ifranken n Luksumburg),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Afrank adriman n Luksumburg),
				'one' => q(Afrank adriman n Luksumburg),
				'other' => q(Ifranken idrimanen n Luksumburg),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Alats n Letunya),
				'one' => q(Alats n Letunya),
				'other' => q(Ilatsen n Letunya),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Arubl n Litunya),
				'one' => q(Arubl n Litunya),
				'other' => q(Irublen n Litunya),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Adinar Alibi),
				'one' => q(Adinar n Libya),
				'other' => q(Idinaren n Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Adirham Amerruki),
				'one' => q(Adirham n Meṛṛuk),
				'other' => q(Idirhamen n Meṛṛuk),
			},
		},
		'MAF' => {
			symbol => 'fMA',
			display_name => {
				'currency' => q(Afrank n Meṛṛuk),
				'one' => q(Afrank n Meṛṛuk),
				'other' => q(Ifranken n Meṛṛuk),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Alu n Muldavya),
				'one' => q(Alu n Muldavya),
				'other' => q(Iluten n Muldavya),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Aryari Amalgac),
				'one' => q(Aryari n Madagaskaṛ),
				'other' => q(Iryariyen n Madagaskaṛ),
			},
		},
		'MGF' => {
			symbol => 'Fmg',
			display_name => {
				'currency' => q(Afrank n Madakaskaṛ),
				'one' => q(Afrank n Madakaskaṛ),
				'other' => q(Ifranken n Madakaskaṛ),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Adenar n Masidunya),
				'one' => q(Adenar n Masidunya),
				'other' => q(I denaren n Masidunya),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Afrank n Mali),
				'one' => q(Afrank n Mali),
				'other' => q(Ifranken n Mali),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Akyat n Myanmar),
				'one' => q(Akyat n Myanmar),
				'other' => q(Ikyaten n Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Atugrik n Mungulya),
				'one' => q(Atugrik n Mungulya),
				'other' => q(Itugriken n Mungulya),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Apataka n Makaw),
				'one' => q(Apataka n Makaw),
				'other' => q(Ipatakayen n Makaw),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Agiya Amuriṭani \(1973–2017\)),
				'one' => q(Ugiya n Muritaniya \(1973–2017\)),
				'other' => q(Ugiyaten n Muritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Agiya Amuriṭani),
				'one' => q(Ugiya n Muritaniya),
				'other' => q(Ugiyaten n Muritaniya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Alir n Malt),
				'one' => q(Alir n Malt),
				'other' => q(Iliren n Malt),
			},
		},
		'MTP' => {
			symbol => '£MT',
			display_name => {
				'currency' => q(Apawnd n Malt),
				'one' => q(Apawnd n Malt),
				'other' => q(Ipawnden n Malt),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Arupi Amurisi),
				'one' => q(Arupi n Muris),
				'other' => q(Irupiyen n Muris),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(Arupi n Maldiv),
				'one' => q(Arupi n Maldiv),
				'other' => q(Trupiyen n Maldiv),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Arufiya n Maldiv),
				'one' => q(Arufiya n Maldiv),
				'other' => q(Irufiyaten n Maldiv),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Akwaca Amalawi),
				'one' => q(Akwaca n Malawi),
				'other' => q(Ikwacayen n Malawi),
			},
		},
		'MXN' => {
			symbol => '$MX',
			display_name => {
				'currency' => q(Apisu Miksik),
				'one' => q(Apisu Miksik),
				'other' => q(Ipisuten Miksik),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Apisu n lfeṭṭa n Miksik \(1861–1992\)),
				'one' => q(Apisu n lfeṭṭa n Miksik \(1861–1992\)),
				'other' => q(Ipisuten n lfeṭṭa n Miksik \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Aferdis n uselket n Miksi \(UDI\)),
				'one' => q(Aferdis n uselket n Miksi \(UDI\)),
				'other' => q(Iferdisen n uselket n Miksi \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Aringgit n Malizya),
				'one' => q(Aringgit n Malizya),
				'other' => q(Iringgiten n Malizya),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(Askudu n Muzumbik),
				'one' => q(Askudu n Muzumbik),
				'other' => q(Iskuduyen n Muzumbik),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(Amitikal Amuzembiqi),
				'one' => q(Amitikal n Muzumbik \(1980–2006\)),
				'other' => q(Imitikalen n Muzumbik \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Amitikal n Muzumbik),
				'one' => q(Amitikal n Muzumbik),
				'other' => q(Imitikalen n Muzumbik),
			},
		},
		'NAD' => {
			symbol => '$NA',
			display_name => {
				'currency' => q(Adular Anamibi),
				'one' => q(Adular n Namibya),
				'other' => q(Idularen n Namibya),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Anayra Anijiri),
				'one' => q(Anayra n Nijirua),
				'other' => q(Inayrayen n Nijirua),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(Akurduba n Nikaragwa \(1912–1988\)),
				'one' => q(Akurduba n Nikaragwa \(1912–1988\)),
				'other' => q(Ikurdubayen n Nikaragwa \(1912–1988\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Akurduba n Nikaragwa),
				'one' => q(Akurduba n Nikaragwa),
				'other' => q(Ikurdubayen n Nikaragwa),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Aflurin n Huland),
				'one' => q(Aflurin n Huland),
				'other' => q(Iflurinen n Huland),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Akurun n Nurvij),
				'one' => q(Akurun n Nurvij),
				'other' => q(Ikurunen n Nurvij),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Arupi n Nipal),
				'one' => q(Arupi n Nipal),
				'other' => q(Irupiyen n Nipal),
			},
		},
		'NZD' => {
			symbol => '$NZ',
			display_name => {
				'currency' => q(Adular n Ziland Tamaynut),
				'one' => q(Adular n Ziland Tamaynut),
				'other' => q(Idularen n Ziland Tamaynut),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Ariyal n Ɛuman),
				'one' => q(Ariyal n Ɛuman),
				'other' => q(Iriyalen n Ɛuman),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Abalbwa n Panama),
				'one' => q(Abalbwa n Panama),
				'other' => q(Ibalbwayen n Panama),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(Inti n Piru),
				'one' => q(Inti n Piru),
				'other' => q(Intiyen n Piru),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Asul amaynut n Piru),
				'one' => q(Asul amaynut n Piru),
				'other' => q(Isulen amaynut n Piru),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(Asul n Piru \(1863–1985\)),
				'one' => q(Asul n Piru \(1863–1985\)),
				'other' => q(Isulen n Piru \(1863–1985\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Akina n Papwazi n Ɣinya Tamaynut),
				'one' => q(Akina n Papwazi n Ɣinya Tamaynut),
				'other' => q(Ikinayen n Papwazi n Ɣinya Tamaynut),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Apisu n Filipin),
				'one' => q(Apisu n Filipin),
				'other' => q(Ipisuten n Filipin),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Arupi n Pakistan),
				'one' => q(Arupi n Pakistan),
				'other' => q(Irupiyen n Pakistan),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Azluti n Puland),
				'one' => q(Azluti n Puland),
				'other' => q(Izlutiyen n Puland),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Azluti n Pulund \(1950–1995\)),
				'one' => q(Azluti n Pulund \(1950–1995\)),
				'other' => q(Izlutiyen n Pulund \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Askudu n Purtugal),
				'one' => q(Askudu n Purtugal),
				'other' => q(Iskuduten n Purtugal),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Agarani n Paragway),
				'one' => q(Agarani n Paragway),
				'other' => q(Igaraniyen n Paragway),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Ariyal n Qatar),
				'one' => q(Ariyal n Qatar),
				'other' => q(Iriyalen n Qatar),
			},
		},
		'RHD' => {
			symbol => '$RH',
			display_name => {
				'currency' => q(Adular Arudizyan),
				'one' => q(Adular Arudizyan),
				'other' => q(Idularen Irudizyanen),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Alu aqbuṛ n Rumanya \(1952–2005\)),
				'one' => q(Alu aqbuṛ n Rumanya \(1952–2005\)),
				'other' => q(Iluten iqbuṛen n Rumanya \(1952–2005\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Alu n Rumanya),
				'one' => q(Alu n Rumanya),
				'other' => q(Ilen n Rumanya),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Adinar n Ṣirbya),
				'one' => q(Adinar n Ṣirbya),
				'other' => q(Idinaren n Ṣirbya),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Arubl n Rrus),
				'one' => q(Arubl n Rrus),
				'other' => q(Irublen n Rrus),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Arubl n Rrus \(1991–1998\)),
				'one' => q(Arubl n Rrus \(1991–1998\)),
				'other' => q(Irublen n Rrus \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Afrank Aruwandi),
				'one' => q(Afrank n Rwanda),
				'other' => q(Ifranken n Rwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Aryal Asuɛudi),
				'one' => q(Ariyal n Saɛudya),
				'other' => q(Iriyalen n Saɛudya),
			},
		},
		'SBD' => {
			symbol => '$SB',
			display_name => {
				'currency' => q(Adular n tegzirin Salumun),
				'one' => q(Adular n tegzirin Salumun),
				'other' => q(Idularen n tegzirin Salumun),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Arupi Aseycili),
				'one' => q(Arupi n Saycal),
				'other' => q(Irupiyen n Saycal),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(Adinar n Sudan \(1992–2007\)),
				'one' => q(Adinar n Sudan \(1992–2007\)),
				'other' => q(Idinaren n Sudan \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Apund Asudani),
				'one' => q(Apawnd n Sudan),
				'other' => q(Ipawnden n Sudan),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(Apawnd n Sudan \(1956–2007\)),
				'one' => q(Apawnd n Sudan \(1956–2007\)),
				'other' => q(Ipawnden n Sudan \(1956–2007\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Akurun n Swid),
				'one' => q(Akurun n Swid),
				'other' => q(Akurun n Swid),
			},
		},
		'SGD' => {
			symbol => '$SG',
			display_name => {
				'currency' => q(Adular n Sangapur),
				'one' => q(Adular n Sangapur),
				'other' => q(Idularen n Sangapur),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Apund Asant Ilini),
				'one' => q(Apawnd n San Ilina),
				'other' => q(Ipawnden n San Ilina),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Atular n Sluvinya),
				'one' => q(Atular n Sluvinya),
				'other' => q(Itularen n Sluvinya),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Akurun n Sluvakya),
				'one' => q(Akurun n Sluvakya),
				'other' => q(Ikurunen n Sluvakya),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Alyun),
				'one' => q(Aliyun n Sira Lyun),
				'other' => q(Iliyunen n Sira Lyun),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Aciling Aṣumali),
				'one' => q(Aciling n Ṣumal),
				'other' => q(Icilingen n Ṣumal),
			},
		},
		'SRD' => {
			symbol => '$SR',
			display_name => {
				'currency' => q(Adular n Surinam),
				'one' => q(Adular n Surinam),
				'other' => q(Idularen n Surinam),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(Aflurin n Surinam),
				'one' => q(Aflurin n Surinam),
				'other' => q(Iflurinen n Surinam),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Apawnd n Sudan n Unẓul),
				'one' => q(Apawnd n Sudan n Unẓul),
				'other' => q(Ipawnden n Sudan n Unẓul),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Asw Ṭum d Udubra Amenzay \(1977–2017\)),
				'one' => q(Adubra n Sint-Toma \(1977–2017\)),
				'other' => q(Idubrayen n Sint-Toma \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(Asw Ṭum d Udubra Amenzay),
				'one' => q(Adubra n Sint-Toma),
				'other' => q(Idubrayen n Sint-Toma),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Arubl n Suvyat),
				'one' => q(Arubl n Suvyat),
				'other' => q(Irublen n Suvyat),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(Akulun n Salvadur),
				'one' => q(Akulun n Salvadur),
				'other' => q(Ikulunen n Salvadur),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Apawnd n Surya),
				'one' => q(Apawnd n Surya),
				'other' => q(Ipawnden n Surya),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Alilangini),
				'one' => q(Alilangeni n Swazilan),
				'other' => q(Ililangeniyen n Swazilan),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Abaht n Tayland),
				'one' => q(Abaht n Tayland),
				'other' => q(Ibahten n Tayland),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Arubl n Ṭajikistan),
				'one' => q(Arubl n Ṭajikistan),
				'other' => q(Irublen n Ṭajikistan),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Asumuni n Ṭajikistan),
				'one' => q(Asumuni n Ṭajikistan),
				'other' => q(Isumuniyen n Ṭajikistan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Amanat n Ṭurkmanistan),
				'one' => q(Amanat n Ṭurkmanistan),
				'other' => q(Imanaten n Ṭurkmanistan),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Amanat amaynut n Ṭurkmanistan),
				'one' => q(Amanat amaynut n Ṭurkmanistan),
				'other' => q(Imanaten imaynuten n Ṭurkmanistan),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Adinar Atunsi),
				'one' => q(Adinar n Tunes),
				'other' => q(Idinaren n Tunes),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Apanga n Ṭunga),
				'one' => q(Apanga n Ṭunga),
				'other' => q(Ipangayen n Ṭunga),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Askudu n Timur),
				'one' => q(Askudu n Timur),
				'other' => q(Iskuduyen n Timur),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(Apawnd n Ṭurk \(1844–2005\)),
				'one' => q(Apawnd n Ṭurk \(1844–2005\)),
				'other' => q(Ipawnden n Ṭurk \(1844–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Apawnd n Ṭurk),
				'one' => q(Apawnd n Ṭurk),
				'other' => q(Ipawnden n Ṭurk),
			},
		},
		'TTD' => {
			symbol => '$TT',
			display_name => {
				'currency' => q(Adular n Triniti-d-Ṭubagu),
				'one' => q(Adular n Triniti-d-Ṭubagu),
				'other' => q(Idularen n Triniti-d-Ṭubagu),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(Adular amaynut n Taywan),
				'one' => q(Adular amaynut n Taywan),
				'other' => q(Idularen amaynut n Taywan),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Aciling Aṭanẓani),
				'one' => q(Aciling n Ṭanzanya),
				'other' => q(Icilingen n Ṭanzanya),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ahrivnya n Ukrin),
				'one' => q(Ahrivnya n Ukrin),
				'other' => q(Ihrivnyaen n Ukrin),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Akarbuvanit n Ukrin \(1992–1996\)),
				'one' => q(Akarbuvanit n Ukrin \(1992–1996\)),
				'other' => q(Ikarbuvaniten n Ukrin \(1992–1996\)),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Aciling n Uganda \(1966–1987\)),
				'one' => q(Aciling n Uganda \(1966–1987\)),
				'other' => q(Icilingen n Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Aciling Awgandi),
				'one' => q(Aciling n Uganda),
				'other' => q(Icilingen n Uganda),
			},
		},
		'USD' => {
			symbol => '$US',
			display_name => {
				'currency' => q(Adular WD),
				'one' => q(Adular n Marikan),
				'other' => q(Idularen n Marikan),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(Adular n Marikan \(azekka–yen\)),
				'one' => q(Adular n Marikan \(azekka–yen\)),
				'other' => q(Idularen n Marikan \(azekka–yen\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(Adular n Marikan \(ass–en\)),
				'one' => q(Adular n Marikan \(ass–en\)),
				'other' => q(Idularen n Marikan \(ass–en\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(Apisu n Urugway \(iferdisen s umatar\)),
				'one' => q(Apisu n Urugway \(iferdisen s umatar\)),
				'other' => q(Ipisuten n Urugway \(iferdisen s umatar\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(Apisu n Urugway \(1975–1993\)),
				'one' => q(Apisu n Urugway \(1975–1993\)),
				'other' => q(Ipisuten n Urugway \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => '$UY',
			display_name => {
				'currency' => q(Apisu n Urugway),
				'one' => q(Apisu n Urugway),
				'other' => q(Ipisuten n Urugway),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Asum n Uzbikistan),
				'one' => q(Asum n Uzbikistan),
				'other' => q(Isumen n Uzbikistan),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Abulivaṛ n Vinizwila \(1871–2008\)),
				'one' => q(Abulivaṛ n Vinizwila \(1871–2008\)),
				'other' => q(Ibulivaṛen n Vinizwila \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Abulivaṛ n Vinizwila \(2008–2018\)),
				'one' => q(Abulivaṛ n Vinizwila \(2008–2018\)),
				'other' => q(Ibulivaṛen n Vinizwila \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Abulivaṛ n Vinizwila),
				'one' => q(Abulivaṛ n Vinizwila),
				'other' => q(Ibulivaṛen n Vinizwila),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Adung n Vyitnam),
				'one' => q(Adung n Vyitnam),
				'other' => q(Idungen n Vyitnam),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(Adung n Vyitnam \(1978–1985\)),
				'one' => q(Adung n Vyitnam \(1978–1985\)),
				'other' => q(Idungen n Vyitnam \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Avatu n Vanuyatu),
				'one' => q(Avatu n Vanuyatu),
				'other' => q(Ivatuyen n Vanuyatu),
			},
		},
		'WST' => {
			symbol => 'WS$',
			display_name => {
				'currency' => q(Atala n Samwa),
				'one' => q(Atala n Samwa),
				'other' => q(Italayen n Samwa),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Afrank BCEA CFA),
				'one' => q(Afrank n CFA \(BEAC\)),
				'other' => q(Ifranken n CFA \(BEAC\)),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(lfeṭṭa),
				'one' => q(Uns Ṭruy n lfe),
				'other' => q(Unsen Ṭruy n lfe),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(Awraɣ),
				'one' => q(Uns Ṭruy n n uwraɣ),
				'other' => q(Unsen Ṭruy n n uwraɣ),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Aferdis n tufut uddis \(URKU\)),
				'one' => q(Aferdis n tufut uddis \(URKU\)),
				'other' => q(Iferdisen n tufut uddisen \(URKU\)),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Aferdis n tedrimt n tufurt \(UME–6\)),
				'one' => q(Aferdis n tedrimt n tufurt \(UME–6\)),
				'other' => q(Aferdis n tedrimt n tufurt \(UME–6\)),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(Aferdis n umiḍan n turfut \(UEC–9\)),
				'one' => q(Aferdis n umiḍan n turfut \(UEC–9\)),
				'other' => q(Iferdisen n umiḍan n turfut \(UEC–9\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(Aferdis n umiḍan 17 n turfut \(UEC–17\)),
				'one' => q(Aferdis n umiḍan 17 n turfut \(UEC–17\)),
				'other' => q(Iferdisen n umiḍan 17 n turfut \(UEC–17\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(Adular n Karayib n usammar),
				'one' => q(Adular n Karayib n usammar),
				'other' => q(Idularen n Karayib n usammar),
			},
		},
		'XDR' => {
			symbol => 'DTS',
			display_name => {
				'currency' => q(droit de tirage spécial),
				'one' => q(droit de tirage spécial),
				'other' => q(droits de tirage spéciaux),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Aferdis n umiḍan n turfut \(ACU\)),
				'one' => q(Aferdis n umiḍan n turfut \(ACU\)),
				'other' => q(Iferdisen n umiḍan n turfut \(ACU\)),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(Afrank awraɣ),
				'one' => q(Afrank n awraɣ),
				'other' => q(Ifranken n uwraɣ),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(Afrank UIC),
				'one' => q(Afrank UIC),
				'other' => q(Ifranken UIC),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Afrank BCEAO CFA),
				'one' => q(Afrank CFA \(BCEAO\)),
				'other' => q(Ifranken CFA \(BCEAO\)),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(Palladium),
				'one' => q(Uns n Ṭrwa n palladium),
				'other' => q(Unsen n Ṭrwa n palladium),
			},
		},
		'XPF' => {
			symbol => 'FCFP',
			display_name => {
				'currency' => q(Afrank CFP),
				'one' => q(Afrank CFP),
				'other' => q(Ifranken CFP),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(Platin),
				'one' => q(Uns n Ṭrwa n Platin),
				'other' => q(Unsen n Ṭrwa n Platin),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(Anaw n idran RINET),
				'one' => q(Aferdis n idran RINET),
				'other' => q(Aferdis n idran RINET),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(Asukr),
				'one' => q(Asukr),
				'other' => q(Isukren),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(\(tadrimt n usefkyed\)),
				'one' => q(\(tadrimt n usefkyed\)),
				'other' => q(\(tadrimt n usefkyed\)),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(Aferdis n umiḍan ADB),
				'one' => q(Aferdis n umiḍan ADB),
				'other' => q(Iferdisen n umiḍan ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Tadrimt tarussint neɣ tarameɣtut),
				'one' => q(Tadrimt tarussint),
				'other' => q(Tadrimt tirussinin),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(Adinar n Yaman),
				'one' => q(Adinar n Yaman),
				'other' => q(Idinaren n Yaman),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Ariyal n Yaman),
				'one' => q(Ariyal n Yaman),
				'other' => q(Iriyalen n Yaman),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Adinar n Yuguslavya amaynut \(1966–1989\)),
				'one' => q(Adinar n Yuguslavya amaynut \(1966–1989\)),
				'other' => q(Adinar n Yuguslavya amaynut \(1966–1989\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Adinar n Yuguslavya amaynut \(1994–2003\)),
				'one' => q(Adinar n Yuguslavya amaynut \(1994–2003\)),
				'other' => q(Idinaren n Yuguslavya amaynut \(1994–2003\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Adinar n Yuguslavya yettwaselkaten \(1990–1992\)),
				'one' => q(Adinar n Yuguslavya yettwaselkaten \(1990–1992\)),
				'other' => q(Idinaren n Yuguslavya yettwaselkaten \(1990–1992\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(Arand n Tefriqt n unzul \(adriman\)),
				'one' => q(Arand n Tefriqt n unzul \(adriman\)),
				'other' => q(Iranden n Tefriqt n unzul \(idrimanen\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Arand Afriqi n Wadda),
				'one' => q(Arand n Tefriqt n unzul),
				'other' => q(Iranden n Tefriqt n unzul),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Akwaca Azambi \(1968–2012\)),
				'one' => q(Akwaca n Ẓambya \(1968–2012\)),
				'other' => q(Ikwacayen n Ẓambya \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Akwaca Azambi),
				'one' => q(Akwaca n Ẓambya),
				'other' => q(Ikwacayen n Ẓambya),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(Azayir amaynut n Zayir),
				'one' => q(Azayir amaynut n Zayir),
				'other' => q(Izayiren imaynuten n Zayir),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(Azayir n Zayir),
				'one' => q(Azayir n Zayir),
				'other' => q(Izayiren n Zayir),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(Adular Azimbabwi),
				'one' => q(Adular n zimbabwi),
				'other' => q(Idularen n zimbabwi),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Adular n zimbabwi \(2009\)),
				'one' => q(Adular n zimbabwi \(2009\)),
				'other' => q(Idularen n zimbabwi \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(Adular n zimbabwi \(2008\)),
				'one' => q(Adular n zimbabwi \(2008\)),
				'other' => q(Idularen n zimbabwi \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Yen',
							'Fur',
							'Meɣ',
							'Yeb',
							'May',
							'Yun',
							'Yul',
							'Ɣuc',
							'Cte',
							'Tub',
							'Nun',
							'Duǧ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Y',
							'F',
							'Ɣ',
							'B',
							'M',
							'N',
							'L',
							'C',
							'T',
							'R',
							'W',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yennayer',
							'Fuṛar',
							'Meɣres',
							'Yebrir',
							'Mayyu',
							'Yunyu',
							'Yulyu',
							'Ɣuct',
							'Ctembeṛ',
							'Tubeṛ',
							'Nunembeṛ',
							'Duǧembeṛ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Yen',
							'Fur',
							'Meɣ',
							'Yeb',
							'May',
							'Yun',
							'Yul',
							'Ɣuc',
							'Cte',
							'Tub',
							'Wam',
							'Duj'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Y',
							'F',
							'M',
							'Y',
							'M',
							'Y',
							'Y',
							'Ɣ',
							'C',
							'T',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yennayer',
							'Fuṛar',
							'Meɣres',
							'Yebrir',
							'Mayyu',
							'Yunyu',
							'Yulyu',
							'Ɣuct',
							'Ctembeṛ',
							'Tubeṛ',
							'Wambeṛ',
							'Duǧembeṛ'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'San',
						tue => 'Kraḍ',
						wed => 'Kuẓ',
						thu => 'Sam',
						fri => 'Sḍis',
						sat => 'Say',
						sun => 'Yan'
					},
					narrow => {
						mon => 'R',
						tue => 'A',
						wed => 'H',
						thu => 'M',
						fri => 'S',
						sat => 'D',
						sun => 'C'
					},
					short => {
						mon => 'Ri',
						tue => 'Ra',
						wed => 'Hd',
						thu => 'Mh',
						fri => 'Sm',
						sat => 'Sd',
						sun => 'Cr'
					},
					wide => {
						mon => 'Sanass',
						tue => 'Kraḍass',
						wed => 'Kuẓass',
						thu => 'Samass',
						fri => 'Sḍisass',
						sat => 'Sayass',
						sun => 'Yanass'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Ari',
						tue => 'Ara',
						wed => 'Aha',
						thu => 'Amh',
						fri => 'Sem',
						sat => 'Sed',
						sun => 'Ace'
					},
					narrow => {
						mon => 'S',
						tue => 'K',
						wed => 'K',
						thu => 'S',
						fri => 'S',
						sat => 'S',
						sun => 'Y'
					},
					short => {
						mon => 'Ri',
						tue => 'Ra',
						wed => 'Hd',
						thu => 'Md',
						fri => 'Sm',
						sat => 'Sd',
						sun => 'Cr'
					},
					wide => {
						mon => 'Arim',
						tue => 'Aram',
						wed => 'Ahad',
						thu => 'Amhad',
						fri => 'Sem',
						sat => 'Sed',
						sun => 'Acer'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {0 => 'Kḍg1',
						1 => 'Kḍg2',
						2 => 'Kḍg3',
						3 => 'Kḍg4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'akraḍaggur amenzu',
						1 => 'akraḍaggur wis-sin',
						2 => 'akraḍaggur wis-kraḍ',
						3 => 'akraḍaggur wis-kuẓ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Kḍg1',
						1 => 'Kḍg2',
						2 => 'Kḍg3',
						3 => 'Kḍg4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'akraḍaggur amenzu',
						1 => 'akraḍaggur wis-sin',
						2 => 'akraḍaggur wis-kraḍ',
						3 => 'akraḍaggur wis-kuẓ'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{n tufat},
					'pm' => q{n tmeddit},
				},
				'narrow' => {
					'am' => q{f},
					'pm' => q{m},
				},
				'wide' => {
					'am' => q{n tufat},
					'pm' => q{n tmeddit},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{FT},
					'pm' => q{MD},
				},
				'narrow' => {
					'am' => q{FT},
					'pm' => q{MD},
				},
				'wide' => {
					'am' => q{FT},
					'pm' => q{MD},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'snd. T.Ɛ',
				'1' => 'sld. T.Ɛ'
			},
			wide => {
				'0' => 'send talalit n Ɛisa',
				'1' => 'seld talalit n Ɛisa'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'af' {0}},
			'long' => q{{1} 'af' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'af' {0}},
			'long' => q{{1} 'af' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{M},
			MEd => q{MM-dd, E},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{M},
			MEd => q{MM-dd, E},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMW => q{'amalas' W 'n' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'amalas' w 'n' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(KLG {0}),
		gmtZeroFormat => q(KLG),
		regionFormat => q(akud: {0}),
		regionFormat => q({0} (akud n unebdu)),
		regionFormat => q({0} (akud amagnu)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Akud n Afɣanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abiǧan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akṛa#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Zzayer#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisaw#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Bṛazavil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kayṛu#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Sebta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Kunakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Ǧibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Dwala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Leɛyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Friṭawn#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaburun#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harari#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Juhanisburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xaṛtum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kincaṣa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomi#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luwanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaci#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Luzaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbaban#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadicu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nayrobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Nǧamina#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Nyamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nwakcuṭ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Puṛtu-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Ṣaw Ṭumi#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunes#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Akud n tefriqt talemmast#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Akud n tefriqt n usammar#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Akud amagnu n tefriqt n unẓul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Akud n unebdu n tefriqt n umalu#,
				'generic' => q#Akud n tefriqt n umalu#,
				'standard' => q#Akud amagnu n tefriqt n umalu#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Akud n Unebdu n Alaska#,
				'generic' => q#Akud n Alaska#,
				'standard' => q#Akud Amagnu n Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Akud n Unebdu n Amaẓun#,
				'generic' => q#Akud n Amaẓun#,
				'standard' => q#Akud Amagnu n Amaẓun#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankṛaj#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiga#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bhya Bandiṛas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Baṛbadus#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Biliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blun-Sablun#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Bwaẓ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Cikagu#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Ciwawa#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Antikukan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kusta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kristun#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kuračaw#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkcavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawsun#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawsun Krik#,
		},
		'America/Denver' => {
			exemplarCity => q#Dinver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Ditrwa#,
		},
		'America/Dominica' => {
			exemplarCity => q#Duminik#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Idmuntun#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvaduṛ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico City#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Akud n Unebdu n Tlemmast n Marikan#,
				'generic' => q#Akud n Tlemmast n Marikan#,
				'standard' => q#Akud Amagnu n Tlemmast n Marikan#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Akud n Unebdu n Usammar Agafa n Marikan#,
				'generic' => q#Akud n Usammar Agafa n Marikan#,
				'standard' => q#Akud Amagnu n Usammar Agafa n Marikan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Akud n Unebdu n Idurar n Marikan#,
				'generic' => q#Akud n Idurar n Marikan#,
				'standard' => q#Akud Amagnu n Idurar n Marikan#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Akud Amelwi n Unebdu n Marikan n Ugafa#,
				'generic' => q#Akud Amelwi n Marikan n Ugafa#,
				'standard' => q#Akud Amelwi Amagnu n Marikan n Ugafa#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Alpa#,
				'generic' => q#Akud n Alpa#,
				'standard' => q#Akud Amagnu n Alpa#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Akud Aɛrab n Unebdu#,
				'generic' => q#Akud Aɛrab#,
				'standard' => q#Akud Amagnu Aɛrab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Akud n Unebdu n Arjuntin#,
				'generic' => q#Akud n Arjuntin#,
				'standard' => q#Akud Amagnu n Arjuntin#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Akud n Unebdu n Arjuntin n Usammar#,
				'generic' => q#Akud n Arjuntin n Usammar#,
				'standard' => q#Akud Amagnu n Arjuntin n Usammar#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Aṛminya#,
				'generic' => q#Akud n Aṛminya#,
				'standard' => q#Akud Amagnu n Aṛminya#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Ɛaden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ɛamman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baɣdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baḥrayn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bayrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunay#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Kwabalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damas#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Ɣeza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hung Kung#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makaw#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyungyung#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Siyul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Cangay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sangapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Ṭaypay#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Akud Aṭlasan n Unebdu#,
				'generic' => q#Akud Aṭlasan#,
				'standard' => q#Akud Amagnu Aṭlasan#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Aẓuris#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Birmud#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Tigzirin n Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Vir#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faṛawi#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Jyuṛjya n Unẓul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant Ilina#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adilayid#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisban#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Malburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ustralya Talemmast#,
				'generic' => q#Akud n Ustralya Talemmast#,
				'standard' => q#Akud Amagnu n Ustralya Talemmast#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Akud n Unebdu n Tlemmast n Umalu n Ustṛalya#,
				'generic' => q#Akud n Tlemmast n Umalu n Ustṛalya#,
				'standard' => q#Akud Amagnu n Tlemmast n Umalu n Ustṛalya#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ustṛalya n Usammar#,
				'generic' => q#Akud n Ustṛalya n Usammar#,
				'standard' => q#Akud Amagnu n Ustṛalya n Usammar#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Akud n Unebdu Ustṛalya n Umalu#,
				'generic' => q#Akud n Ustṛalya n Umalu#,
				'standard' => q#Akud Amagnu n Ustṛalya n Umalu#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Aziṛbiǧan#,
				'generic' => q#Akud n Aziṛbiǧan#,
				'standard' => q#Akud Amagnu n Aziṛbiǧan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Akud n unebdu n Aẓuris#,
				'generic' => q#Akud n Aẓuris#,
				'standard' => q#Akud amagnu n Aẓuris#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Akud n Unebdu n Bingladic#,
				'generic' => q#Akud n Bingladic#,
				'standard' => q#Akud Amagnu n Bingladic#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Akud n Butan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Akud n Bulivi#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Bṛazilya#,
				'generic' => q#Akud n Bṛazilya#,
				'standard' => q#Akud Amagnu n Bṛazilya#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Akud n Brunay Dar Salam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Akud n unebdu n Kap Viṛ#,
				'generic' => q#Akud n Kap Viṛ#,
				'standard' => q#Akud amagnu n Kap Viṛ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Akud Amagnu n Camuṛṛu#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Akud n Unebdu Catham#,
				'generic' => q#Akud n Catham#,
				'standard' => q#Akud Amagnu n Catham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Akud n Unebdu n Cili#,
				'generic' => q#Akud n Cili#,
				'standard' => q#Akud Amagnu n Cili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Akud n Unebdu n Cin#,
				'generic' => q#Akud n Cin#,
				'standard' => q#Akud Amagnu n Cin#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Kwabalsan#,
				'generic' => q#Akud n Kwabalsan#,
				'standard' => q#Akud Amagnu n Kwabalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Akud n Tegzirin n Kristmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Akud n Tegzirin n Kuku#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Kulumbya#,
				'generic' => q#Akud n Kulumbya#,
				'standard' => q#Akud Amagnu n Kulumbya#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Akud n Unebdu n Tegzirin n Kuk#,
				'generic' => q#Akud n Tegzirin n Kuk#,
				'standard' => q#Akud Amagnu n Tegzirin n Kuk#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Akud n Unebdu n Kuba#,
				'generic' => q#Akud n Kuba#,
				'standard' => q#Akud Amagnu n Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Akud n Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Akud n Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Akud n Timuṛ n Usammar#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Akud n Unebdu n Island n Usammar#,
				'generic' => q#Akud n Island n Usammar#,
				'standard' => q#Akud Amagnu n Island n Usammar#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Akud n Ikwaṭur#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Akud Agraɣlan Imyuddsen#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Aɣrem Arussin#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amstirdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Anduṛ#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bilgṛad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Birlan#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bṛatislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruksil#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Buxarist#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapist#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublan#,
			long => {
				'daylight' => q#Agud Amagnu n Irland#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jibṛaltaṛ#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Girnizey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hilsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Tigzirt n Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jiṛzey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kyiv#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbun#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Akud n Unebdu n Britanya#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksumburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Munaku#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Akud n unebdu n Turuft Talemmast#,
				'generic' => q#Akud n Turuft Talemmast#,
				'standard' => q#Akud amagnu n Turuft Talemmast#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Akud n unebdu n Turuft n Usammar#,
				'generic' => q#Akud n Turuft n Usammar#,
				'standard' => q#Akud amagnu n Turuft n Usammar#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Akud nniḍen n Turuft n Usammar#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Akud n unebdu turuft n umalu#,
				'generic' => q#Akud n turuft n umalu#,
				'standard' => q#Akud amagnu n turuft n umalu#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Akud n Unebdu Tegzirin n Falkland#,
				'generic' => q#Akud n Tegzirin n Falkland#,
				'standard' => q#Akud Amagnu n Tegzirin n Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Akud n Unebdu n Fiji#,
				'generic' => q#Akud n Fiji#,
				'standard' => q#Akud Amagnu n Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Akud n Gwiyan Tafṛansist#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Akud n Wakal n Unẓul d Antaṛktik n Fṛansa#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Akud alemmas n Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Akud n Gapapaguṣ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Akud n Tegzirin Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Jyuṛjya#,
				'generic' => q#Akud n Jyuṛjya#,
				'standard' => q#Akud Amagnu n Jyuṛjya#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Akud n Tegzirin Jilbiṛ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Akud n Unebdu n Grinland n Usammar#,
				'generic' => q#Akud n Grinland n Usammar#,
				'standard' => q#Akud Amagnu n Grinland n Usammar#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Akud n Unebdu n Grinland n Umalu#,
				'generic' => q#Akud n Grinland n Umalu#,
				'standard' => q#Akud Amagnu n Grinland n Umalu#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Akud Amagnu n Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Akud n Gwiyan#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Akud n Unebu n Haway-Aliwsyan#,
				'generic' => q#Akud n Haway-Aliwsyan#,
				'standard' => q#Akud Amagnu n Haway-Aliwsyan#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Akud n Unebdu n Hung Kung#,
				'generic' => q#Akud n Hung Kung#,
				'standard' => q#Akud Amagnu n Hung Kung#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Akud n Unebdu n Hovd#,
				'generic' => q#Akud n Hovd#,
				'standard' => q#Akud Amagnu n Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Akud Amagnu n Hend#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Kumuṛ#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahi#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiv#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Muris#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayuṭ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Riyunyun#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Akud n Ugaraw Ahendi#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Akud n Inducin#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Akud n Tlemmast n Indunisya#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Akud n Usammar n Indunisya#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Akud n Umalu n Indunisya#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Akud n Unebdu Iran#,
				'generic' => q#Akud n Iran#,
				'standard' => q#Akud Amagnu n Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Akud n Unebdu n Irkutsk#,
				'generic' => q#Akud n Irkutsk#,
				'standard' => q#Akud Amagnu n Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Akud n Unebdu n Izrayil#,
				'generic' => q#Akud n Izrayil#,
				'standard' => q#Akud Amagnu n Izrayil#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Japun#,
				'generic' => q#Akud n Japun#,
				'standard' => q#Akud Amagnu n Japun#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Akud n Kazaxistan n Usammar#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Akud n Kazaxistan n Umalu#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Akud n Unebdu n Kurya#,
				'generic' => q#Akud n Kurya#,
				'standard' => q#Akud Amagnu n Kurya#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Akud n Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Akud n unebdu n Krasnoyarsk#,
				'generic' => q#Akud n Krasnoyarsk#,
				'standard' => q#Akud amagnu n Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Akud n Kirigistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Akud n Tegzirin Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Akud n Unebdu n Lord Howe#,
				'generic' => q#Akud n Lord Howe#,
				'standard' => q#Akud Amagnu n Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Akud n Markari#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Magadan#,
				'generic' => q#Akud n Magadan#,
				'standard' => q#Akud Amagnu n Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Akud n Malizya#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Akud n Maldiv#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Akud n Tegzirin Markiz#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Akud n Tegzirin Maṛcal#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Akud n unebdu n Muris#,
				'generic' => q#Akud n Muris#,
				'standard' => q#Akud amagnu n Muris#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Akud n Mawsun#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ugafa Amalu n Miksik#,
				'generic' => q#Akud n Ugafa Amalu n Miksik#,
				'standard' => q#Akud Amagnu n Ugafa Amalu n Miksik#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Akud Amelwi n Unebdu n Miksik#,
				'generic' => q#Akud Amelwi n Miksik#,
				'standard' => q#Akud amagnu Amelwi n Miksik#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ulan Bator#,
				'generic' => q#Akud n Ulan Bator#,
				'standard' => q#Akud Amagnu n Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Akud n Unebdu n Moscow#,
				'generic' => q#Akud n Moscow#,
				'standard' => q#Akud Amagnu n Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Akud n Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Akud n Nuru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Akud n Nipal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Akud n Unebdu n Kalidunya Tamaynut#,
				'generic' => q#Akud n Kalidunya Tamaynut#,
				'standard' => q#Akud Amagnu n Kalidunya Tamaynut#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Akud n Unebdu Ziland Tamaynut#,
				'generic' => q#Akud n Ziland Tamaynut#,
				'standard' => q#Akud Amagnu n Ziland Tamaynut#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Akud n Unebdu n Wakal Amaynut#,
				'generic' => q#Akud n Wakal Amaynut#,
				'standard' => q#Akud Amagnu n Wakal Amaynut#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Akud n Niyu#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Akud n Tigzirt n Nuṛfulk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Akud n Unebdu n Firnandu n Nurunha#,
				'generic' => q#Akud n Firnandu n Nurunha#,
				'standard' => q#Akud Amagnu n Firnandu n Nurunha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Akud n Unebdu n Novosibirsk#,
				'generic' => q#Akud n Novosibirsk#,
				'standard' => q#Akud Amagnu n Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Akud n Unebdu n Omsk#,
				'generic' => q#Akud n Omsk#,
				'standard' => q#Akud Amagnu n Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Ukland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Catham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Maṛkiz#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niyu#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nuṛfulk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Pakistan#,
				'generic' => q#Akud n Pakistan#,
				'standard' => q#Akud Amagnu n Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Akud n Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Akud n Papwazi n Ɣinya Tamaynut#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Akud n Unebdu n Paṛagway#,
				'generic' => q#Akud n Paṛagway#,
				'standard' => q#Akud Amagnu n Paṛagway#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Akud n Unebdu n Piru#,
				'generic' => q#Akud n Piru#,
				'standard' => q#Akud Amagnu n Piru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Akud n Unebdu n Filipin#,
				'generic' => q#Akud n Filipin#,
				'standard' => q#Akud Amagnu n Filipin#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Akud n Tegzirin n Finiks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Akud n Unebdu n San Pyir & Miklun#,
				'generic' => q#Akud n San Pyir & Miklun#,
				'standard' => q#Akud Amagnu n San Pyir & Miklun#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Akud n Pitkaṛn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Akud n Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Akud n Pyungyung#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Akud n Riyunyun#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Akud n Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Akud n Unebdu n Sakhalin#,
				'generic' => q#Akud n Sakhalin#,
				'standard' => q#Akud Amagnu n Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ṣamwa#,
				'generic' => q#Akud n Ṣamwa#,
				'standard' => q#Akud Amagnu n Ṣamwa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Akud n Saycal#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Akud Amagnu n Sangapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Akud n Tegzirin Salumun#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Akud n Jyuṛjya n Unẓul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Akud n Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Akud n Syuwa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Akud n Tayti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ṭaypay#,
				'generic' => q#Akud n Ṭaypay#,
				'standard' => q#Akud Amagnu n Ṭaypay#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Akud n Ṭajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Akud n Ṭukilaw#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ṭunga#,
				'generic' => q#Akud n Ṭunga#,
				'standard' => q#Akud Amagnu n Ṭunga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Akud n Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Ṭurkmanistan#,
				'generic' => q#Akud n Ṭurkmanistan#,
				'standard' => q#Akud Amagnu n Ṭurkmanistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Akud n Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Akud n Unebdu n Urugway#,
				'generic' => q#Akud n Urugway#,
				'standard' => q#Akud amagnu n Urugway#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Akud n Unebdu n Uzbikistan#,
				'generic' => q#Akud n Uzbikistan#,
				'standard' => q#Akud Amagnu n Uzbikistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Akud n Unebdu n Vanuyatu#,
				'generic' => q#Akud n Vanuyatu#,
				'standard' => q#Akud Amagnu n Vanuyatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Akud n Vinizwila#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Akud n Unebdu n Vladivostok#,
				'generic' => q#Akud n Vladivostok#,
				'standard' => q#Akud Amagnu n Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Akud n Unebdu n Volgograd#,
				'generic' => q#Akud n Volgograd#,
				'standard' => q#Akud Amagnu n Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Akud n Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Akud n Tegzirin n Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Akud n Wallis akked Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Akud n Unebdu n Yakutsk#,
				'generic' => q#Akud n Yakutsk#,
				'standard' => q#Akud Amagnu n Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Akud n Unebdu n Yekaterinburg#,
				'generic' => q#Akud n Yekaterinburg#,
				'standard' => q#Akud Amagnu n Yekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
