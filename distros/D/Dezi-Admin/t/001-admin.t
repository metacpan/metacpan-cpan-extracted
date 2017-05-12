#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 36;
use Plack::Test;
use File::Temp 'tempfile';
use Plack::Request;
use HTTP::Request;
use JSON;
use Data::Dump qw( dump );
use Carp;

SKIP: {

    eval "use Dezi::Stats::DBI 0.001005";
    if ($@) {
        diag "install Dezi::Stats::DBI >= 0.001005 to test Dezi::Admin";
        skip "Dezi::Stats::DBI not installed", 36;
    }

    eval "use DBD::SQLite";
    if ($@) {
        diag "install DBD::SQLite to test Dezi::Admin";
        skip "DBD::SQLite not installed", 36;
    }

    my ( undef, $dbfile ) = tempfile();

    ok( my $stats = Dezi::Stats->new(
            type     => 'DBI',
            dsn      => 'dbi:SQLite:dbname=' . $dbfile,
            username => 'ignored',
            password => 'ignored',
        ),
        "new Stats object"
    );

    # init the db
    my $dbh = $stats->conn->dbh;
    ok( my $r = $dbh->do( $stats->schema ), "init db" );
    if ( !$r ) {
        croak "init sqlite db $dbfile failed: " . $dbh->errstr;
    }

    use_ok('Dezi::Server');

    ok( my $app = Dezi::Server->app(
            {   search_path   => 's',
                index_path    => 'i',
                engine_config => {
                    indexer_config => {
                        config => { 'FuzzyIndexingMode' => 'Stemming_en1', },
                    },
                },
                admin_class  => 'Dezi::Admin',
                stats_logger => $stats,
            }
        ),
        "new Plack app with admin_class"
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/s' );
            my $res = $cb->($req);
            is( $res->content, qq/'q' required/, "missing 'q' param" );
            is( $res->code, 400, "bad request status" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( PUT => 'http://localhost/s/foo/bar' );
            $req->content_type('application/xml');
            $req->content('<doc><title>i am a test</title></doc>');
            $req->content_length( length( $req->content ) );
            my $res = $cb->($req);

            #dump $res;
            #diag( $res->content );
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $json->{success}, 0,   "405 json response has success=0" );
            is( $res->code,       405, "PUT not allowed to /s" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( PUT => 'http://localhost/i/foo/bar' );
            $req->content_type('application/xml');
            $req->content(
                '<doc><title>i am a test</title>tester testing test123</doc>'
            );
            $req->content_length( length( $req->content ) );
            my $res = $cb->($req);

            #dump $res;
            #diag( $res->content );
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $json->{doc}->{title}, 'i am a test', "test title" );
            is( $res->code,            201,           "PUT ok" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( GET => 'http://localhost/s?q=test' );
            my $res = $cb->($req);
            ok( my $results = decode_json( $res->content ),
                "decode_json response" );

            #dump $results;
            is( $results->{query}, "test", "query param returned" );
            cmp_ok( $results->{total}, '==', 1, "more than one hit" );
            ok( exists $results->{search_time}, "search_time key exists" );
            is( $results->{title}, qq/OpenSearch Results/, "got title" );
            if ( defined $results->{suggestions} ) {
                is_deeply(
                    $results->{suggestions},
                    [ 'test', 'test123', 'tester' ],
                    "got 3 suggestions, testing stemmed to test"
                );
            }
            else {
                pass("suggester not available");
            }
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                DELETE => 'http://localhost/i/foo/bar' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $res->code, 200, "DELETE ok" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( GET => 'http://localhost/s?q=test' );
            my $res = $cb->($req);
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );
            is( $json->{total}, 0, "DELETE worked" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/admin' );
            my $res = $cb->($req);
            is( $res->content_type, 'text/html', "/admin page is text/html" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => 'http://localhost/admin/static/css/dezi-admin.css' );
            my $res = $cb->($req);
            is( $res->content_type, 'text/css',
                "/admin/static/css is text/css" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( GET => 'http://localhost/admin/api' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );
            is( $json->{type}, 'Lucy', "/admin/api has correct type" );
            is( $json->{models}->[0], 'stats', "stats model loaded" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => 'http://localhost/admin/api/stats' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );
            is( $json->{total}, 4, "4 stats" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => 'http://localhost/admin/api/stats/terms' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );
            is( $json->{total},                 1,      "1 stats/terms" );
            is( $json->{results}->[0]->{count}, 2,      "got count result" );
            is( $json->{results}->[0]->{term},  'test', "got term result" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => 'http://localhost/admin/api/indexes' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;

            is( $json->{total}, 1, "1 index" );
            is( $json->{results}->[0]->{config}->{FuzzyIndexingMode},
                'Stemming_en1', 'stemming config preserved' );
        }
    );

    # clean up
    unless ( $ENV{DEZI_DEBUG} ) {
        system("rm -rf dezi.index");
    }
}
