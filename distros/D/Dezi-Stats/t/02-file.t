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

    eval "use Log::Dispatchouli";
    if ($@) {
        diag "install Log::Dispatchouli to test Dezi::Stats::File";
        skip "Log::Dispatchouli not installed", 5;
    }

    ok( my $stats = Dezi::Stats->new(
            type      => 'File',
            path      => 'ignored',
            log_pid   => 0,
            to_stderr => 0,
            to_stdout => 0,
            to_file   => 0,
            to_self   => 1,
            facility  => undef,
        ),
        "new Stats object"
    );

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
            my $json = decode_json( $res->content );

            #dump $json;
        }
    );

    # get the logger events
    ok( my $events = $stats->dispatcher->events, "get events" );

    #dump $events;

    is( scalar @$events, 1, "got one event" );
    my $row = decode_json( $events->[0]->{message} );
    is_deeply(
        $row,
        {   L           => undef,
            b           => undef,
            build_time  => undef,
            c           => undef,
            f           => undef,
            h           => undef,
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
        "got expected stats event"
    );

}
