#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 60;

my (undef,undef,undef,undef,undef,$year) = localtime(time);
$year += 1900;

my $test_vars = {
   'testing' => '0',
   'copyright' => '2013-2014 Me',
   'cgiroot' => 'http://example.com',
   'ddmonths' => '<select id="month" name="month"><option value="0">Select Month</option><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
   'administrator' => 'admin@example.com',
   'pid' => 4,
   'timeout' => '3600',
   'docroot' => 'http://example.com',
   'iname' => 'Test Site',
   'blank' => 'images/blank.png',
   'cookiename' => 'session',
   'webdir' => 't/_DBDIR/html',
   'iid' => 0,
   'ipaddr' => '',
   'cgidir' => 't/_DBDIR/cgi-bin',
   'maxpicwidth' => '500',
   'htmltags' => '+img',
   'webpath' => '',
   'month' => '',
   'lastpagereturn' => '0',
   'autoguest' => '1',
   'realm' => 'public',
   'mailhost' => '',
   'maxpasslen' => '20',
   'minpasslen' => '6',
   'script' => '',
   'requests' => 't/_DBDIR/cgi-bin/config/requests',
   'cgipath' => '/cgi-bin',
   'basedir' => 't/_DBDIR',
   'host' => 'example.com',
   'icode' => 'testsite',
   'ddyears' => qq'<select id="year" name="year"><option value="0">Select Year</option><option value="$year" selected="selected">$year</option></select>',
   'evalperl' => '1',
   'randpicwidth' => '400',
   'year' => $year
};

