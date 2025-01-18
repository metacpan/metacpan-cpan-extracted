=encoding utf8

=head1 NAME

Locale::CLDR::Locales::El::Polyton - Package for language Greek

=cut

package Locale::CLDR::Locales::El::Polyton;
# This file auto generated from Data\common\main\el_POLYTON.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::El');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'Ἀραβικά',
 				'arc' => 'Ἀραμαϊκά',
 				'cy' => 'Οὐαλικά',
 				'egy' => 'Αἰγυπτιακὰ (ἀρχαῖα)',
 				'el' => 'Ἑλληνικά',
 				'en' => 'Ἀγγλικά',
 				'es' => 'Ἱσπανικά',
 				'et' => 'Ἐσθονικά',
 				'ga' => 'Ἰρλανδικά',
 				'gd' => 'Σκωτικὰ κελτικά',
 				'grc' => 'Ἀρχαῖα Ἑλληνικά',
 				'he' => 'Ἑβραϊκά',
 				'hu' => 'Οὑγγρικά',
 				'hy' => 'Ἀρμενικά',
 				'id' => 'Ἰνδονησιακά',
 				'is' => 'Ἰσλανδικά',
 				'it' => 'Ἰταλικά',
 				'ja' => 'Ἰαπωνικά',
 				'mul' => 'Πολλαπλές γλῶσσες',
 				'nl' => 'Ὁλλανδικά',
 				'ota' => 'Τουρκικά, ὀθωμανικὰ',
 				'peo' => 'Ἀρχαῖα περσικὰ',
 				'sq' => 'Ἀλβανικά',
 				'uk' => 'Οὐκρανικά',
 				'yi' => 'Ἰουδαϊκά',

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
			'Arab' => 'Ἀραβικό',
 			'Armn' => 'Ἀρμενικό',
 			'Ethi' => 'Αἰθιοπικό',
 			'Grek' => 'Ἑλληνικό',
 			'Hebr' => 'Ἑβραϊκό',

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
			'AD' => 'Ἀνδόρα',
 			'AE' => 'Ἠνωμένα Ἀραβικὰ Ἐμιράτα',
 			'AF' => 'Ἀφγανιστάν',
 			'AG' => 'Ἀντίγκουα καὶ Μπαρμπούντα',
 			'AI' => 'Ἀνγκουίλα',
 			'AL' => 'Ἀλβανία',
 			'AM' => 'Ἀρμενία',
 			'AO' => 'Ἀνγκόλα',
 			'AQ' => 'Ἀνταρκτική',
 			'AR' => 'Ἀργεντινή',
 			'AS' => 'Ἀμερικανικὴ Σαμόα',
 			'AT' => 'Αὐστρία',
 			'AU' => 'Αὐστραλία',
 			'AW' => 'Ἀρούμπα',
 			'AZ' => 'Ἀζερμπαϊτζάν',
 			'BA' => 'Βοσνία - Ἐρζεγοβίνη',
 			'BM' => 'Βερμοῦδες',
 			'BV' => 'Νῆσος Μπουβέ',
 			'CC' => 'Νῆσοι Κόκος (Κήλινγκ)',
 			'CD' => 'Κονγκό, Λαϊκὴ Δημοκρατία τοῦ',
 			'CF' => 'Κεντροαφρικανικὴ Δημοκρατία',
 			'CH' => 'Ἑλβετία',
 			'CI' => 'Ἀκτὴ Ἐλεφαντοστού',
 			'CI@alt=variant' => 'Ακτή Ελεφαντοστού',
 			'CK' => 'Νῆσοι Κούκ',
 			'CV' => 'Πράσινο Ἀκρωτήριο',
 			'CX' => 'Νῆσος Χριστουγέννων',
 			'DO' => 'Δομινικανὴ Δημοκρατία',
 			'DZ' => 'Ἀλγερία',
 			'EC' => 'Ἰσημερινός',
 			'EE' => 'Ἐσθονία',
 			'EG' => 'Αἴγυπτος',
 			'EH' => 'Δυτικὴ Σαχάρα',
 			'ER' => 'Ἐρυθραία',
 			'ES' => 'Ἱσπανία',
 			'ET' => 'Αἰθιοπία',
 			'EU' => 'Εὐρωπαϊκὴ ᾿Ένωση',
 			'FM' => 'Μικρονησία, Ὁμόσπονδες Πολιτεῖες τῆς',
 			'FO' => 'Νῆσοι Φερόες',
 			'GB' => 'Ἡνωμένο Βασίλειο',
 			'GF' => 'Γαλλικὴ Γουιάνα',
 			'GQ' => 'Ἰσημερινὴ Γουινέα',
 			'GR' => 'Ἑλλάδα',
 			'GS' => 'Νότια Γεωργία καὶ Νότιες Νήσοι Σάντουιτς',
 			'HK' => 'Χὸνγκ Κόνγκ, Εἰδικὴ Διοικητικὴ Περιφέρεια τῆς Κίνας',
 			'HM' => 'Νῆσοι Χὲρντ καὶ Μακντόναλντ',
 			'HN' => 'Ὁνδούρα',
 			'HT' => 'Ἁϊτή',
 			'HU' => 'Οὑγγαρία',
 			'ID' => 'Ἰνδονησία',
 			'IE' => 'Ἰρλανδία',
 			'IL' => 'Ἰσραήλ',
 			'IN' => 'Ἰνδία',
 			'IO' => 'Βρετανικὰ Ἐδάφη Ἰνδικοῦ Ὠκεανοῦ',
 			'IQ' => 'Ἰράκ',
 			'IR' => 'Ἰράν, Ἰσλαμικὴ Δημοκρατία τοῦ',
 			'IS' => 'Ἰσλανδία',
 			'IT' => 'Ἰταλία',
 			'JO' => 'Ἰορδανία',
 			'JP' => 'Ἰαπωνία',
 			'KN' => 'Σαὶντ Κὶτς καὶ Νέβις',
 			'KY' => 'Νῆσοι Κέιμαν',
 			'LA' => 'Λατινικὴ Ἀμερική',
 			'LC' => 'Ἁγία Λουκία',
 			'LK' => 'Σρὶ Λάνκα',
 			'LU' => 'Λουξεμβοῦργο',
 			'MD' => 'Μολδαβία, Δημοκρατία τῆς',
 			'MH' => 'Νῆσοι Μάρσαλ',
 			'ML' => 'Μαλί',
 			'MO' => 'Μακάο, Εἰδικὴ Διοικητικὴ Περιφέρεια τῆς Κίνας',
 			'MP' => 'Νῆσοι Βόρειες Μαριάνες',
 			'NF' => 'Νῆσος Νόρφολκ',
 			'NL' => 'Ὁλλανδία',
 			'OM' => 'Ὀμάν',
 			'PF' => 'Γαλλικὴ Πολυνησία',
 			'PM' => 'Σαὶντ Πιὲρ καὶ Μικελόν',
 			'PS' => 'Παλαιστινιακὰ Ἐδάφη',
 			'SA' => 'Σαουδικὴ Ἀραβία',
 			'SB' => 'Νῆσοι Σολομῶντος',
 			'SH' => 'Ἁγία Ἑλένη',
 			'SJ' => 'Νῆσοι Σβάλμπαρ καὶ Γιὰν Μαγιέν',
 			'SM' => 'Ἅγιος Μαρίνος',
 			'ST' => 'Σάο Τομὲ καὶ Πρίνσιπε',
 			'SV' => 'Ἒλ Σαλβαδόρ',
 			'SY' => 'Συρία, Ἀραβικὴ Δημοκρατία τῆς',
 			'TC' => 'Νῆσοι Τὲρκς καὶ Κάικος',
 			'TD' => 'Τσάντ',
 			'TF' => 'Γαλλικὰ Νότια Ἐδάφη',
 			'TL' => 'Ἀνατολικὸ Τιμόρ',
 			'TT' => 'Τρινιδὰδ καὶ Τομπάγκο',
 			'UA' => 'Οὐκρανία',
 			'UG' => 'Οὐγκάντα',
 			'UM' => 'Ἀπομακρυσμένες Νησίδες τῶν Ἡνωμένων Πολιτειῶν',
 			'US' => 'Ἡνωμένες Πολιτεῖες',
 			'UY' => 'Οὐρουγουάη',
 			'UZ' => 'Οὐζμπεκιστάν',
 			'VA' => 'Ἁγία Ἕδρα (Βατικανό)',
 			'VC' => 'Ἅγιος Βικέντιος καὶ Γρεναδίνες',
 			'VG' => 'Βρετανικὲς Παρθένοι Νῆσοι',
 			'VI' => 'Ἀμερικανικὲς Παρθένοι Νῆσοι',
 			'WF' => 'Νῆσοι Οὐάλλις καὶ Φουτουνά',
 			'YE' => 'Ὑεμένη',
 			'ZA' => 'Νότια Ἀφρική',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Ἡμερολόγιο',

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
 				'buddhist' => q{Βουδιστικὸ ἡμερολόγιο},
 				'chinese' => q{Κινεζικὸ ἡμερολόγιο},
 				'gregorian' => q{Γρηγοριανὸ ἡμερολόγιο},
 				'hebrew' => q{Ἑβραϊκὸ ἡμερολόγιο},
 				'islamic' => q{Ἰσλαμικὸ ἡμερολόγιο},
 				'islamic-civil' => q{Ἰσλαμικὸ ἀστικὸ ἡμερολόγιο},
 				'japanese' => q{Ἰαπωνικὸ ἡμερολόγιο},
 			},
 			'collation' => {
 				'phonebook' => q{Σειρὰ τηλεφωνικοῦ καταλόγου},
 				'pinyin' => q{Σειρὰ Πίνγιν},
 				'stroke' => q{Σειρὰ Stroke},
 			},

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
			main => qr{[αἀἄἂἆἁἅἃἇάὰᾶ β γ δ εἐἔἒἑἕἓέὲ ζ ηἠἤἢἦἡἥἣἧήὴῆ θ ιἰἴἲἶἱἵἳἷίὶῖϊΐῒῗ κ λ μ ν ξ οὄὂὃόὸ π ρ σς τ υὐὔὒὖὑὕὓὗύὺῦϋΰῢῧ φ χ ψ ωὤὢὦὥὣὧώὼῶ]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ναί|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ὄχι|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ADP' => {
			display_name => {
				'currency' => q(Πεσέτα Ἀνδόρας),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Ντιρὰμ Ἡνωμένων Ἀραβικῶν Ἐμιράτων),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Λὲκ Ἀλβανίας),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Ἀρμενίας),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Γκίλντα Ὁλλανδικῶν Ἀντιλλῶν),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Ἀνγκόλας),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kwanza Ἀνγκόλας \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Νέα Kwanza Ἀνγκόλας \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza Reajustado Ἀνγκόλας \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral Ἀργεντινῆς),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Πέσο Ἀργεντινῆς \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Πέσο Ἀργεντινῆς),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Σελίνι Αὐστρίας),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Δολάριο Αὐστραλίας),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Γκίλντα Ἀρούμπα),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Μανὰτ Ἀζερμπαϊτζάν),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Δηνάριο Βοσνίας-Ἑρζεγοβίνης),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Μάρκο Βοσνίας-Ἑρζεγοβίνης),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Φράγκο Βελγίου \(οἰκονομικό\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Μεταλλικὸ Λὲβ Βουλγαρίας),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Νέο Λὲβ Βουλγαρίας),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Δολάριο Καναδᾶ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Φράγκο Ἑλβετίας),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Unidades de Fomento Χιλῆς),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Πέσο Χιλῆς),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Σκληρὴ Κορόνα Τσεχοσλοβακίας),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Ἐσκούδο Πράσινου Ἀκρωτηρίου),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Ostmark Ἀνατολικῆς Γερμανίας),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Δηνάριο Ἀλγερίας),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre Ἰσημερινοῦ),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Unidad de Valor Constante \(UVC\) Ἰσημερινοῦ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Κορόνα Ἐστονίας),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Λίρα Αἰγύπτου),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Ἐρυθραίας),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Πεσέτα Ἱσπανίας),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Αἰθιοπίας),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Εὐρώ),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Λίρα Νήσων Φώλκλαντ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Γκάμπιας),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele Guineana Ἰσημερινῆς Γουινέας),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Γουατεμάλας),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Γκινέα Ἐσκούδο Πορτογαλίας),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Δολάριο Χὸνγκ Κόνγκ),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Ἁϊτῆς),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Φιορίνι Οὑγγαρίας),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Ρούπια Ἰνδονησίας),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Λίρα Ἰρλανδίας),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Λίρα Ἰσραήλ),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Νέο Sheqel Ἰσραήλ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Ρούπια Ἰνδίας),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Δηνάριο Ἰράκ),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Ἰράκ),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Κορόνα Ἰσλανδίας),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Λιρέτα Ἰταλίας),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Δηνάριο Ἰορδανίας),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Γιὲν Ἰαπωνίας),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Ρούπια Σρὶ Λάνκας),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Μακάου),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Πέσο Μεξικοῦ),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Ἀσημένιο Πέσο Μεξικοῦ \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Unidad de Inversion \(UDI\) Μεξικοῦ),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Ἐσκούδο Μοζαμβίκης),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Χρυσὴ Κόρδοβα Νικαράγουας),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Γκίλντα Ὁλλανδίας),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Μπαλμπόα Παναμᾶ),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Παπούα Νέα Γουινέας),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Ἐσκούδο Πορτογαλίας),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Γκουαρανὶ Παραγουάης),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Δολάριο Νήσων Σολομῶντος),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Ρούπια Σεϋχελῶν),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Λίρα Ἀγίας Ἑλένης),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Σοβιετικὸ Ρούβλι),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colon Ἒλ Σαλβαδόρ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Ζουαζιλάνδης),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Μπὰτ Ταϊλάνδης),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Μανὰτ Τουρκμενιστάν),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Ἐσκούδο Τιμόρ),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Δολάριο Τρινιδὰδ καὶ Τομπάγκο),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Οὐκρανίας),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Karbovanetz Οὐκρανίας),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Σελίνι Οὐγκάντας \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Σελίνι Οὐγκάντας),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Δολάριο ΗΠΑ \(Ἑπόμενη ἡμέρα\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Δολάριο ΗΠΑ \(Ἴδια ἡμέρα\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Πέσο Οὐρουγουάης \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Πέσο Uruguayo Οὐρουγουάης),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sum Οὐζμπεκιστάν),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Μπολιβὰλ Βενεζουέλας),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Δυτικῆς Σαμόας),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Εὐρωπαϊκὴ Σύνθετη Μονάδα),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Εὐρωπαϊκὴ Νομισματικὴ Μονάδα),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Εὐρωπαϊκὴ Μονάδα Λογαριασμοῦ \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Εὐρωπαϊκὴ Μονάδα Λογαριασμοῦ \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Δολάριο Ἀνατολικῆς Καραϊβικῆς),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Εἰδικὰ Δικαιώματα Ἀνάληψης),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Εὐρωπαϊκὴ Συναλλαγματικὴ Μονάδα),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Χρυσὸ Φράγκο Γαλλίας),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Δηνάριο Ὑεμένης),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Ὑεμένης),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Μεταλλικὸ Δηνάριο Γιουγκοσλαβίας),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Ραντ Νότιας Ἀφρικῆς \(οἰκονομικό\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ρὰντ Νότιας Ἀφρικῆς),
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
							'Ιαν',
							'Φεβ',
							'Μαρ',
							'Απρ',
							'Μαΐ',
							'Ιουν',
							'Ιουλ',
							'Αὐγ',
							'Σεπ',
							'Ὀκτ',
							'Νοε',
							'Δεκ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ιανουαρίου',
							'Φεβρουαρίου',
							'Μαρτίου',
							'Απριλίου',
							'Μαΐου',
							'Ιουνίου',
							'Ιουλίου',
							'Αὐγούστου',
							'Σεπτεμβρίου',
							'Ὀκτωβρίου',
							'Νοεμβρίου',
							'Δεκεμβρίου'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Ιανουάριος',
							'Φεβρουάριος',
							'Μάρτιος',
							'Απρίλιος',
							'Μάιος',
							'Ιούνιος',
							'Ιούλιος',
							'Αὔγουστος',
							'Σεπτέμβριος',
							'Ὀκτώβριος',
							'Νοέμβριος',
							'Δεκέμβριος'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

no Moo;

1;

# vim: tabstop=4
