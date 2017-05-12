#!/usr/bin/perl -w
use strict;

#use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 11;

my $test_vars = {
    'cookiename' => 'session',
    'timeout' => '3600',
    'ipaddr' => '',
    'maxpicwidth' => '500',
    'host' => 'example.com',
    'article' => {
        'data' => {
            'createdate' => '1189973221',
            'title' => 'Test Lyric',
            'publish' => '3',
            'name' => 'guest',
            'latest' => '0',
            'front' => '0',
            'imageid' => '0',
            'quickname' => 'test',
            'articleid' => '3',
            'postdate' => '16th September 2007',
            'snippet' => undef,
            'sectionid' => '7',
            'userid' => '1',
            'folderid' => '1'
        },
        'body' => []
    },
    'webdir' => 't/_DBDIR/html',
    'icode' => 'testsite',
    'mailhost' => '',
    'testing' => '0',
    'administrator' => 'admin@example.com',
    'blank' => 'images/blank.png',
    'lastpagereturn' => '0',
    'webpath' => '',
    'evalperl' => '1',
    'realm' => 'public',
    'cgipath' => '/cgi-bin',
    'randpicwidth' => '400',
    'autoguest' => '1',
    'iname' => 'Test Site',
    'primary' => 'test',
    'cgiroot' => 'http://example.com',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'basedir' => 't/_DBDIR',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'copyright' => '2013-2014 Me',
    'mainarts' => [
        {
            'data' => {
                'createdate' => '1189973221',
                'title' => 'Test Lyric',
                'publish' => '3',
                'name' => 'guest',
                'latest' => '0',
                'front' => '0',
                'imageid' => '0',
                'quickname' => 'test',
                'articleid' => '3',
                'postdate' => '16th September 2007',
                'snippet' => undef,
                'sectionid' => '7',
                'userid' => '1',
                'folderid' => '1'
            },
            'body' => []
        },
    ],
    'script' => '',
    'maxpasslen' => '20',
    'articles' => {
        'test' => {
            'data' => {
                'createdate' => '1189973221',
                'title' => 'Test Lyric',
                'publish' => '3',
                'name' => 'guest',
                'latest' => '0',
                'front' => '0',
                'imageid' => '0',
                'quickname' => 'test',
                'articleid' => '3',
                'postdate' => '16th September 2007',
                'snippet' => undef,
                'sectionid' => '7',
                'userid' => '1',
                'folderid' => '1'
            },
            'body' => []
        },
    },
    'docroot' => 'http://example.com',
    'minpasslen' => '6',
    'htmltags' => '+img'
};

my @plugins = qw(
    Labyrinth::Plugin::Articles::Lyrics
);

# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new( keep => 1 );
my $dir = $loader->directory;

my $res = $loader->prep(
    sql     => [ "$dir/cgi-bin/db/plugin-base.sql","t/data/test-base.sql" ],
    files   => { 
        't/data/phrasebook.ini' => 'cgi-bin/config/phrasebook.ini'
    },
    config  => {
        'INTERNAL'  => { logclear => 0 }
    }
);
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 11  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Articles::Lyrics::List'),1);
    diag($loader->error)    unless($res);

    my $vars = $loader->vars;
    #diag("list vars=".Dumper($vars));
    is_deeply($vars,$test_vars,'list variables are as expected');

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 2 } );

    # test bad access to admin
    for my $call ( 'Articles::Lyrics::Admin' ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(),       '<select id="lyricid" name="lyricid"><option value="3">Test Lyric</option></select>');
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(1),      '<select id="lyricid" name="lyricid"><option value="3">Test Lyric</option></select>');
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(1,1),    '<select id="lyricid" name="lyricid"><option value="0">Select Lyric</option><option value="3">Test Lyric</option></select>');
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(1,0),    '<select id="lyricid" name="lyricid"><option value="3">Test Lyric</option></select>');
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(undef,1),'<select id="lyricid" name="lyricid"><option value="0">Select Lyric</option><option value="3">Test Lyric</option></select>');
    is(Labyrinth::Plugin::Articles::Lyrics::LyricSelect(undef,0),'<select id="lyricid" name="lyricid"><option value="3">Test Lyric</option></select>');
}
