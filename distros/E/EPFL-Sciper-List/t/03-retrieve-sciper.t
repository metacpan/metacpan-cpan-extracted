use strict;
use warnings;

use IO::All;
use lib 't/';
use MockSite;
use EPFL::Sciper::List qw/p_buildUrl retrieveSciper toJson toTsv/;

use Test::JSON;
use Test::MockModule;
use Test::More tests => 10;

is(
  p_buildUrl('k'),
  'https://search.epfl.ch/json/autocompletename.action?maxRows=99999999&term=k',
  'correct url'
);

my $urlRoot = MockSite::mockLocalSite('t/resources/epfl-search');

my $module = Test::MockModule->new('EPFL::Sciper::List');
$module->mock(
  'p_buildUrl',
  sub {
    my $letter = shift;
    return $urlRoot . q{/} . $letter . '.json';
  }
);

my @personsList = retrieveSciper();
is( scalar @personsList,           62,        'number of persons' );
is( $personsList[0]->{sciper},     100654,    'sciper of first person' );
is( $personsList[0]->{name},       'Klum',    'name of first person' );
is( $personsList[22]->{sciper},    168745,    'sciper of first person' );
is( $personsList[22]->{firstname}, 'Rebecca', 'name of first person' );

$urlRoot = MockSite::mockLocalSite('t/resources/epfl-search-empty');
$module->mock(
  'p_buildUrl',
  sub {
    my $letter = shift;
    return $urlRoot . q{/} . $letter . '.json';
  }
);

my $output = toJson(@personsList);
my $content < io 't/resources/output.json';
is_valid_json($output, 'is valid json');
is_json($output, $content, 'same json');

$output = toTsv(@personsList);
$content < io 't/resources/output.tsv';
is( $output, $content, 'same tsv output' );

@personsList = retrieveSciper();
is( scalar @personsList, 0, 'number of persons' );
