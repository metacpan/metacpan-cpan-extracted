#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 56;

my $test_vars = {
        'testing' => '0',
        'copyright' => '2013-2014 Me',
        'cgiroot' => 'http://example.com',
        'lastpagereturn' => '0',
        'autoguest' => '1',
        'administrator' => 'admin@example.com',
        'timeout' => '3600',
        'docroot' => 'http://example.com',
        'mailhost' => '',
        'iname' => 'Test Site',
        'blank' => 'images/blank.png',
        'realm' => 'public',
        'cookiename' => 'session',
        'minpasslen' => '6',
        'maxpasslen' => '20',
        'webdir' => 't/_DBDIR/html',
        'ipaddr' => '',
        'script' => '',
        'requests' => 't/_DBDIR/cgi-bin/config/requests',
        'cgidir' => 't/_DBDIR/cgi-bin',
        'maxpicwidth' => '500',
        'host' => 'example.com',
        'basedir' => 't/_DBDIR',
        'cgipath' => '/cgi-bin',
        'album' => {
                     'iid' => 0
                   },
        'htmltags' => '+img',
        'icode' => 'testsite',
        'evalperl' => '1',
        'webpath' => '',
        'randpicwidth' => '400'
};

my $test_data = { 
    add => {
        'pageid' => '1',
        'title' => 'Archive'
    },
    edit1a => [
        {
          'title' => 'Archive',
          'pageid' => '1'
        },
        {
          'title' => 'Home Page',
          'pageid' => '2'
        },
        {
          'title' => 'Test Page',
          'pageid' => '3'
        },
        {
          'pageid' => '4',
          'title' => 'Test Sub Page 1'
        },
        {
          'title' => 'Test Sub Page 2',
          'pageid' => '5'
        }
    ],
    edit2a => [
        {
          'title' => 'Archive',
          'pageid' => '1'
        },
        {
          'pageid' => '2',
          'title' => 'Home Page'
        },
        {
          'pageid' => '3',
          'title' => 'Test Page'
        },
        {
          'pageid' => '4',
          'title' => 'Test Sub Page 1'
        },
        {
          'title' => 'Test Sub Page 2',
          'pageid' => '5'
        }
    ],
    edit2b => {
        'dimensions' => '800x600',
        'photoid' => '2',
        'thumb' => '20050830/dscf5904-thumb.jpg',
        'image' => '20050830/dscf5904.jpg',
        'tagline' => undef,
        'cover' => '0',
        'hide' => '0',
        'pageid' => '3',
        'orderno' => '2'
    },
    admin1 => [
        {
          'photoid' => '1',
          'thumb' => '20050830/dscf5903-thumb.jpg',
          'pageid' => '3',
          'tagline' => undef,
          'title' => 'Test Page'
        },
        {
          'thumb' => '20050830/dscf5904-thumb.jpg',
          'photoid' => '2',
          'tagline' => undef,
          'title' => 'Test Page',
          'pageid' => '3'
        },
        {
          'thumb' => '20050830/dscf5905-thumb.jpg',
          'photoid' => '3',
          'title' => 'Test Sub Page 1',
          'tagline' => undef,
          'pageid' => '4'
        },
        {
          'thumb' => '20050830/dscf5906-thumb.jpg',
          'photoid' => '4',
          'title' => 'Test Sub Page 2',
          'tagline' => undef,
          'pageid' => '5'
        }
    ],
    admin3 => [
        {
          'title' => 'Test Page',
          'tagline' => undef,
          'thumb' => '20050830/dscf5903-thumb.jpg',
          'photoid' => '1',
          'pageid' => '3'
        },
        {
          'photoid' => '2',
          'pageid' => '3',
          'title' => 'Test Page',
          'tagline' => 'Labyrinth',
          'thumb' => 'thumb.png'
        },
        {
          'title' => 'Test Sub Page 1',
          'tagline' => undef,
          'thumb' => '20050830/dscf5905-thumb.jpg',
          'photoid' => '3',
          'pageid' => '4'
        },
        {
          'pageid' => '5',
          'photoid' => '4',
          'tagline' => undef,
          'thumb' => '20050830/dscf5906-thumb.jpg',
          'title' => 'Test Sub Page 2'
        }
    ],
    admin4 => {
        'photoid' => '2',
        'thumb' => '',
        'image' => '',
        'tagline' => '',
        'summary' => '',
        'hide' => 0,
        'pageid' => '',
        'title' => 'Labyrinth2'
    },
    view1 => {
        'photo' => {
                 'orderno' => '2',
                 'photoid' => '2',
                 'tagline' => 'Labyrinth',
                 'cover' => '0',
                 'pageid' => '3',
                 'thumb' => 'thumb.png',
                 'hide' => '0',
                 'image' => 'image.jpg',
                 'prev' => '1',
                 'toobig' => 1,
                 'dimensions' => '800x600'
        },
        'page' => {
                'hide' => '0',
                'year' => '2005',
                'summary' => '',
                'title' => 'Test Page',
                'orderno' => '0',
                'path' => 'photos/20050830',
                'month' => 'August',
                'tagline' => '',
                'area' => '1',
                'parent' => '0',
                'pageid' => '3'
        }
    },
    gallery1 => [
        {
          'photoid' => '1',
          'image' => '20050830/dscf5903.jpg',
          'cover' => '1',
          'pageid' => '3',
          'tagline' => undef,
          'thumb' => 'photos/20050830/dscf5903-thumb.jpg',
          'dimensions' => '800x600',
          'orderno' => '1',
          'hide' => '0'
        },
        {
          'tagline' => 'Labyrinth',
          'image' => 'image.jpg',
          'photoid' => '2',
          'pageid' => '3',
          'cover' => '0',
          'hide' => '0',
          'orderno' => '2',
          'dimensions' => '800x600',
          'thumb' => 'photos/thumb.png'
        },
        {
          'hide' => '0',
          'dimensions' => '800x600',
          'thumb' => 'photos/20050830/dscf5905-thumb.jpg',
          'orderno' => '1',
          'image' => '20050830/dscf5905.jpg',
          'photoid' => '3',
          'pageid' => '4',
          'cover' => '1',
          'tagline' => undef
        },
        {
          'pageid' => '5',
          'cover' => '0',
          'image' => '20050830/dscf5906.jpg',
          'photoid' => '4',
          'tagline' => undef,
          'hide' => '0',
          'thumb' => 'photos/20050830/dscf5906-thumb.jpg',
          'dimensions' => '800x600',
          'orderno' => '1'
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'tagline' => '',
          'thumb' => 'images/blank.png'
        },
        {
          'tagline' => '',
          'thumb' => 'images/blank.png'
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        }
    ],
    gallery2 => [
        {
          'thumb' => 'photos/thumb.png',
          'dimensions' => '800x600',
          'orderno' => '2',
          'hide' => '0',
          'photoid' => '2',
          'image' => 'image.jpg',
          'cover' => '0',
          'pageid' => '3',
          'tagline' => 'Labyrinth'
        },
        {
          'tagline' => undef,
          'pageid' => '4',
          'cover' => '1',
          'image' => '20050830/dscf5905.jpg',
          'photoid' => '3',
          'hide' => '0',
          'thumb' => 'photos/20050830/dscf5905-thumb.jpg',
          'dimensions' => '800x600',
          'orderno' => '1'
        },
        {
          'tagline' => undef,
          'cover' => '0',
          'pageid' => '5',
          'photoid' => '4',
          'image' => '20050830/dscf5906.jpg',
          'thumb' => 'photos/20050830/dscf5906-thumb.jpg',
          'dimensions' => '800x600',
          'orderno' => '1',
          'hide' => '0'
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'tagline' => '',
          'thumb' => 'images/blank.png'
        },
        {
          'tagline' => '',
          'thumb' => 'images/blank.png'
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        },
        {
          'thumb' => 'images/blank.png',
          'tagline' => ''
        }
    ],
    'albums' => {
        '3' => {
            'records' => [
                {
                    'thumb' => '20050830/dscf5903-thumb.jpg',
                    'image' => '20050830/dscf5903.jpg',
                    'hide' => '0',
                    'photoid' => '1',
                    'cover' => '1',
                    'orderno' => 1,
                    'pageid' => '3',
                    'dimensions' => '800x600',
                    'tagline' => undef
                },
                {
                    'pageid' => '3',
                    'orderno' => 2,
                    'cover' => '0',
                    'photoid' => '2',
                    'hide' => '0',
                    'image' => 'image.jpg',
                    'thumb' => 'thumb.png',
                    'tagline' => 'Labyrinth',
                    'dimensions' => '800x600'
                }
            ],
        },
        '2' => {
            'records' => undef
        }
    },
};