my $test_data = { 
    add => {
       'ddmonths' => '<select id="month" name="month"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
       'ddyears' => qq'<select id="year" name="year"><option value="$year">$year</option></select>',
       'senarios' => [
                       {
                         'title' => 'Photos Section',
                         'id' => 2
                       }
                     ]
    },

    edit1 => {
       'writeable' => 0,
       'senarios' => [
                       {
                         'title' => 'Photos Section',
                         'id' => 2
                       }
                     ],
       'directory' => 0,
       'ddmonths' => '<select id="month" name="month"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
       'ddpages' => '<select id="parent" name="parent"><option value="0">Select Gallery Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="2">Home Page</option><option value="1">Archive</option></select>',
       'executable' => 0,
       'ddyears' => qq'<select id="year" name="year"><option value="$year">$year</option></select>',
       'exists' => 0,
       'readable' => 0
    },
    edit2 => {
        'month' => '8',
        'area' => '1',
        'directory' => 0,
        'ddmonths' => '<select id="month" name="month"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8" selected="selected">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
        'ddpages' => '<select id="parent" name="parent"><option value="0">Select Gallery Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="2">Home Page</option><option value="1">Archive</option></select>',
        'summary' => '',
        'executable' => 0,
        'pageid' => '3',
        'readable' => 0,
        'parent' => '',
        'writeable' => 0,
        'path' => 'photos/20050830',
        'hide' => '',
        'ddyears' => qq'<select id="year" name="year"><option value="$year">$year</option></select>',
        'title' => 'Test Page',
        'orderno' => '0',
        'exists' => 0,
        'year' => '2005'
    },
    edit3 => {
        'month' => '8',
        'area' => '1',
        'directory' => 0,
        'ddmonths' => '<select id="month" name="month"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8" selected="selected">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
        'ddpages' => '<select id="parent" name="parent"><option value="0">Select Gallery Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="2">Home Page</option><option value="1">Archive</option></select>',
        'summary' => '',
        'executable' => 0,
        'pageid' => '3',
        'readable' => 0,
        'parent' => '',
        'writeable' => 0,
        'path' => 'photos/20050830',
        'hide' => '',
        'ddyears' => qq'<select id="year" name="year"><option value="$year">$year</option></select>',
        'title' => 'Test Page',
        'orderno' => '0',
        'exists' => 0,
        'year' => '2005'
    },

    photos1 => {
    },
    photos2 => [
        {
          'dimensions' => '800x600',
          'photoid' => '1',
          'thumb' => '20050830/dscf5903-thumb.jpg',
          'image' => '20050830/dscf5903.jpg',
          'tagline' => undef,
          'cover' => '1',
          'hide' => '0',
          'pageid' => '3',
          'metadata' => 'Labyrinth Test',
          'orderno' => '1'
        },
        {
          'dimensions' => '800x600',
          'photoid' => '2',
          'thumb' => '20050830/dscf5904-thumb.jpg',
          'image' => '20050830/dscf5904.jpg',
          'tagline' => undef,
          'cover' => '0',
          'hide' => '0',
          'pageid' => '3',
          'metadata' => 'Labyrinth',
          'orderno' => '2'
        }
    ],
    photos3 => [
        {
          'dimensions' => '800x600',
          'photoid' => '2',
          'thumb' => '20050830/dscf5904-thumb.jpg',
          'image' => '20050830/dscf5904.jpg',
          'tagline' => undef,
          'cover' => '0',
          'hide' => '0',
          'pageid' => '3',
          'metadata' => 'Labyrinth',
          'orderno' => '1'
        },
        {
          'dimensions' => '800x600',
          'photoid' => '1',
          'thumb' => '20050830/dscf5903-thumb.jpg',
          'image' => '20050830/dscf5903.jpg',
          'tagline' => undef,
          'cover' => '1',
          'hide' => '0',
          'pageid' => '3',
          'metadata' => 'Labyrinth Test',
          'orderno' => '2'
        }
    ],

    admin1 => {
        'month' => '8',
        'area' => '1',
        'directory' => 0,
        'ddmonths' => '<select id="month" name="month"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8" selected="selected">August</option><option value="9">September</option><option value="10">October</option><option value="11">November</option><option value="12">December</option></select>',
        'ddpages' => '<select id="parent" name="parent"><option value="0">Select Gallery Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="2">Home Page</option><option value="1">Archive</option></select>',
        'summary' => '',
        'executable' => 0,
        'pageid' => '3',
        'readable' => 0,
        'parent' => '',
        'writeable' => 0,
        'path' => 'photos/20050830',
        'hide' => '',
        'ddyears' => qq'<select id="year" name="year"><option value="$year">$year</option></select>',
        'title' => 'Test Page',
        'orderno' => '0',
        'exists' => 0,
        'year' => '2005'
    },
    admin2 => {
        'parent' => 0,
        'area' => 2,
        'month' => '10',
        'path' => 'photos/20141112T215303',
        'summary' => 'blah',
        'hide' => 0,
        'pageid' => '6',
        'title' => 'A New Page',
        'year' => '2014'
    },
    admin3 => {
        'parent' => 0,
        'area' => 2,
        'month' => '1',
        'path' => 'photos/20050830',
        'summary' => 'blah blah',
        'hide' => 1,
        'pageid' => '2',
        'title' => 'An Updated Page',
        'orderno' => '2',
        'year' => '2012'
    },
    admin4 => {
       'parent' => 0,
       'area' => 2,
       'month' => '11',
       'path' => 'photos/20141111T205337',
       'summary' => '',
       'hide' => 0,
       'pageid' => '3',
       'title' => 'Labyrinth2',
       'orderno' => '0',
       'year' => '2014'
    },
    'children2' => {
        'children' => [
            {
                'orderno' => '3',
                'summary' => '',
                'title' => 'Test Sub Page 1',
                'month' => '8',
                'area' => '1',
                'hide' => '0',
                'parent' => '3',
                'path' => 'photos/20050830',
                'pageid' => '4',
                'year' => '2005'
            },
            {
                'year' => '2005',
                'path' => 'photos/20050830',
                'pageid' => '5',
                'parent' => '3',
                'hide' => '0',
                'month' => '8',
                'area' => '1',
                'title' => 'Test Sub Page 2',
                'orderno' => '4',
                'summary' => ''
            }
        ]
    },
};

