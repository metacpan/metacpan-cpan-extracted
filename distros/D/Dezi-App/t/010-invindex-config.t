use strict;
use warnings;
use Test::More tests => 6;

use_ok('Dezi::App');
use_ok('Dezi::Indexer::Config');
use_ok('Dezi::Test::Indexer');

ok( my $config = Dezi::Indexer::Config->new('t/test.conf'),
    "config from t/test.conf" );

$config->IndexFile("foo/bar");

ok( my $app = Dezi::App->new( config => $config, indexer => 'test', ),
    "new App" );

is( $app->indexer->invindex->path, "foo/bar", "ad hoc IndexFile config" );

