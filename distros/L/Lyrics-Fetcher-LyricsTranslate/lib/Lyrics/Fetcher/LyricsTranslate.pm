package Lyrics::Fetcher::LyricsTranslate;

use 5.014000;
use strict;
use warnings;

use HTML::TreeBuilder;
use HTTP::Tiny;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.002001';
our $BASE_URL = 'http://lyricstranslate.com';
# 0 means (from) any language; the following arguments are the
# destination language, artist, and title. The meaning of the last
# parameter is unknown.
our $URL_FORMAT = "$BASE_URL/en/translations/0/%s/%s/%s/none";

my $ht = HTTP::Tiny->new(agent => "Lyrics-Fetcher-LyricsTranslate/$VERSION ");

our %LANGUAGES; # Filled at the end of the file

sub fetch {
	my ($self, $artist, $song, $language) = @_;
	$language //= 'English';
	$language = $LANGUAGES{$language} unless looks_like_number $language;
	$Lyrics::Fetcher::Error = 'OK';
	my $url = sprintf $URL_FORMAT, $language, $artist, $song;
	my $response = $ht->get($url);
	unless ($response->{success}) {
		$Lyrics::Fetcher::Error = 'Search request failed: ' . $response->{reason};
		return
	}
	my $tree = HTML::TreeBuilder->new_from_content($response->{content});
	# First result would be the link to the artist, so we get the second one
	my (undef, $result) = $tree->look_down(class => 'ltsearch-translatenameoriginal');
	unless ($result) {
		$Lyrics::Fetcher::Error = 'Lyrics not found';
	}
	$response = $ht->get($BASE_URL . $result->find('a')->attr('href'));
	unless ($response->{success}) {
		$Lyrics::Fetcher::Error = 'Lyrics request failed: ' . $response->{reason};
		return
	}
	$tree = HTML::TreeBuilder->new_from_content($response->{content});
	my $node = $tree->look_down(class => qr/(?<!\S)translate-node-text(?!\S)/);
	my $ltf = $node->look_down(class => qr/\bltf\b/);
	my @pars = $ltf->look_down(class => 'par');
	join "\n", map {
		join '', map { $_->as_trimmed_text . "\n" } $_->content_list
	} @pars
}

