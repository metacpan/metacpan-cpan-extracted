#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;

use Carp;
use Data::Dump qw( dump );
use File::Temp 'tempfile';
use Plack::Test;
use Plack::Request;
use JSON;
use Search::OpenSearch::Response::JSON;

use_ok('Dezi::Stats');

SKIP: {

    eval "use DBIx::Connector";
    if ($@) {
        diag "install DBIx::Connector to test Dezi::Stats::DBI";
        skip "DBIx::Connector not installed", 5;
    }

    eval "use DBIx::InsertHash";
    if ($@) {
        diag "install DBIx::InsertHash to test Dezi::Stats::DBI";
        skip "DBIx::InsertHash not installed", 5;
    }

    eval "use DBD::SQLite";
    if ($@) {
        diag "install DBD::SQLite to test Dezi::Stats::DBI";
        skip "DBD::SQLite not installed", 5;
    }

    my ( undef, $dbfile ) = tempfile();

    ok( my $stats = Dezi::Stats->new(
            type     => 'DBI',
            dsn      => 'dbi:SQLite:dbname=' . $dbfile,
            username => 'ignore',
            password => 'ignore',
        ),
        "new Stats object"
    );

    # init the db
    my $dbh = $stats->conn->dbh;
    ok( my $r = $dbh->do( $stats->schema ), "init db" );
    if ( !$r ) {
        croak "init sqlite db $dbfile failed: " . $dbh->errstr;
    }

    my $app = sub {
        my $request  = Plack::Request->new(shift);
        my $sos_resp = Search::OpenSearch::Response::JSON->new();
        ok( $stats->log( $request, $sos_resp ), "log request" );
        return [
            200, [ 'Content-Type', $sos_resp->content_type, ],
            ["$sos_resp"]
        ];
    };

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET =>
                    'http://localhost/search/?q=test&s=foo+ASC&o=0&p=100' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode_json content" );

            #dump $json;
        }
    );

    # query the db
    my $sth = $dbh->prepare('select * from dezi_stats');
    $sth->execute;
    my $row = $sth->fetchrow_hashref;

    #dump($row);
    is_deeply(
        $row,
        {   L           => undef,
            b           => undef,
            build_time  => undef,
            c           => undef,
            f           => undef,
            h           => undef,
            id          => 1,
            o           => 0,
            p           => 100,
            "q"         => "test",
            r           => undef,
            remote_user => undef,
            "s"         => "foo ASC",
            search_time => undef,
            t           => undef,
            tstamp      => $row->{tstamp},
            path        => '/search/',
            total       => undef,
        },
        "got expected stats row"
    );

}
