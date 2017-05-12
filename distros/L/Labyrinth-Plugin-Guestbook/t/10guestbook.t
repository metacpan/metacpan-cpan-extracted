#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 42;

my $test_data = { 
    read => {
        'page' => 1,
        'realm' => 'public',
        'htmltags' => '+img',
        'requests' => 't/_DBDIR/cgi-bin/config/requests',
        'ipaddr' => '',
        'minpasslen' => '6',
        'webpath' => '',
        'timeout' => '3600',
        'autoguest' => '1',
        'randpicwidth' => '400',
        'maxpasslen' => '20',
        'data' => [
                    {
                      'entryid' => '1',
                      'city' => 'Manchester',
                      'url' => '',
                      'email' => 'foo@example.com',
                      'realname' => 'Foo',
                      'comments' => 'This is just a test',
                      'createdate' => '1283443612',
                      'country' => 'UK',
                      'publish' => '3',
                      'ipaddr' => '1.2.3.4',
                      'postdate' => 'Thursday, 02 September 2010 (5:06pm)'
                    },
                    {
                      'entryid' => '2',
                      'city' => 'Birmingham',
                      'url' => '',
                      'email' => 'bar@example.com',
                      'createdate' => '1283073463',
                      'comments' => 'This is another test',
                      'realname' => 'Bar',
                      'postdate' => 'Sunday, 29 August 2010 (10:17am)',
                      'publish' => '3',
                      'ipaddr' => '5.6.7.8',
                      'country' => 'UK'
                    }
                  ],
        'administrator' => 'admin@example.com',
        'lastpagereturn' => '0',
        'iname' => 'Test Site',
        'cgiroot' => 'http://example.com',
        'pages' => [
                     1
                   ],
        'prev' => undef,
        'cookiename' => 'session',
        'cgipath' => '/cgi-bin',
        'next' => undef,
        'basedir' => 't/_DBDIR',
        'blank' => 'images/blank.png',
        'host' => 'example.com',
        'webdir' => 't/_DBDIR/html',
        'icode' => 'testsite',
        'first' => 1,
        'script' => '',
        'mailhost' => '',
        'last' => 1,
        'docroot' => 'http://example.com',
        'testing' => '0',
        'evalperl' => '1',
        'maxpicwidth' => '500',
        'cgidir' => 't/_DBDIR/cgi-bin',
        'copyright' => '2013-2014 Me'
    },

    save1a => [
                    {
                      'entryid' => '1',
                      'city' => 'Manchester',
                      'url' => '',
                      'email' => 'foo@example.com',
                      'realname' => 'Foo',
                      'comments' => 'This is just a test',
                      'createdate' => '1283443612',
                      'country' => 'UK',
                      'publish' => '3',
                      'ipaddr' => '1.2.3.4',
                      'postdate' => 'Thursday, 02 September 2010 (5:06pm)'
                    },
                    {
                      'entryid' => '2',
                      'city' => 'Birmingham',
                      'url' => '',
                      'email' => 'bar@example.com',
                      'createdate' => '1283073463',
                      'comments' => 'This is another test',
                      'realname' => 'Bar',
                      'postdate' => 'Sunday, 29 August 2010 (10:17am)',
                      'publish' => '3',
                      'ipaddr' => '5.6.7.8',
                      'country' => 'UK'
                    }
    ],

    save1b => [
                    {
                      'entryid' => '1',
                      'city' => 'Manchester',
                      'url' => '',
                      'email' => 'foo@example.com',
                      'realname' => 'Foo',
                      'comments' => 'This is just a test',
                      'createdate' => '02/09/2010 17:06:52',
                      'country' => 'UK',
                      'publish' => '3',
                      'ipaddr' => '1.2.3.4'
                    },
                    {
                      'entryid' => '2',
                      'city' => 'Birmingham',
                      'url' => '',
                      'email' => 'bar@example.com',
                      'createdate' => '29/08/2010 10:17:43',
                      'comments' => 'This is another test',
                      'realname' => 'Bar',
                      'publish' => '3',
                      'ipaddr' => '5.6.7.8',
                      'country' => 'UK'
                    }
    ],

    save2 => [
                    {
                      'entryid' => '3',
                      'city' => 'Here',
                      'url' => '',
                      'email' => '',
                      'createdate' => '01/03/2015 16:41:31',
                      'comments' => 'Yet another test',
                      'realname' => 'Test User',
                      'publish' => undef,
                      'ipaddr' => '1.1.1.1',
                      'country' => 'UK'
                    },
                    {
                      'entryid' => '1',
                      'city' => 'Manchester',
                      'url' => '',
                      'email' => 'foo@example.com',
                      'realname' => 'Foo',
                      'comments' => 'This is just a test',
                      'createdate' => '02/09/2010 17:06:52',
                      'country' => 'UK',
                      'publish' => '3',
                      'ipaddr' => '1.2.3.4',
                    },
                    {
                      'entryid' => '2',
                      'city' => 'Birmingham',
                      'url' => '',
                      'email' => 'bar@example.com',
                      'comments' => 'This is another test',
                      'realname' => 'Bar',
                      'createdate' => '29/08/2010 10:17:43',
                      'publish' => '3',
                      'ipaddr' => '5.6.7.8',
                      'country' => 'UK'
                    }
    ],

    edit2 => {
                    'publish' => '3',
                    'realname' => 'Bar',
                    'city' => 'Birmingham',
                    'country' => 'UK',
                    'email' => 'bar@example.com',
                    'url' => '',
                    'comments' => 'This is another test',
                    'ipaddr' => '5.6.7.8',
                    'entryid' => '2',
                    'createdate' => '1283073463'
    },
    edit3 => {
                    'realname' => 'Baz',
                    'country' => 'UK',
                    'url' => '',
                    'entryid' => '2',
                    'createdate' => '1283073463',
                    'comments' => 'Yada Yada',
                    'city' => 'There',
                    'publish' => '3',
                    'email' => '',
                    'ipaddr' => '5.6.7.8'
    },
    update => {
                    'email' => '',
                    'createdate' => '1283073463',
                    'publish' => '3',
                    'realname' => 'Baz',
                    'guestpass' => '',
                    'url' => '',
                    'comments' => 'Yada Yada',
                    'country' => 'UK',
                    'entryid' => '2',
                    'city' => 'There',
                    'ipaddr' => '5.6.7.8'
    },

    admin1 => [
                       {
                         'createdate' => '01/03/2015 16:49:00',
                         'realname' => 'Test User',
                         'comments' => 'Yet another test',
                         'city' => 'Here',
                         'url' => '',
                         'email' => '',
                         'country' => 'UK',
                         'publish' => undef,
                         'entryid' => '3',
                         'ipaddr' => '1.1.1.1'
                       },
                       {
                         'realname' => 'Foo',
                         'createdate' => '02/09/2010 17:06:52',
                         'city' => 'Manchester',
                         'comments' => 'This is just a test',
                         'url' => '',
                         'email' => 'foo@example.com',
                         'country' => 'UK',
                         'publish' => '3',
                         'ipaddr' => '1.2.3.4',
                         'entryid' => '1'
                       },
                       {
                         'city' => 'Birmingham',
                         'comments' => 'This is another test',
                         'url' => '',
                         'createdate' => '29/08/2010 10:17:43',
                         'realname' => 'Bar',
                         'publish' => '3',
                         'country' => 'UK',
                         'ipaddr' => '5.6.7.8',
                         'entryid' => '2',
                         'email' => 'bar@example.com'
                       }
    ],

    'delete' => [
                       {
                         'entryid' => '3',
                         'country' => 'UK',
                         'realname' => 'Test User',
                         'url' => '',
                         'comments' => 'Yet another test',
                         'createdate' => '01/03/2015 17:08:51',
                         'city' => 'Here',
                         'publish' => undef,
                         'ipaddr' => '1.1.1.1',
                         'email' => ''
                       },
                       {
                         'realname' => 'Foo',
                         'url' => '',
                         'country' => 'UK',
                         'entryid' => '1',
                         'ipaddr' => '1.2.3.4',
                         'email' => 'foo@example.com',
                         'publish' => '3',
                         'createdate' => '02/09/2010 17:06:52',
                         'comments' => 'This is just a test',
                         'city' => 'Manchester'
                       }
    ],

};

