#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use Carp;
use Data::Dump qw( dump );
use File::Temp 'tempfile';

use_ok('Dezi::Bot::Queue');

SKIP: {

    eval "use DBD::SQLite";
    if ($@) {
        diag "install DBD::SQLite to test Dezi::Bot::Queue::DBI";
        skip "DBD::SQLite not installed", 13;
    }

    my ( undef, $dbfile ) = tempfile();

    ok( my $queue = Dezi::Bot::Queue->new(
            type     => 'DBI',
            dsn      => 'dbi:SQLite:dbname=' . $dbfile,
            username => 'ignore',
            password => 'ignore',
        ),
        "new Queue object"
    );

    # init the db
    my $dbh = $queue->conn->dbh;
    ok( my $r = $dbh->do( $queue->schema ), "init db" );
    if ( !$r ) {
        croak "init sqlite db $dbfile failed: " . $dbh->errstr;
    }

    # put something on the queue
    # then exercise the queue
    my $item = 'http://dezi.org/';
    ok( $queue->put($item), "put $item" );
    is( $queue->size, 1,     "size==1" );
    is( $queue->peek, $item, "peek returns $item" );
    is( $queue->size, 1,     "size still == 1 (no lock on peek)" );
    ok( my $uri = $queue->get, "get uri" );
    is( $uri,         $item, "uri==$item" );
    is( $queue->size, 0,     "nothing in the queue" );

    # query the db directly
    my $sth = $dbh->prepare('select * from dezi_queue');
    $sth->execute;
    my $row = $sth->fetchrow_hashref;

    #dump($row);
    is( $row->{id}, 1, "got expected queue row" );
    isnt( $row->{lock_time}, 0, "lock_time set" );

    is( $queue->remove($uri), 1, "remove uri from the queue" );

    $sth = $dbh->prepare('select count(*) from dezi_queue');
    $sth->execute;
    my $count = $sth->fetch->[0];

    is( $count, 0, "table empty" );
}