my @plugins = qw(
    Labyrinth::Plugin::Album::Pages
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
    skip "Unable to prep the test environment", 60  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Album::Pages::List'),1);
    diag($loader->error)    unless($res);

    my $vars = $loader->vars;
    #diag("vars=".Dumper($vars));
    is_deeply($vars,$test_vars,'list variables are as expected');

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 2 } );

    # test bad access to admin
    for my $call ('Album::Pages::Admin','Album::Pages::Add','Album::Pages::ArchiveEdit','Album::Pages::Edit','Album::Pages::Save','Album::Pages::Delete') {
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
    $res = is($loader->action('Album::Pages::Add'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{add},'add variables are as expected');


    # no page given
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    $res = is($loader->action('Album::Pages::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit1},"base data provided, when no page given");
    #diag("photos1 vars=".Dumper($vars->{photos}));
    is($vars->{photos},undef,"base data provided, when no page given");


    # basic page given
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { pageid => 3 } );

    $res = is($loader->action('Album::Pages::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit2},"page 2 data provided, with no reordering");
    #diag("photos2 vars=".Dumper($vars->{photos}));
    is_deeply($vars->{photos},$test_data->{photos2},"base data provided, when no page given");

    
    # reorder photo up
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { pageid => 3, order => 'up', photoid => 2 } );

    $res = is($loader->action('Album::Pages::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit3},"page 2 data provided, photo up");
    #diag("photos3 vars=".Dumper($vars->{photos}));
    is_deeply($vars->{photos},$test_data->{photos3},"base data provided, when no page given");


    # reorder photo down
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { pageid => 3, order => 'down', photoid => 2 } );

    $res = is($loader->action('Album::Pages::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit2},"page 2 data provided, photo down");
    #diag("photos2 vars=".Dumper($vars->{photos}));
    is_deeply($vars->{photos},$test_data->{photos2},"base data provided, when no page given");


    # Admin access
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    # test basic admin
    $res = is($loader->action('Album::Pages::Admin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin list variables are as expected');


    # Save a new page
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { 'title' => 'A New Page', 'summary' => 'blah', 'year' => '2014', month => 10, hide => 0, pageid => 0, parent => 0 } );

    $res = is($loader->action('Album::Pages::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks_message},'Page saved successfully.','saved successfully');

    $res = is($loader->action('Album::Pages::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{admin2}{path} = $vars->{data}{path};
    like($vars->{data}{path},qr!^photos/\d{8}T\d{6}!);
    #diag("admin2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin2},'admin list variables are as expected');

    # Update an existing page
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { 'title' => 'An Updated Page', 'summary' => 'blah blah', 'year' => '2012', month => 1, hide => 1, pageid => 2, parent => 0 } );

    $res = is($loader->action('Album::Pages::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks_message},'Page saved successfully.','saved successfully');

    $res = is($loader->action('Album::Pages::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin3 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin3},'admin list variables are as expected');


    # Page Selection
    $loader->clear;
    $loader->refresh( \@plugins );
    $res = is($loader->action('Album::Pages::Selection'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("selection1 vars=".Dumper($vars->{ddpages}));
    is($vars->{ddpages},'<select id="pageid" name="pageid"><option value="0">Select Gallery Page</option><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1" selected="selected">Archive</option></select>');

    # Named Page Selection
    $loader->clear;
    $loader->refresh( \@plugins, { data => { pageid => 3 } } );
    $res = is($loader->action('Album::Pages::Selection'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("selection2 vars=".Dumper($vars->{ddpages}));
    is($vars->{ddpages},'<select id="pageid" name="pageid"><option value="0">Select Gallery Page</option><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3" selected="selected">Test Page</option><option value="1">Archive</option></select>');


    # drop downs
    is(Labyrinth::Plugin::Album::Pages::PageSelect(),       '<select id="pageid" name="pageid"><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(1),      '<select id="pageid" name="pageid"><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1" selected="selected">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(1,1),    '<select id="pageid" name="pageid"><option value="0">Select Gallery Page</option><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1" selected="selected">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(1,0),    '<select id="pageid" name="pageid"><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1" selected="selected">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(undef,1),'<select id="pageid" name="pageid"><option value="0">Select Gallery Page</option><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(undef,0),'<select id="pageid" name="pageid"><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1">Archive</option></select>');

    is(Labyrinth::Plugin::Album::Pages::PageSelect(undef,0,'albumid'),      '<select id="albumid" name="albumid"><option value="6">A New Page</option><option value="2">An Updated Page</option><option value="5">Test Sub Page 2</option><option value="4">Test Sub Page 1</option><option value="3">Test Page</option><option value="1">Archive</option></select>');
    is(Labyrinth::Plugin::Album::Pages::PageSelect(undef,0,'albumid',2,4,5),'<select id="albumid" name="albumid"><option value="6">A New Page</option><option value="3">Test Page</option><option value="1">Archive</option></select>');
 

    # Children - no children
    $loader->clear;
    $loader->refresh( \@plugins, {}, { pageid => 2 } );
    $res = is($loader->action('Album::Pages::Children'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("children1 vars=".Dumper($vars));
    is_deeply($vars->{album},undef,'children1 variables are as expected');

    # Children - with children
    $loader->clear;
    $loader->refresh( \@plugins, {}, { pid => 3 } );
    $res = is($loader->action('Album::Pages::Children'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("children2 vars=".Dumper($vars));
    is_deeply($vars->{album},$test_data->{children2},'children2 variables are as expected');

    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef, thanks_message => undef },
        { pageid => 2 } );

    # test delete via admin
    $res = is($loader->action('Album::Pages::Delete'),1);
    diag($loader->error)    unless($res);
    is($vars->{thanks_message},undef,'deleted successfully');

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef, thanks_message => undef },
        { pageid => 3 } );

    # test delete via admin
    $res = is($loader->action('Album::Pages::Delete'),1);
    diag($loader->error)    unless($res);
    is($vars->{thanks_message},'Page deleted successfully.','deleted successfully');
}
