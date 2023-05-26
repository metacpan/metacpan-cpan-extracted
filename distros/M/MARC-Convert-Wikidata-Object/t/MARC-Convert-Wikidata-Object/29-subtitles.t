use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->subtitles, [], 'Get default subtitles.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'subtitles' => ['Subtitle'],
);
is_deeply($obj->subtitles, ['Subtitle'], 'Get explicit subtitle.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'subtitles' => ['Subtitle1', 'Subtitle2'],
);
is_deeply($obj->subtitles, ['Subtitle1', 'Subtitle2'], 'Get more explicit subtitles.');
