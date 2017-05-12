use Test::More tests => 31;
use strict;
use Data::Dump qw( dump );

use_ok('Dezi::App');
use_ok('Dezi::Lucy::InvIndex');
use_ok('Dezi::Lucy::Searcher');

ok( my $invindex = Dezi::Lucy::InvIndex->new(
        clobber => 0,                    # Lucy handles this
        path    => 't/lucy/dezi.index'
    ),
    "new invindex"
);

my $passes = 0;
my $searcher;
while ( ++$passes < 4 ) {

    diag("pass $passes");
    ok( my $program = Dezi::App->new(
            invindex   => $invindex,
            aggregator => 'fs',
            indexer    => 'lucy',
            config     => 't/lucy/config.xml',

            #verbose    => 1,
            #debug      => 1,
        ),
        "new program"
    );

    # skip the index dir every time
    # the '1' arg indicates to append the value, not replace.
    $program->config->FileRules( 'dirname is dezi.index',                1 );
    $program->config->FileRules( 'filename is config.xml',               1 );
    $program->config->FileRules( 'filename is fields.xml',               1 );
    $program->config->FileRules( 'filename is config-nostemmer.xml',     1 );
    $program->config->FileRules( 'filename contains \.t',                1 );
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    ok( $program->run('t/lucy'), "run program" );

    is( $program->count, 2, "indexed test docs" );

    if ( !$searcher ) {
        ok( $searcher = Dezi::Lucy::Searcher->new( invindex => $invindex, ),
            "new searcher" );
    }
    else {
        pass("searcher already defined");
    }
    ok( my $results = $searcher->search('test'), "search()" );

    #diag( dump $results );

    is( $results->hits, 1, "1 hit" );

    ok( my $result = $results->next, "next result" );

    is( $result->uri, 't/lucy/test.html', 'get uri' );

    is( $result->title, "test html doc", "get title" );
}

END {
    unless ( $ENV{DEZI_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
