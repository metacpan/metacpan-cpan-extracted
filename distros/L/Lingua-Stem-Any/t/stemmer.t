use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 180;
use Lingua::Stem::Any;

my ($stemmer, @words, @words_copy);

$stemmer = new_ok 'Lingua::Stem::Any', [language => 'cs'];

can_ok $stemmer, qw( stem language languages source );

is $stemmer->language, 'cs', 'language read-accessor';

my @langs = sort qw(
    bg cs da de en eo es fa fi fr gl hu io it la nl no pl pt ro ru sv tr
);
my $langs = @langs;
is_deeply [$stemmer->languages], \@langs, 'list languages';
is scalar $stemmer->languages,    $langs, 'scalar languages';

for my $lang (@langs) {
    $stemmer->language($lang);
    is $stemmer->language, $lang, "change language to $lang";
}

is_deeply [$stemmer->languages('Lingua::Stem::Snowball')], [qw(
    da de en es fi fr hu it la nl no pt ro ru sv tr
)], 'list languages for source';

my @sources = qw(
    Lingua::Stem::Snowball
    Lingua::Stem::UniNE
    Lingua::Stem
    Lingua::Stem::Patch
);
my $sources = @sources;
is_deeply [$stemmer->sources], \@sources, 'list sources';
is scalar $stemmer->sources,    $sources, 'scalar sources';
is_deeply [$stemmer->sources('en')], [qw(
    Lingua::Stem::Snowball Lingua::Stem
)], 'list sources for language';

@words = @words_copy = qw( že dobře ještě );
$stemmer->language('cs');
is_deeply [$stemmer->stem(@words)], [qw( že dobř jesk )], 'list of words';
is_deeply \@words, \@words_copy, 'not destructive on arrays';

$stemmer->stem_in_place(\@words);
is_deeply \@words, [qw( že dobř jesk )], 'arrayref modified in place';

is_deeply scalar $stemmer->stem(@words), 'jesk', 'list of words in scalar';

is_deeply [$stemmer->stem('prosím')], ['pro'], 'word in list context';
is_deeply [$stemmer->stem()],         [],      'empty list in list context';
is scalar $stemmer->stem('prosím'),   'pro',   'word in scalar context';
is scalar $stemmer->stem(),           undef,   'empty list in scalar context';

SKIP: {
    skip 'aggressive attribute NYI', 4;

    ok !$stemmer->aggressive,               'light stemmer by default';
    is $stemmer->stem('všechno'), 'všechn', 'light stemmer';
    $stemmer->aggressive(1);
    ok $stemmer->aggressive,                'aggressive stemmer explicitly set';
    is $stemmer->stem('všechno'), 'všech',  'aggressive stemmer';
}

is $stemmer->stem('работа'), 'работа', 'only stem for current language';

$stemmer->language('bg');
is $stemmer->language,       'bg',  'language changed via write-accessor';
is $stemmer->stem('работа'), 'раб', 'language change confirmed by stemming';

$stemmer->language('CS');
is $stemmer->language,       'cs',  'language coerced via write-accessor';
is $stemmer->stem('prosím'), 'pro', 'language coersion confirmed by stemming';

eval { $stemmer->language('xx') };
like $@, qr/Invalid language 'xx'/, 'invalid language via write-accessor';

eval { $stemmer->language('') };
like $@, qr/Invalid language ''/, 'empty string as language via write-accessor';

eval { $stemmer->language(undef) };
like $@, qr/Language is not defined/, 'undef as language via write-accessor';

eval { Lingua::Stem::Any->new(language => 'xx') };
like $@, qr/Invalid language 'xx'/, 'invalid language via instantiator';

$stemmer = new_ok 'Lingua::Stem::Any', [
    language => 'de',
    source   => 'Lingua::Stem::Snowball',
], 'new stemmer using Snowball';

@words = @words_copy = qw( sähet singen );
is_deeply [$stemmer->stem(@words)], [qw( sahet sing )], 'list of words';
is_deeply \@words, \@words_copy, 'not destructive on arrays';

$stemmer->stem_in_place(\@words);
is_deeply \@words, [qw( sahet sing )], 'arrayref modified in place';

is_deeply scalar $stemmer->stem(@words), 'sing', 'list of words in scalar';

is_deeply [$stemmer->stem('bekämen')], ['bekam'], 'word in list context';
is_deeply [$stemmer->stem()],          [],        'empty list in list context';
is scalar $stemmer->stem('bekämen'),   'bekam',   'word in scalar context';
is scalar $stemmer->stem(),            undef,     'empty list in scalar context';

