use Test::More tests => 10;
BEGIN { use_ok('HTML::HTML5::Sanity') };

ok(
	HTML::HTML5::Sanity::_valid_lang('EN-LATN-GB'),
	'Simple language validity check.',
	);

ok(
	HTML::HTML5::Sanity::_valid_lang('en-latn-gb-x-tobyink'),
	'More complex language validity check.',
	);

ok(
	!HTML::HTML5::Sanity::_valid_lang('en-tobyinkster'),
	'Language validity function fails invalid languages',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('EN-LATN-GB'),
	'en-Latn-GB',
	'Case handling of languages is good.',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('eng'),
	'en',
	'Correction of 3 character codes to 2 character codes works.',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('en-uk'),
	'en-GB',
	'Obsolete/special country codes are corrected.',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('en-826'),
	'en-GB',
	'Numeric country codes are swapped.',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('es-419'),
	'es-419',
	'Numeric country codes are not swapped when they can\'t be.',
	);

is(
	HTML::HTML5::Sanity::_canon_lang('i-klingon'),
	'tlh',
	'Grandfathered tags are replaced with preferred tags.',
	);
