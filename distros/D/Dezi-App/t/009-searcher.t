#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 131;
use Data::Dump qw( dump );

use_ok('Dezi::App');
use_ok('Dezi::Test::Indexer');
use_ok('Dezi::Test::InvIndex');
use_ok('Dezi::Aggregator::FS');
use_ok('Dezi::Indexer::Config');

ok( my $invindex = Dezi::Test::InvIndex->new( path => 'no/such/path', ),
    "new invindex" );

ok( my $config = Dezi::Indexer::Config->new('t/test.conf'),
    "config from t/test.conf" );

# skip our local config test files
$config->FileRules( 'dirname contains config',              1 );
$config->FileRules( 'filename is swish.xml',                1 );
$config->FileRules( 'filename contains \.t',                1 );
$config->FileRules( 'dirname contains (testindex|\.index)', 1 );
$config->FileRules( 'filename contains \.conf',             1 );
$config->FileRules( 'dirname contains mailfs',              1 );

ok( my $indexer = Dezi::Test::Indexer->new(
        invindex => $invindex,
        config   => $config
    ),
    "new indexer"
);

ok( my $aggregator = Dezi::Aggregator::FS->new(
        indexer => $indexer,

        #verbose => 1,
        #debug   => 1,
    ),
    "new filesystem aggregator"
);

ok( my $app = Dezi::App->new(
        aggregator => $aggregator,

        #filter => sub { diag( "doc filter on " . $_[0]->url ) },

        #verbose    => 1,
    ),
    "new program"
);

ok( $app->run('t/'), "run program" );

is( $app->count, 7, "indexed test docs" );

use_ok('Dezi::Test::Searcher');
ok( my $searcher = Dezi::Test::Searcher->new(
        invindex      => $invindex,
        swish3_config => $indexer->swish3->get_config
    ),
    "new searcher"
);

my $query = 'foo or words';
ok( my $results
        = $searcher->search( $query, { order => 'swishdocpath ASC' } ),
    "do search"
);
is( $results->hits, 5, "5 hits" );
while ( my $result = $results->next ) {
    ok( $result, "results->next" );

    #diag( dump $result );
    diag( $result->swishdocpath );
    is( $result->get_property('swishtitle'),
        $result->swishtitle, "get_property(swishtitle)" );

    # test all the built-in properties and their method shortcuts
    my @methods = qw(
        swishdocpath
        uri
        swishlastmodified
        mtime
        swishtitle
        title
        swishdescription
        summary
        swishrank
        score
    );

    for my $m (@methods) {
        ok( defined $result->$m,               "get $m" );
        ok( defined $result->get_property($m), "get_property($m)" );
    }

    # test an aliased property
    is( $result->get_property('lastmod'),
        $result->swishlastmodified,
        "aliased PropertyName fetched"
    );

}
