package Lingua::RU::Detect;

use vars qw ($VERSION);
$VERSION = '1.1';

use strict;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(detect_enc);

my %patterns = (
	'-|'.
		'UTF-8.KOI8-R,CP1251.KOI8-R,CP1251.UTF-8',	'\b(?:[А-Я][а-х]+|[а-я]{3,})\b',

	'UTF-8.CP1251,KOI8-R.UTF-8|'.
		'UTF-8.KOI8-R,CP1251.UTF-8',		'\b(?:[а-я][А-Я]+|[А-Я]{3,})\b',

	'UTF-8.ISO-8859-5,KOI8-R.UTF-8|'.
		'UTF-8.KOI8-R,ISO-8859-5.UTF-8|'.
		'UTF-8.CP1251,ISO-8859-5.UTF-8',	'[а-я]+[А-Я]+[а-я]+|[А-Я]+[а-я]+[А-Я]+',

	'UTF-8.ISO-8859-5,CP1251.UTF-8|'.
		'UTF-8.CP866,CP1251.UTF-8',			'[а-яёїџђѓќў]+[√ЄЁЎЇ№]{1,2}[а-яџђѓќўёї]+\b',

	'UTF-7.UTF-8',							'(?:^|\s)\+B[B-F][0-9a-zA-Z]+',
	'UTF-7.CP866',							'(?:^|\s)\+JWg[a-zA-Z]+',
	'UTF-8.ISO-8859-1,UTF-7.ISO-8859-1',	'(?:^|\s)\+AN[a-zA-Z]+',

	'UTF-8.CP1251,KOI8-R.CP866',			'є.¶|¶.¶',
	'UTF-8.CP1252,KOI8-R.CP866',			'º.º|¶.º',
	'UTF-8.CP1251,UTF-8.CP866',				'в•Ё|•›в•',
	'UTF-8.KOI8-R,UTF-8.CP866',				'Б∙╗|Б∙.Б∙.',
	'UTF-8.ISO-8859-1',						'Ðº|Ð¿Ð',
	'UTF-8.CP1251,UTF-8.ISO-8859-1',		'ГђВ|°Г‘',
	'UTF-8.KOI8-R,UTF-8.ISO-8859-1',		'ц░б',
	'UTF-8.CP1251,UTF-8.UTF-16',			'н‚.н‚|н†.н†',
	'UTF-8.KOI8-R,UTF-8.UTF-16',			'╬М|╪М|╣М|╫М',
	'UTF-8.CP1251,CP866.UTF-8',				'®.+Ґ|«Ё|®¤­®|«Ґ',
	'UTF-8.CP1251,UTF-8.KOI8-R',			'Рїв|СЏ',

	'UTF-8.ISO-8859-1,ISO-8859-5.UTF-8',	'[ýëåêòðèôèêàöèÿãóáåðíèé]+[ÝËÅÊÒÐÈÔÈÊÀÖÈŸÃÓÁÅÐÍÈÉ]+[ýëåêòðèôèêàöèÿãóáåðíèé]+|[ÝËÅÊÒÐÈÔÈÊÀÖÈŸÃÓÁÅÐÍÈÉ]+[ýëåêòðèôèêàöèÿãóáåðíèé]+[ÝËÅÊÒÐÈÔÈÊÀÖÈŸÃÓÁÅÐÍÈÉ]+',
	'UTF-8.CP1252,CP1251.UTF-8',			'[ýëåêòðèôèêàöèÿãóáåðíèé]{3,}',
	'UTF-8.CP1252,KOI8-R.UTF-8',			'[ÀÏÎËÜÇÎÂÀÍÈÅÑ]{2,}',

	'UTF-8.CP866,KOI8-R.UTF-8',				'[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]{4,}',
	'UTF-8.KOI8-R,CP866.UTF-8',				'[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+[А-Я]+[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+[А-Я]+[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+',
	'UTF-8.CP866,ISO-8859-5.UTF-8',			'[а-ор-я]+[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+[а-ор-я]+[╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+',
	'UTF-8.KOI8-R',							'[пя][╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩][пя]|п.я',
	'UTF-8.CP866',							'[▒▓╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+[А-Я][▒▓╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+[А-Я][▒▓╟╧╫╣║╔╙═╔╥╧╦┴╤╠┼╦╘╥╔╞╔╦┴├╔╤└╓╬┘╚ ╟╒┬┼╥╬╔╩]+',
);