%LANGUAGES = (
	'Albanian' => 319,
	'Arabic' => 12,
	'Azerbaijani' => 433,
	'Belarusian' => 317,
	'Bosnian' => 318,
	'Bulgarian' => 14,
	'Catalan' => 342,
	'Chinese' => 15,
	'Croatian' => 16,
	'Czech' => 17,
	'Danish' => 18,
	'Dutch' => 19,
	'English' => 328,
	'Estonian' => 326,
	'Filipino/Tagalog' => 373,
	'Finnish' => 21,
	'French' => 22,
	'German' => 23,
	'Greek' => 24,
	'Hebrew' => 26,
	'Hindi' => 27,
	'Hungarian' => 28,
	'Indonesian' => 29,
	'Italian' => 30,
	'Japanese' => 31,
	'Kazakh' => 374,
	'Korean' => 32,
	'Latin' => 33,
	'Latvian' => 325,
	'Lithuanian' => 324,
	'Macedonian' => 314,
	'Malay' => 444,
	'Norwegian' => 36,
	'Other' => 1025951,
	'Persian' => 322,
	'Polish' => 37,
	'Portuguese' => 38,
	'Romanian' => 312,
	'Russian' => 40,
	'Serbian' => 41,
	'Slovak' => 315,
	'Spanish' => 42,
	'Swedish' => 43,
	'Tongan' => 801,
	'Transliteration' => 718,
	'Turkish' => 313,
	'Ukrainian' => 48,
	'Unknown' => 376,
	'Uzbek' => 323,
	'Adunaic' => 1000213,,
	'Afrikaans' => 440,
	'Ainu' => 1035920,
	'Aklan' => 1019908,
	'Al Bhed' => 1000269,
	'Altai' => 1025586,
	'American Sign Language' => 1000218,
	'Amharic' => 705,
	'Amis' => 1032629,
	'Angolar Creole' => 1034642,
	'Aragonese' => 1032780,
	'Aramaic (Modern Syriac Dialects)' => 1025338,
	'Aramaic (Syriac Classical)' => 1025337,
	'Armenian' => 321,
	'Armenian (Homshetsi dialect)' => 1025608,
	'Assamese' => 803,
	'Asturian' => 1000136,
	'Avar' => 1030975,
	'Aymara' => 1025801,
	'Baeggu' => 1000129,
	'Bagobo' => 1021656,
	'Bambara' => 445,
	'Bashkir' => 632,
	'Basque' => 624,
	'Bengali' => 13,
	'Berber' => 802,
	'Bikol' => 1000248,
	'Black Speech' => 1000212,
	'Blackfoot' => 1028055,
	'Breton (Brezhoneg)' => 608,
	'Burmese' => 1020572,
	'Butuanon' => 1019909,
	'Cantabrian' => 1034733,
	'Cape Verdean' => 808,
	'Castithan' => 1022982,
	'Catalan (Medieval)' => 1033121,
	'Cebuano' => 1000245,
	'Chamorro' => 784,
	'Chavacano' => 1000278,
	'Chechen' => 1021776,
	'Cherokee' => 1029750,
	'Chewa' => 819,
	'Chinese (Hakka)' => 1032630 ,
	'Chuvash' => 1027857,
	'Circassian' => 1030979,
	'Common' => 1000187,
	'Comorian' => 1000199,
	'Cornish' => 1030748,
	'Corsican' => 814,
	'Crimean Tatar' => 827,
	'Croatian (Chakavian dialect)' => 1000152,
	'Croatian (Kajkavian dialect)' => 1022139,
	'Dari' => 1000072,
	'Arabic (other varieties)' => 1000186,
	'Darnassian' => 1000188,
	'Dholuo' => 1021614,
	'Dogon' => 1022611,
	'Dothraki' => 1000228,
	'Dragon' => 1000205,
	'Dutch (Middle Dutch)' => 1022075,
	'Dutch (Old Dutch)' => 1028105,
	'Dutch dialects' => 434,
	'Dzongkha' => 1000197,
	'Egyptian (Old Egyptian/Coptic)' => 1028479,
	'Emilian-Romagnol' => 1000240,
	'English (Jamaican)' => 1023750,
	'English (Middle English)' => 1020671,
	'English (Old English)' => 1000210,
	'English (Scots)' => 521,
	'English Creole (Tok Pisin)' => 1029190,
	'Esperanto' => 413,
	'Estonian (South)' => 1022579,
	'Extremaduran' => 1034916,
	'Faroese' => 437,
	'Fijian' => 1000267,
	'Finnish (Savo)' => 436,
	'Fon' => 1000140,
	'Fremen' => 1000190,
	'French (Antillean Creole)' => 1037027,
	'French (Haitian Creole)' => 570,
	'French (Indian French)' => 1028744,
	'French (Louisiana Creole French)' => 1023092,
	'French (Middle French)' => 1028104,
	'French (Old French)' => 1020670,
	'French (Réunion Creole)' => 1033982,
	'Frisian' => 439,
	'Friulian' => 818,
	'Gaelic (Irish Gaelic)' => 607,
	'Gaelic (Scottish Gaelic)' => 597,
	'Gagauz' => 1000133,
	'Galician' => 438,
	'Galician-Portuguese' => 1000238,
	'Garifuna' => 1033983,
	'Gaulish' => 860,
	'Genoese' => 1000272,
	'Georgian' => 414,
	'German (Austrian/Bavarian)' => 658,
	'German (Berlinerisch dialect)' => 1031655,
	'German (central dialects)' => 1000195,
	'German (Kölsch)' => 1033301,
	'German (Low German)' => 1000131,
	'German (Middle High German)' => 824,
	'German (Old High German)' => 825,
	'German (Swiss-German/Allemanic)' => 631,
	'Gilbertese' => 1000202,
	'Goranian' => 1037077,
	'Gothic' => 855,
	'Greek (classical)' => 823,
	'Greek (Cypriot)' => 1032770,
	'Greek (Pontic)' => 1000172,
	'Greenlandic' => 1029356,
	'Griko' => 1000144,
	'Guaraní' => 1031493,
	'Gujarati' => 25,
	'Hausa' => 1033388,
	'Hawaiian' => 375,
	'High Valyrian' => 1022167,
	'Hiligaynon' => 1000247,
	'Hmong' => 813,
	'Hungarian (Old Hungarian)' => 1033943,
	'Icelandic' => 332,
	'Ilokano' => 1000246,
	'Indigenous Languages (Mexico)' => 1037074,
	'Ingush' => 1029233,
	'Interlingua' => 1037062,
	'Inuktitut ' => 1035431,
	'IPA' => 1000173,
	'Iranian (Balochi)' => 1025775,
	'Iranian (Gilaki)' => 1033120,
	'Iranian (Luri)' => 1037061,
	'Istriot' => 1000239,
	'Italian (Medieval)' => 1024385,
	'Kabyle' => 501,
	'Kalmyk' => 1034135,
	'Kannada' => 1025336,
	'Kapampangan' => 1019910,
	'Karachay-Balkar' => 1024275,
	'Karakalpak' => 1020990,
	'Karelian' => 1020968,
	'Kariña' => 1037071,
	'Kashubian' => 1025888,
	'Khmer' => 415,
	'Khuzdul' => 1000214,
	'Kinaray-a' => 1019911,
	'Kinyarwanda' => 1021709,
	'Kirundi' => 1000198,
	'Klingon' => 1000220,
	'Kongo' => 1022612,
	'Kriol (Guinea Bissau)' => 1033054,
	'Kumyk' => 1034264,
	'Kurdish (Kurmanji)' => 327,
	'Kurdish (Sorani)' => 1024274,
	'Kurdish dialects' => 1022466,
	'Kyrgyz' => 702,
	'Ladin (Rhaeto-Romance)' => 1032848,
	'Ladino (Judeo-Spanish)' => 1023993,
	'Lao' => 596,
	'Latvian (Latgalian)' => 1033068,
	'Laz' => 1000204,
	'Lingala' => 1028743,
	'Livonian' => 1025670,
	'Lombard' => 1035433,
	'Loxian' => 1000141,
	'Luganda' => 1000268,
	'Luxembourgish' => 785,
	'Malagasy' => 1033944,
	'Malayalam' => 34,
	'Maldivian (dhivehi)' => 1021237,
	'Maltese' => 1000067,
	'Manobo' => 1019912,
	'Manx Gaelic' => 1000071,
	'Maori' => 659,
	'Mapudungun' => 1035835,
	'Marathi' => 35,
	'Mari' => 1027765,
	'Minangkabau' => 1022890,
	'Mixtec' => 1037064,
	'Mohawk' => 1021100,
	'Mongolian' => 614,
	'Mongolian (Buryat dialect)' => 1037067,
	'Montenegrin' => 657,
	'Nahuatl' => 1000226,
	'Navajo' => 1019915,
	'Neapolitan' => 637,
	'Nepali' => 442,
	'Niuean' => 1000281,
	'Nogai' => 1021238,
	'Norwegian (Dano-Norwegian)' => 1020252,
	'Norwegian (Sognamål)' => 1025146,
	'Occitan' => 1000068,
	'Old Church Slavonic' => 1000135,
	'Old East Slavic' => 1024273,
	'Old Norse/Norrønt' => 826,
	'Old Prussian' => 1026171,
	'Ossetic' => 1000139,
	'Otomi' => 1037065,
	'Pali' => 1036467,
	'Pangasinan' => 1000249,
	'Papiamento' => 1000209,
	'Pashto' => 1000066,
	'Paumotuan' => 1024518,
	'Piedmontese' => 1036374,
	'Polish (Poznan dialect)' => 1031836,
	'Pseudo-Latin' => 1000279,
	'Punjabi' => 39,
	'Quechua' => 1000142,
	'Quenya' => 1000211,
	'Quichua (Kichwa)' => 1031957,
	'Rapa Nui' => 1000145,
	'Rarotongan' => 1000273,
	'Roman dialect' => 1035163,
	'Romani' => 757,
	'Romanian (Aromanian)' => 810,
	'Romansh' => 1000130,
	'Romeyika/Rumka' => 1032709,
	'Sakha' => 1020991,
	'Salar' => 1033242,
	'Salentine' => 1035162,
	'Sami' => 1000191,
	'Samoan' => 660,
	'Sanskrit' => 1000138,
	'Sardinian' => 698,
	'Sardo-corsican' => 1029194,
	'Sicilian' => 1000225,
	'Sindarin' => 1000184,
	'Sinhala' => 756,
	'Slovene' => 316,
	'Somali' => 1000069,
	'Sotho' => 1033981,
	'Spanish (Old Castillian)' => 1035797,
	'Sranan Tongo' => 1022039,
	'Sumerian' => 1026172,
	'Sundanese' => 1035432,
	'Surzhyk ' => 1020339,
	'Swahili' => 595,
	'Swedish (dialects)' => 1037078,
	'Swedish (Old Swedish)' => 1033302,
	'Tagalog (dialects)' => 44,
	'Tahitian' => 1000227,
	'Taíno' => 1024755,
	'Taiwanese' => 783,
	'Tajik' => 720,
	'Tamashek-Berber/Tuareg' => 791,
	'Tamil' => 45,
	'Tatar' => 630,
	'Tausūg' => 1019913,
	'Telugu' => 46,
	'Tetum' => 1028389,
	'Thai' => 47,
	'Thalassian' => 1000189,
	'Tibetan' => 1000143,
	'Tigrinya' => 1000201,
	'Tokelauan' => 1000185,
	'Tongan (Old Tongan)' => 1022633,
	'Torlakian dialect' => 1000230,
	'Totonac' => 1037076,
	'Tswana' => 524,
	'Turkish (Anatolian dialects)' => 1021735,
	'Turkish (Middle Turkic)' => 1032996,
	'Turkish (Ottoman)' => 1019916,
	'Turkmen' => 703,
	'Tuvaluan' => 1000203,
	'Tuvan' => 1021332,
	'Tzotzil' => 1031492,
	'Udmurt' => 804,
	'Upper Sorbian' => 1022610,
	'Urdu' => 49,
	'Uvean' => 1000274,
	'Uyghur' => 704,
	'Uzbek dialects' => 1025822,
	'Venetian' => 1033821,
	'Veps' => 1021708,
	'Vietnamese' => 50,
	'Walloon ' => 886,
	'Waray-Waray' => 1019914,
	'Welsh' => 525,
	'Wolof' => 1037072,
	'Xhosa' => 1000070,
	'Yiddish' => 822,
	'Yolŋu Matha' => 817,
	'Yoruba' => 671,
	'Yupik' => 1029797,
	'Zapotec' => 1000196,
	'Zazaki' => 761,
	'Zulu' => 1000280,
);

