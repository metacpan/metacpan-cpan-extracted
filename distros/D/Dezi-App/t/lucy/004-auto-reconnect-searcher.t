#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 17;
use Dezi::Lucy::Indexer;
use Dezi::Lucy::Searcher;
use Dezi::Lucy::InvIndex;
use Dezi::Indexer::Doc;

ok( my $invindex = Dezi::Lucy::InvIndex->new(
        clobber => 0,                     # Lucy handles this
        path    => 't/lucy/dezi.index',
    ),
    "new invindex"
);

ok( my $indexer = Dezi::Lucy::Indexer->new( invindex => $invindex ),
    "new indexer" );

ok( my $doc = Dezi::Indexer::Doc->new(
        url     => 'foo/bar',
        content => '<doc><title>round 1</title></doc>',
        type    => 'application/xml'
    ),
    "new doc, round 1"
);

ok( $indexer->process($doc), "process doc" );
is( $indexer->finish(), 1, "finish indexer with 1 total docs" );

ok( my $searcher = Dezi::Lucy::Searcher->new( invindex => $invindex ),
    "new searcher" );

ok( my $results = $searcher->search(qq/swishtitle="round 1"/),
    "search for round 1" );
is( $results->hits, 1, "1 match" );

# update doc
ok( my $doc2 = Dezi::Indexer::Doc->new(
        url     => 'foo/bar',
        content => '<doc><title>round 2</title></doc>',
        type    => 'application/xml'
    ),
    "new doc, round 2"
);

ok( my $indexer2 = Dezi::Lucy::Indexer->new( invindex => $invindex ),
    "new indexer2" );
ok( $indexer2->process($doc2), "process doc2" );
is( $indexer2->finish(), 1, "finish indexer with 1 total docs" );

# search again with old searcher object. should find updated doc.
ok( $results = $searcher->search(qq/swishtitle="round 2"/),
    "search for round 2" );
is( $results->hits, 1, "1 match" );

# new searcher object should find the same thing
ok( my $searcher2 = Dezi::Lucy::Searcher->new(
        invindex => $invindex,
        nfs_mode => 1,           # exercise code but not failure conditions
    ),
    "new searcher2"
);
ok( $results = $searcher2->search(qq/swishtitle="round 2"/),
    "search for round 2" );
is( $results->hits, 1, "1 match" );

END {
    unless ( $ENV{DEZI_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
