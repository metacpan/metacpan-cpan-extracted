#!perl
# @(#) $Id: Log-Dispatch-Atom.t 1102 2005-12-07 14:33:19Z dom $

use strict;
use warnings;

use File::Temp qw( tempfile );
use Log::Dispatch::Atom;
use POSIX qw( strftime );
use Sys::Hostname;
use Test::More 'no_plan';
use XML::Atom::Feed;

test_basics();
test_feed_extras();
test_timestamps();

sub test_basics {
    my $fn  = tempfilename();
    my $log = Log::Dispatch::Atom->new(
        name      => 'foo',
        min_level => 'debug',
        file      => $fn
    );
    isa_ok( $log, 'Log::Dispatch::Atom' );
    can_ok( $log, qw( log ) );

    my $today = strftime "%Y-%m-%d", gmtime;
    my $now = time;
    $log->log( level => 'info', message => 'hello world' );
    my $feed = eval { XML::Atom::Feed->new( $fn ) };
    is( $@, '', 'log(1) No problems parsing feed.' );
    my @entries = $feed->entries;
    is( scalar( @entries ), 1, 'log(1) produced 1 entry' );
    is( $entries[0]->title, 'hello world', 'log(1) made correct title' );
    is( $entries[0]->content->body,
        'hello world', 'log(1) made correct content' );
    my $expected_id = "tag:" . hostname() . ",$today:$now/$$/1";
    is( $entries[0]->id, $expected_id, 'log(1) made correct id' );

    $now = time;
    $log->log( level => 'info', message => 'hello world#2' );
    $feed = eval { XML::Atom::Feed->new( $fn ) };
    is( $@, '', 'log(2) No problems parsing feed.' );
    @entries = $feed->entries;
    is( scalar( @entries ), 2, 'log(2) produced 1 more entry' );
    is( $entries[0]->title, 'hello world#2', 'log(2) made correct title' );
    is(
        $entries[0]->content->body,
        'hello world#2',
        'log(2) made correct content'
    );
    $expected_id = "tag:" . hostname() . ",$today:$now/$$/2";
    is( $entries[0]->id, $expected_id, 'log(2) made correct id' );
    return;
}

sub test_feed_extras {
    my $fn  = tempfilename();
    my $log = Log::Dispatch::Atom->new(
        name        => 'test_feed_extras',
        min_level   => 'debug',
        file        => $fn,
        feed_title  => 'My Test Log',
        feed_id     => 'http://example.com/log/',
        feed_author => {
            name  => 'Fred Flintstone',
            email => 'fred@flintstones.com',
            uri   => 'http://fred.flintstones.com/',
        },
    );
    isa_ok( $log, 'Log::Dispatch::Atom' );

    $log->log(
        level   => 'info',
        message => 'hello world',
        author  => { name => 'Barney' }
    );
    my $feed = eval { XML::Atom::Feed->new( $fn ) };
    is( $@, '', 'test_feed_extras: No problems parsing feed.' );
    is( $feed->title, 'My Test Log', 'test_feed_extras: title' )
        or diag( slurp( $fn ) );
    is( $feed->id, 'http://example.com/log/', 'test_feed_extras: id' );

    isa_ok( $feed->author, 'XML::Atom::Person', 'test_feed_extras: author' );
    is(
        $feed->author->name,
        'Fred Flintstone',
        'test_feed_extras: author/name',
    );
    is( $feed->author->email, 'fred@flintstones.com',
        'test_feed_extras: author/email',
    );
    is(
        $feed->author->uri,
        'http://fred.flintstones.com/',
        'test_feed_extras: author/uri',
    );

    my ( $e1 ) = $feed->entries;
    isa_ok( $e1->author, 'XML::Atom::Person',
        'test_feed_extras: entry/author' );
    is( $e1->author->name, 'Barney', 'test_feed_extras: entry/author/name' );
    return;
}

sub test_timestamps {
    my $fn  = tempfilename();
    my $log = Log::Dispatch::Atom->new(
        name      => 'test_timestamps',
        min_level => 'debug',
        file      => $fn,
    );
    isa_ok( $log, 'Log::Dispatch::Atom' );

    my $now = strftime "%Y-%m-%dT%H:%M:%SZ", gmtime;
    $log->log( level => 'debug', message => 'Got Here' );
    my $feed = eval { XML::Atom::Feed->new( $fn ) };
    is( $@, '', 'test_timestamps: No problems parsing feed.' );
    is( $feed->updated, $now,
        'test_timestamps: feed has correct updated time.' );

    my @entries = $feed->entries;
    is( scalar( @entries ), 1, 'test_timestamps: produced 1 entry' );
    is( $entries[0]->updated, $now, 'test_timestamps: entry has correct time' );
    return;
}

sub tempfilename {
    my ( $fh, $filename ) = tempfile( 'XML-Atom-Log.XXXXXX', UNLINK => 1 );
    close $fh;
    return $filename;
}

sub slurp {
    my ( $file ) = @_;
    open my $fh, '<', $file or die "open($file): $!\n";
    my $contents = do { local $/; <$fh> };
    close $fh;
    return $contents;
}

# vim: set ai et sw=4 syntax=perl :
