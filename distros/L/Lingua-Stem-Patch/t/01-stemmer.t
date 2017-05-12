use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 26;
use Lingua::Stem::Patch;

my (@words, @words_copy);

my $stemmer = new_ok 'Lingua::Stem::Patch', [language => 'eo'];

can_ok $stemmer, qw( stem language languages );

is $stemmer->language, 'eo', 'language read-accessor';

my @langs = qw( eo io pl );
my $langs = @langs;
is_deeply [$stemmer->languages],            \@langs, 'object method list';
is_deeply [Lingua::Stem::Patch->languages], \@langs, 'class method list';
is_deeply [Lingua::Stem::Patch::languages], \@langs, 'function list';
is scalar $stemmer->languages,               $langs, 'object method scalar';
is scalar Lingua::Stem::Patch->languages,    $langs, 'class method scalar';
is scalar Lingua::Stem::Patch::languages,    $langs, 'function scalar';

@words = @words_copy = qw( ĝin ekmanĝis manĝado );
is_deeply [$stemmer->stem(@words)], [qw( ĝi manĝi manĝi )], 'list of words';
is_deeply \@words, \@words_copy, 'not destructive on arrays';

is_deeply scalar $stemmer->stem(@words), 'manĝi', 'list of words in scalar';

is_deeply [$stemmer->stem('manĝu')], ['manĝi'], 'word in list context';
is_deeply [$stemmer->stem()],        [],        'empty list in list context';
is scalar $stemmer->stem('manĝu'),   'manĝi',   'word in scalar context';
is scalar $stemmer->stem(),          undef,     'empty list in scalar context';

is $stemmer->stem('manjez'), 'manjez', 'only stem for current language';

$stemmer->language('io');
is $stemmer->language,       'io',     'language changed via write-accessor';
is $stemmer->stem('manjis'), 'manjar', 'language change confirmed by stemming';

$stemmer->language('EO');
is $stemmer->language,       'eo',    'language coerced via write-accessor';
is $stemmer->stem('manĝis'), 'manĝi', 'language coersion confirmed by stemming';

eval { $stemmer->language('xx') };
like $@, qr/Invalid language 'xx'/, 'invalid language via write-accessor';

eval { $stemmer->language('') };
like $@, qr/Invalid language ''/, 'empty string as language via write-accessor';

eval { $stemmer->language(undef) };
like $@, qr/Invalid language ''/, 'undef as language via write-accessor';

eval { Lingua::Stem::Patch->new(language => 'xx') };
like $@, qr/Invalid language 'xx'/, 'invalid language via instantiator';

eval { Lingua::Stem::Patch->new() };
like $@, qr/Missing required arguments: language/, 'instantiator w/o language';