my %ambiguities = (
	'-'		=> 'на|ст|ни|но|ан|ов|ко|то|ен|ле|ел|ра|ре|ис|по|ом|ро|ет|ва|та|ос|те|де|ль|ер|он|ть|за|ск|от|ли|ат|ол|об|ар|од|ие|го|пр|ри|мо|ам|сл|тр|не|ор|ла|ал|ит',
	'UTF-8.KOI8-R,CP1251.KOI8-R,CP1251.UTF-8'		=> 'лч|ъп|лу|лм|чл|ма|им|пм|ел|йе|ей|оч|ое|уъ|нм|мк|ом|еп|ач|пч|мъ|пе|де|йщ|ео|мл|пщ|цч|ъи|мп|йу|чп|мй|мю|чо|мд|уе|жм|но|оу|км|чк|ъй|по|ле|мо|йч|чй|уп',
	
	'UTF-8.CP1251,KOI8-R.UTF-8'		=> 'ОБ|УФ|ОЙ|ОП|БО|ПЧ|ЛП|ФП|ЕО|МЕ|ЕМ|ТБ|ТЕ|ЙУ|РП|ПН|ТП|ЕФ|ЧБ|ФБ|ПУ|ФЕ|ДЕ|МШ|ЕТ|ПО|ФШ|ЪБ|УЛ|ПФ|МЙ|БФ|ПМ|ПВ|БТ|ПД|ЙЕ|ЗП|РТ|ТЙ|НП|БН|УМ|ФТ|ОЕ|ПТ|МБ|БМ|ЙФ',
	'UTF-8.KOI8-R,CP1251.UTF-8'		=> 'МЮ|ЯР|МХ|МН|ЮМ|НБ|ЙН|РН|ЕМ|КЕ|ЕК|ПЮ|ПЕ|ХЯ|ОН|НЛ|ПН|ЕР|БЮ|РЮ|НЯ|РЕ|ДЕ|КЭ|ЕП|НМ|РЭ|ГЮ|ЯЙ|НР|КХ|ЮР|НК|НА|ЮП|НД|ХЕ|ЦН|ОП|ПХ|ЛН|ЮЛ|ЯК|РП|МЕ|НП|КЮ|ЮК|ХР',
	
	'UTF-8.ISO-8859-5,KOI8-R.UTF-8' => 'ЮС|гд|ЮЩ|ЮЯ|СЮ|Яз|ЫЯ|дЯ|ХЮ|ЬХ|ХЬ|вС|вХ|Щг|аЯ|ЯЭ|вЯ|Хд|зС|дС|Яг|дХ|ФХ|Ьи|Хв|ЯЮ|ди|кС|гЫ|Яд|ЬЩ|Сд|ЯЬ|ЯТ|Св|ЯФ|ЩХ|ЧЯ|ав|вЩ|ЭЯ|СЭ|гЬ|дв|ЮХ|Яв|ЬС|СЬ|Щд',
	'UTF-8.KOI8-R,ISO-8859-5.UTF-8' => 'щп|АБ|щь|щч|пщ|чр|зч|Бч|ущ|шу|уш|Юп|Юу|ьА|ъч|чэ|Юч|уБ|рп|Бп|чА|Бу|ту|шЛ|уЮ|чщ|БЛ|вп|Аз|чБ|шь|пБ|чш|чя|пЮ|чт|ьу|сч|ъЮ|Юь|эч|пэ|Аш|БЮ|щу|чЮ|шп|пш|ьБ',
	'UTF-8.CP1251,ISO-8859-5.UTF-8' => 'ЭР|бв|ЭШ|ЭЮ|РЭ|ЮТ|ЪЮ|вЮ|ХЭ|ЫХ|ХЫ|аР|аХ|Шб|ЯЮ|ЮЬ|аЮ|Хв|ТР|вР|Юб|вХ|ФХ|Ым|Ха|ЮЭ|вм|ЧР|бЪ|Юв|ЫШ|Рв|ЮЫ|ЮС|Ра|ЮФ|ШХ|УЮ|Яа|аШ|ЬЮ|РЬ|бЫ|ва|ЭХ|Юа|ЫР|РЫ|Шв',

	'UTF-8.ISO-8859-5,CP1251.UTF-8' => 'эр|ёђ|эш|эю|рэ|ют|ъю|ђю|хэ|ых|хы|№р|№х|шё|яю|юь|№ю|хђ|тр|ђр|юё|ђх|фх|ыќ|х№|юэ|ђќ|чр|ёъ|юђ|ыш|рђ|юы|юс|р№|юф|шх|ую|я№|№ш|ью|рь|ёы|ђ№|эх|ю№|ыр|ры|шђ',
	'UTF-8.CP866,CP1251.UTF-8'		=> 'эр|ёЄ|эш|эю|рэ|ют|ъю|Єю|хэ|ых|хы|Ёр|Ёх|шё|яю|юь|Ёю|хЄ|тр|Єр|юё|Єх|фх|ы№|хЁ|юэ|Є№|чр|ёъ|юЄ|ыш|рЄ|юы|юс|рЁ|юф|шх|ую|яЁ|Ёш|ью|рь|ёы|ЄЁ|эх|юЁ|ыр|ры|шЄ',
);

