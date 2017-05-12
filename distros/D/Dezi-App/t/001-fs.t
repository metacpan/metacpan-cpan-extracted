use strict;
use warnings;
use Test::More tests => 11;

use_ok('Dezi::App');
use_ok('Dezi::Test::Indexer');
use_ok('Dezi::Aggregator::FS');
use_ok('Dezi::Indexer::Config');

ok( my $config = Dezi::Indexer::Config->new('t/test.conf'),
    "config from t/test.conf" );

# skip our local config test files
$config->FileRules( 'dirname contains config',              1 );
$config->FileRules( 'filename is swish.xml',                1 );
$config->FileRules( 'filename contains \.t',                1 );
$config->FileRules( 'dirname contains (testindex|\.index)', 1 );
$config->FileRules( 'filename contains \.conf',             1 );
$config->FileRules( 'dirname contains mailfs',              1 );

ok( my $invindex = Dezi::InvIndex->new( path => 't/testindex', ),
    "new invindex" );

ok( my $indexer = Dezi::Test::Indexer->new(
        invindex => $invindex,
        config   => $config,
    ),
    "new indexer"
);

ok( my $aggregator = Dezi::Aggregator::FS->new(
        indexer => $indexer,
        config  => $config,

        #verbose => 1,
        #debug   => 1,
    ),
    "new filesystem aggregator"
);

ok( my $app = Dezi::App->new(
        aggregator => $aggregator,

        #verbose    => 1,
        config => $config,
    ),
    "new program"
);

ok( $app->run('t/'), "run program" );

is( $app->count, 7, "indexed test docs" );