my @plugins = qw(
    Labyrinth::Plugin::Guestbook
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
    skip "Unable to prep the test environment", 42  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Guestbook::Read'),1);
    diag($loader->error)    unless($res);

    my $vars = $loader->vars;
    #diag("read vars=".Dumper($vars));
    is_deeply($vars,$test_data->{read},'read variables are as expected');

    
    # refresh instance - save no loopback
    $loader->refresh(
        \@plugins,
        { loggedin => 0, data => undef },
        { realname => 'Test User', email => 'test@example.com', url => '', city => 'Here', country => 'UK', comments => 'Yet another test' },
        { ipaddr => '1.1.1.1' } );

    $res = is($loader->action('Guestbook::Save'),1);
    diag($loader->error)    unless($res);

    $res = is($loader->action('Guestbook::Read'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("save1a vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{save1a},'save variables are as expected');

    $loader->login( 2 );
    $res = is($loader->action('Guestbook::List'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("save1b vars=".Dumper($vars));
    is_deeply($vars->{records},$test_data->{save1b},'save variables are as expected');


    # refresh instance - save with loopback
    $loader->refresh(
        \@plugins,
        { loggedin => 0, data => undef },
        { realname => 'Test User', email => 'test@example.com', url => '', city => 'Here', country => 'UK', comments => 'Yet another test', loopback => '1.1.1.1' },
        { ipaddr => '1.1.1.1' } );

    $res = is($loader->action('Guestbook::Save'),1);
    diag($loader->error)    unless($res);

    $res = is($loader->action('Guestbook::Read'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("save2a vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{save1a},'save variables are as expected');

    $loader->login( 2 );
    $res = is($loader->action('Guestbook::List'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("save2b vars=".Dumper($vars));
    for my $inx (1 .. scalar @{ $vars->{records} }) {
        $test_data->{save2}[$inx-1]{$_} = $vars->{records}[$inx-1]{$_}  for(qw(createdate));
    }
    is_deeply($vars->{records},$test_data->{save2},'save variables are as expected');


    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 1, data => undef } );

    # test bad access to admin
    for my $call (
            'Guestbook::List',  'Guestbook::MultiBlock',    'Guestbook::Block',
            'Guestbook::Allow', 'Guestbook::Approve',       'Guestbook::Delete',
            'Guestbook::Edit',  'Guestbook::Update'
        ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Edit - no page given
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 2 );

    $res = is($loader->action('Guestbook::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars));
    is_deeply($vars->{data},undef,"no entry data provided, when no page given");


    # Edit - missing page given
    $loader->refresh( \@plugins, { data => undef }, { entryid => 2 } );
    $loader->login( 2 );

    $res = is($loader->action('Guestbook::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit2},"page 2 data provided, with no reordering");

    
    # Admin access
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 2 );

    # test basic admin
    $res = is($loader->action('Guestbook::List'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars));
    is_deeply($vars->{records},$test_data->{save2},'admin list variables are as expected');


    # Update an entry
    $loader->refresh( \@plugins, 
        { records => undef, data => undef, errcode => '' },
        { entryid => 2, realname => 'Baz', email => 'baz@example.com', url => '', city => 'There', country => 'UK', comments => 'Yada Yada' } );
    $loader->login( 2 );

    $res = is($loader->action('Guestbook::Update'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("update vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{update},'update list variables are as expected');

    $loader->refresh( \@plugins, { data => undef }, { entryid => 2 } );
    $loader->login( 2 );

    $res = is($loader->action('Guestbook::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit3},"edit entry data provided");

    
    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # refresh instance
    $loader->refresh( \@plugins, { records => undef }, { LISTED => 1 } );
    $loader->login( 2 );

    # test delete via admin
    $res = is($loader->action('Guestbook::Delete'),1);
    diag($loader->error)    unless($res);

    # test delete via admin
    $loader->refresh( \@plugins, { records => undef } );
    $loader->login( 2 );

    $res = is($loader->action('Guestbook::List'),1);
    diag($loader->error)    unless($res);
    
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    for my $inx (1 .. scalar @{ $vars->{records} }) {
        $test_data->{delete}[$inx-1]{$_} = $vars->{records}[$inx-1]{$_}  for(qw(createdate));
    }
    is_deeply($vars->{records},$test_data->{delete},'entry 1 removed as expected');
}