sub detect_enc {
	my $string = shift;

	my %variants = ();
	for my $path (sort keys %patterns) {
		$variants{$path} = () = $string =~ /$patterns{$path}/g;
	}

	my $path = scalar keys %variants ? (sort {$variants{$a} <=> $variants{$b}} keys %variants)[-1] : '';

	$path = remove_ambiguity($path, $string) if $path =~ m{\|};
	
	return make_list($path);
}

sub remove_ambiguity {
	my $paths = shift;
	my $text = shift;

	my @paths = split m{\|}, $paths;
	my %stats = ();
	for my $path (@paths) {
		$stats{$path} = () = $text =~ /$ambiguities{$path}/g;
	}

	return scalar keys %stats ? (sort {$stats{$a} <=> $stats{$b}} keys %stats)[-1] : $paths[0];
}

sub make_list {
	my $path = shift;

	my @ret;

	for my $pair (split /,/, $path) {
		my ($from, $to) = split /\./, $pair;
		push @ret, [$from, $to] unless $from eq '-';
	}

	return @ret;
}

1;

__END__

=encoding utf-8

=head1 NAME

Lingua::RU::Detect - Heuristics for guessing encoding sequence

=head1 SYNOPSIS

	use Lingua::RU::Detect "detect_enc";
	say Dumper(detect_enc("бНОПНЯ")); 
	say Dumper(detect_enc("бОДТЕК"));


=head1 ABSTRACT

Lingua::RU::Detect make a guess of how the original text was reconverted with a sequence of different encodings.

=head1 DESCRIPTION

This module is a heart of http://decodr.ru/ website which provides a tool for automatic recovering Russian texts which were damaged by multiple transcodings. Two and three item chains are now available to detect, and the speed is much higher than that of programmes based on a dictionary.

The result of calling C<detect_enc> subroutine is a list of encoding pairs. To get original UTF-8 string you need to make all these transcodings in the order specified in the array returned. For example:

	$VAR1 = [
		[
			'UTF-8',
			'ISO-8859-5'
		],
		[
			'KOI8-R',
			'UTF-8'
		]
	];

If no reencoding is needed, result is an empty array.

For test suite refer to Wikipedia page
http://ru.wikipedia.org/wiki/%D0%9A%D1%80%D0%BE%D0%BA%D0%BE%D0%B7%D1%8F%D0%B1%D1%80%D1%8B
(not all of them pass current version).

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

Lingua::RU::Detect module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl 5.10.

=cut