$stemmer->language('bg');
is $stemmer->language, 'bg',                  'lang changed via write-accessor';
is $stemmer->source,   'Lingua::Stem::UniNE', 'source changed to match language';
is $stemmer->stem('работа'), 'раб', 'language change confirmed by stemming';

$stemmer->source('Lingua::Stem::UniNE');
is $stemmer->source, 'Lingua::Stem::UniNE', 'updating source to itself is noop';

$stemmer->source('Lingua::Stem::Snowball');
eval { $stemmer->stem('работа') };
like $@, qr/Invalid source 'Lingua::Stem::Snowball' for language 'bg'/,
    'invalid source for current language';

eval { $stemmer->source('Acme::Buffy') };
like $@, qr/Invalid source 'Acme::Buffy'/, 'invalid source via write-accessor';

$stemmer->language('tr');
is $stemmer->language, 'tr',                     'lang changed via write-accessor';
is $stemmer->source,   'Lingua::Stem::Snowball', 'source changed to match language';
is $stemmer->stem('değilken'), 'değil', 'language change confirmed by stemming';

$stemmer->source('Lingua::Stem::UniNE');
$stemmer->language('en');
is $stemmer->source, 'Lingua::Stem::Snowball', 'source implicitly changed';
is $stemmer->stem('liquidize'), 'liquid',   'American stem with snowball';
is $stemmer->stem('liquidise'), 'liquidis', 'no Brittish stem with snowball';
$stemmer->source('Lingua::Stem');
is $stemmer->source, 'Lingua::Stem', 'source explicitly changed';
is $stemmer->stem('liquidize'), 'liquid', 'American stem with Lingua::Stem';
is $stemmer->stem('liquidise'), 'liquid', 'Brittish stem with Lingua::Stem';

$stemmer = new_ok 'Lingua::Stem::Any';
is $stemmer->language, 'en', 'default language is English';
is $stemmer->stem('fooing'), 'foo', 'default English stemming';

$stemmer->language('nb');
is $stemmer->language, 'no', 'Norwegian Bokmål (nb) coerced to Norwegian (no)';
is $stemmer->stem('være'), 'vær', 'Norwegian (no) stemming after setting Norwegian Bokmål (nb)';

$stemmer->language('nn');
is $stemmer->language, 'no', 'Norwegian Nynorsk (nn) coerced to Norwegian (no)';
is $stemmer->stem('være'), 'vær', 'Norwegian (no) stemming after setting Norwegian Nynorsk (nn)';

my @tests = (
    [qw( bg това тов )],
    [qw( cs jste jst )],
    [qw( cs není nen )],
    [qw( cs dobře dobř )],
    [qw( da ikke ikk )],
    [qw( da være vær )],
    [qw( de eine ein )],
    [qw( de für fur )],
    [qw( de françoise françois )],
    [qw( en it's it )],
    [qw( en françois françoi )],
    [qw( es para par )],
    [qw( es qué que )],
    [qw( es mañana mañan )],
    [qw( fa برای برا )],
    [qw( fi olen ole )],
    [qw( fi että et )],
    [qw( fi täällä tääl )],
    [qw( fr les le )],
    [qw( fr très tres )],
    [qw( fr même mêm )],
    [qw( gl cebolas ceb )],
    [qw( hu azt az )],
    [qw( hu miért mi )],
    [qw( hu köszönöm köszönö )],
    [qw( it sono son )],
    [qw( it perché perc )],
    [qw( it é è )],
    [qw( nl maar mar )],
    [qw( nl oké oke )],
    [qw( nl carrière carrièr )],
    [qw( no ikke ikk )],
    [qw( no være vær )],
    [qw( pl jestem jest )],
    [qw( pl proszę prosz )],
    [qw( pl możesz moż )],
    [qw( pt para par )],
    [qw( pt você voc )],
    [qw( pt não nã )],
    [qw( ro bine bin )],
    [qw( ro dacă dac )],
    [qw( ro ştii şti )],
    [qw( ru это эт )],
    [qw( sv inte int )],
    [qw( sv måste måst )],
    [qw( tr ama am )],
    [qw( tr olduğunu olduk )],
    [qw( tr için iç )],
);

for my $test (@tests) {
    my ($language, $word, $stem) = @$test;

    $stemmer->language($language);
    is $stemmer->stem($word), $stem, "$language: $word stems to $stem";

    my @words = ($word) x 2;
    my @stems = ($stem) x 2;
    $stemmer->stem_in_place(\@words);
    is_deeply \@words, \@stems, "$language: $word stems in place to $stem";
}