my @plugins = qw(
    Labyrinth::Plugin::Album::Photos
);

# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new( keep => 0 );
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
    skip "Unable to prep the test environment", 56  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Album::Photos::List'),1);
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
    for my $call (  'Album::Photos::Admin','Album::Photos::Add','Album::Photos::Edit','Album::Photos::Move',
                    'Album::Photos::Save','Album::Photos::Delete','Album::Photos::Archive') {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        is($vars->{data},undef,"no permission: $call");
    }
    
    # Add a page
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef } );

    # test adding a link
    $res = is($loader->action('Album::Photos::Add'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{pages}));
    is_deeply($vars->{pages},$test_data->{add},'add variables are as expected');


    # edit with no photo given
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    $res = is($loader->action('Album::Photos::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit1a vars=".Dumper($vars->{pages}));
    is_deeply($vars->{pages},$test_data->{edit1a},"base data provided, when no photo given");
    #diag("edit1b vars=".Dumper($vars->{record}));
    is_deeply($vars->{record},$test_data->{edit1b},"base data provided, when no photo given");

    # Edit known photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { iid => 2 });

    $res = is($loader->action('Album::Photos::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit2a vars=".Dumper($vars->{pages}));
    is_deeply($vars->{pages},$test_data->{edit2a},"base data provided, with photo given");
    #diag("edit2b vars=".Dumper($vars->{record}));
    is_deeply($vars->{record},$test_data->{edit2b},"base data provided, with photo given");


    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    # test basic admin
    $res = is($loader->action('Album::Photos::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{records}));
    is_deeply($vars->{records},$test_data->{admin1},'admin list variables are as expected');


    # save photo, without data
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Album::Photos::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},undef,'failed to saved');
    $res = is($loader->action('Album::Photos::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin2 vars=".Dumper($vars->{records}));
    is_deeply($vars->{records},$test_data->{admin1},'admin list variables are as expected');


    # update known photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { 'pageid' => 3, 'tagline' => 'Labyrinth', 'thumb' => 'thumb.png', 'image' => 'image.jpg', 'photoid' => 2 } );

    $res = is($loader->action('Album::Photos::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks_message},'Photo saved successfully.','successful save');
    $res = is($loader->action('Album::Photos::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin3 vars=".Dumper($vars->{records}));
    is_deeply($vars->{records},$test_data->{admin3},'admin list variables are as expected');
    

    # view known photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { 'photoid' => 2 } );

    $res = is($loader->action('Album::Photos::View'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("view1 vars=".Dumper($vars));
    is_deeply($vars->{photo},$test_data->{view1}{photo},'view1 photo variables are as expected');
    is_deeply($vars->{page},$test_data->{view1}{page},'view1 page variables are as expected');

    # view unknown photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { 'photoid' => 2999 } );

    $res = is($loader->action('Album::Photos::View'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("view2 vars=".Dumper($vars));
    is($vars->{errcode},'ERROR','admin list variables are as expected');


    # view random photo
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { irand1 => undef, irand2 => undef } );

    $res = is($loader->action('Album::Photos::Random'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("random1 vars=".Dumper($vars));
    ok( defined $vars->{irand1},'random photo irand1 variables are as expected');
    ok(!defined $vars->{irand2},'random photo irand1 variables not defined are as expected');

    # view random photos
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { irand1 => undef, irand2 => undef },
        {},
        { random => 2 } );

    $res = is($loader->action('Album::Photos::Random'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("random2 vars=".Dumper($vars));
    ok(defined $vars->{irand1},'random photo irand1 variables are as expected');
    ok(defined $vars->{irand2},'random photo irand1 variables are as expected');


    # view gallery
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    $res = is($loader->action('Album::Photos::Gallery'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("gallery1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{gallery1},'gallery1 variables are as expected');

    # view gallery for a start point
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 }, { start => 2 } );

    $res = is($loader->action('Album::Photos::Gallery'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("gallery2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{gallery2},'gallery2 variables are as expected');


    # list albums
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 }, { 'pages' => '2,3' } );

    $res = is($loader->action('Album::Photos::Albums'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("albums vars=".Dumper($vars));
    is_deeply($vars->{albums},$test_data->{albums},'albums variables are as expected');


    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # archive photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { photoid => 2 } );

    # test delete via admin
    $res = is($loader->action('Album::Photos::Archive'),1);
    diag($loader->error)    unless($res);
    is($vars->{thanks_message},'Photo archived successfully.','archived successful');

    
    # delete photo
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { photoid => 2 } );

    # test delete via admin
    $res = is($loader->action('Album::Photos::Archive'),1);
    diag($loader->error)    unless($res);
    is($vars->{thanks_message},'Photo deleted successfully.','deleted successful');
}
