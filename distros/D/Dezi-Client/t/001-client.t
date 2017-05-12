#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 25;
use Data::Dump qw( dump );
use JSON;

use_ok('Dezi::Client');
use_ok('Dezi::Doc');

SKIP: {

    diag("set DEZI_URL to test Dezi::Client") unless $ENV{DEZI_URL};
    skip "set DEZI_URL to test Dezi::Client", 23 unless $ENV{DEZI_URL};

    # open a connection
    ok( my $client = Dezi::Client->new( server => $ENV{DEZI_URL}, ),
        "new client" );

    my $resp;

    # add/update a filesystem document to the index
    ok( $resp = $client->index('t/test.html'), "index t/test.html" );
    ok( $resp->is_success, "index fs success" );

    # add/update an in-memory document to the index
    my $html_doc
        = qq(<html><title>hello world</title><body>foo bar</body></html>);
    ok( $resp = $client->index( \$html_doc, 'foo/bar.html' ),
        "index \$html_doc" );
    ok( $resp->is_success, "index scalar_ref success" );

    # add/update a Dezi::Doc to the index
    my $dezi_doc = Dezi::Doc->new( uri => 't/test-dezi-doc.xml' );
    $dezi_doc->content( Search::Tools->slurp( $dezi_doc->uri ) );
    ok( $resp = $client->index($dezi_doc), "index Dezi::Doc" );
    ok( $resp->is_success, "index Dezi::Doc success" );

    my $doc2 = Dezi::Doc->new( uri => 'auto/xml/magic', );
    $doc2->set_field( 'title' => 'ima dezi doc' );
    $doc2->set_field( 'body'  => 'hello world!' );
    ok( $resp = $client->index($doc2),
        "Dezi::Doc converts to XML automatically" );
    ok( $resp->is_success, "auto XML success" );

    # commit our changes
    is( decode_json( $client->commit()->content )->{success},
        1, "/commit changes" );

    # remove a document from the index

    ok( $resp = $client->delete('foo/bar.html'), "delete foo/bar.html" );
    ok( $resp->is_success, "delete success" );

    # search the index
    ok( my $response = $client->search( q => 'dezi' ), "search" );

    #diag( dump $response );

    # iterate over results
    for my $result ( @{ $response->results } ) {

        #diag( dump $result );
        ok( $result->uri, "get result uri" );
        like( $result->mtime, qr/^\d+$/, "mtime is an int" );
        diag(
            sprintf(
                "--\n uri: %s\n title: %s\n score: %s\n summary: %s\n mtime: %s\n",
                $result->uri,     $result->title, $result->score,
                $result->summary, $result->mtime,
            )
        );
    }

    # print stats
    is( $response->total, 3, "got 3 results" );
    ok( $response->search_time, "got search_time" );
    ok( $response->build_time,  "got build time" );
    is( $response->query, "dezi", "round-trip query string" );

}