1;
__END__

=encoding utf-8

=head1 NAME

Lyrics::Fetcher::LyricsTranslate - Get lyrics from lyricstranslate.com

=head1 SYNOPSIS

  # This module should be used directly
  use Lyrics::Fetcher::LyricsTranslate;
  print Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat');
  # Equivalent to
  print Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat', 'English');
  # Equivalent to
  print Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat', 328);


  print $Lyrics::Fetcher::LyricsTranslate::LANGUAGES{English}; # prints 328


  # Can also be used via Lyrics::Fetcher but produces ugly output and
  # does not support a custom target language
  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch('Lyube', 'Kombat', 'LyricsTranslate');

=head1 DESCRIPTION

This module tries to get translated lyrics from
L<http://lyricstranslate.com>. It searches for a translation of the
given artist and song title from any language to a requested language
(which defaults to English), and returns the contents of the first
result found.

It is recommended to use the module directly, as using it via
L<Lyrics::Fetcher> loses empty lines between parahraphs.

The target language can be specified as either a number or a string.
If a string is given, it is looked up in the hash
C<%Lyrics::Fetcher::LyricsTranslate::LANGUAGES> which maps language
names to their numerical identifiers. The hash was generated from the
website, and it might be outdated.

The target language is passed as the third argument to the B<fetch>
method. If using the module via L<Lyrics::Fetcher>, the target
language cannot be set and defaults to English.

=head1 SEE ALSO

L<Lyrics::Fetcher>, L<http://lyricstranslate.com>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
