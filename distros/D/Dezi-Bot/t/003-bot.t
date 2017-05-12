#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use lib 't';

my $num_tests = 8;

use Carp;
use Data::Dump qw( dump );
use File::Temp qw( tempfile tempdir );

SKIP: {

    eval "use DBI";
    if ($@) {
        diag "install DBI to test Dezi::Bot";
        skip "DBI not installed", $num_tests;
    }

    eval "use DBD::SQLite";
    if ($@) {
        diag "install DBD::SQLite to test Dezi::Bot";
        skip "DBD::SQLite not installed", $num_tests;
    }

    eval "use SWISH::Prog::Aggregator::Spider";
    if ( $@ && $@ =~ m/([\w:]+)/ ) {
        skip "$1 required for Dezi::Bot test: $@", $num_tests;
    }

    eval "use Test::HTTP::Server::Simple";
    if ($@) {
        skip "Test::HTTP::Server::Simple required for Dezi::Bot test: $@",
            $num_tests;
    }

    eval "use HTTP::Server::Simple::CGI";
    if ($@) {
        skip "HTTP::Server::Simple::CGI required for Dezi::Bot test: $@",
            $num_tests;
    }

    # load our server
    require TestServer;

    # our classes
    use_ok('Dezi::Bot');
    use_ok('Dezi::Bot::Queue::DBI');
    use_ok('Dezi::Bot::Handler::FileCacher');

    # init temp db
    my ( undef, $dbfile ) = tempfile();
    my $dsn = 'dbi:SQLite:dbname=' . $dbfile;
    my $dbh = DBI->connect($dsn);

    # init the schema
    my $r;
    ok( $r = $dbh->do( Dezi::Bot::Queue::DBI->schema ), "init queue table" );
    if ( !$r ) {
        croak "init queue table in $dbfile failed: " . $dbh->errstr;
    }
    ok( $r = $dbh->do( Dezi::Bot::Handler::FileCacher->schema ),
        "init filecache table" );
    if ( !$r ) {
        croak "init filecache table in $dbfile failed: " . $dbh->errstr;
    }

    # configure Bot
    my $tmpdir       = tempdir( CLEANUP => 1 );
    my $tmp_cachedir = tempdir( CLEANUP => 1 );

    ok( my $bot = Dezi::Bot->new(
            handler_class  => 'TestHandler',
            handler_config => {
                root_dir => $tmpdir,
                dsn      => $dsn,
                username => 'ignored',
                password => 'ignored',
            },
            spider_config => {
                debug => 3,
                email => 'bot-test@dezi.org',
                delay => 0,                     # fail in a hurry
            },
            queue_config => {
                type     => 'DBI',
                dsn      => $dsn,
                username => 'ignored',
                password => 'ignored',
            },
            cache_config => {
                driver    => 'File',
                root_dir  => $tmp_cachedir,
                namespace => 'dezibot',
            },
        ),
        "new Bot"
    );

    # start server
    my $server = TestServer->new();
    my $url    = $server->started_ok("start http server");

    # start crawling
    is( $bot->crawl($url), 4, "crawl" );
}
