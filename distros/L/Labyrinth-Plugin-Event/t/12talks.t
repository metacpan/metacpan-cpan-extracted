#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Plugin::Event::Talks;
use Labyrinth::Test::Harness;
use Test::More tests => 39;

my $test_data = { 
    add => {
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1">Barbie (Barbie)</option><option value="2">guest (Guest)</option></select>',
        'ddevents' => '<select id="eventid" name="eventid"><option value="1">1-3 January 2011 - Test Conference</option></select>'
    },
    edit1 => {
        'ddevents' => '<select id="eventid" name="eventid"><option value="1">1-3 January 2011 - Test Conference</option></select>',
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1">Barbie (Barbie)</option><option value="2">guest (Guest)</option></select>'
    },
    edit2 => {
        'eventid' => '1',
        'address' => 'More details soon',
        'type' => '1',
        'userid' => '1',
        'folderid' => '1',
        'title' => 'Test Conference',
        'publish' => '3',
        'extralink' => undef,
        'href' => undef,
        'link' => 'images/blank.png',
        'venue' => 'To Be Confirmed',
        'ddevents' => '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>',
        'links' => 'web links here',
        'listdate' => '1293840000',
        'addresslink' => '',
        'venueid' => '1',
        'tag' => undef,
        'body' => '<p>This is a test',
        'resourced' => undef,
        'align' => '1',
        'abstracted' => undef,
        'eventdate' => '1-3 January 2011',
        'eventtime' => 'all day',
        'venuelink' => '',
        'sponsor' => 'Miss Barbell Productions',
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1" selected="selected">Barbie (Barbie)</option><option value="2">guest (Guest)</option></select>',
        'info' => '',
        'eventtype' => 'Conference',
        'eventtypeid' => '1',
        'imageid' => '1',
        'sponsorlink' => 'http://www.missbarbell.co.uk',
        'sponsorid' => '1',
        'dimensions' => undef,
        'talks' => '1'
    },
    edit3 => {
        'ddevents' => '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>',
        'abstract' => '<p>Abstract Here</p>',
        'resourced' => '<p>No Resources</p>',
        'eventdate' => '1-3 January 2011',
        'talkid' => '1',
        'realname' => 'Barbie',
        'talktitle' => 'Title To Be Confirmed',
        'abstracted' => '<p>Abstract Here</p>',
        'eventid' => '1',
        'guest' => '1',
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1" selected="selected">Barbie (Barbie)</option><option value="2">guest (Guest)</option></select>',
        'resource' => '<p>No Resources</p>',
        'title' => 'Test Conference',
        'userid' => '1'
    },
    edit4 => {
        'title' => 'Test Conference',
        'eventdate' => '1-3 January 2011',
        'abstracted' => 'blah blah blah',
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1" selected="selected">Barbie (Barbie)</option><option value="2">guest (Guest)</option></select>',
        'userid' => '1',
        'eventid' => '1',
        'talktitle' => 'A New Talk',
        'realname' => 'Barbie',
        'guest' => '0',
        'ddevents' => '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>',
        'talkid' => '2',
        'abstract' => 'blah blah blah',
        'resource' => '',
        'resourced' => ''
    },
    edit5 => {
        'userid' => '2',
        'ddusers' => '<select id="Speaker" name="Speaker"><option value="1">Barbie (Barbie)</option><option value="2" selected="selected">guest (Guest)</option></select>',
        'eventdate' => '1-3 January 2011',
        'title' => 'Test Conference',
        'abstracted' => 'blah blah blah',
        'talkid' => '2',
        'ddevents' => '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>',
        'resource' => '',
        'resourced' => '',
        'abstract' => 'blah blah blah',
        'realname' => 'guest',
        'guest' => '1',
        'talktitle' => 'A Guest Talk',
        'eventid' => '1'
    },
    admin1 => [ {
          'userid' => '1',
          'eventdate' => '1-3 January 2011',
          'eventid' => '1',
          'talktitle' => 'Title To Be Confirmed',
          'realname' => 'Barbie',
          'guest' => '1',
          'abstract' => '<p>Abstract Here</p>',
          'title' => 'Test Conference',
          'resource' => '<p>No Resources</p>',
          'talkid' => '1'
    } ],
    admin2 => [
        {
            'title' => 'Test Conference',
            'guest' => '1',
            'eventdate' => '1-3 January 2011',
            'userid' => '1',
            'resource' => '<p>No Resources</p>',
            'talktitle' => 'Title To Be Confirmed',
            'realname' => 'Barbie',
            'eventid' => '1',
            'abstract' => '<p>Abstract Here</p>',
            'talkid' => '1'
        },
        {
            'talktitle' => 'A Guest Talk',
            'realname' => 'guest',
            'abstract' => 'blah blah blah',
            'eventid' => '1',
            'talkid' => '2',
            'title' => 'Test Conference',
            'guest' => '1',
            'eventdate' => '1-3 January 2011',
            'resource' => '',
            'userid' => '2'
        }
    ],
    admin3 => [ {
        'talkid' => '2',
        'eventid' => '1',
        'title' => 'Test Conference',
        'talktitle' => 'A Guest Talk',
        'guest' => '1',
        'eventdate' => '1-3 January 2011',
        'resource' => '',
        'abstract' => 'blah blah blah',
        'realname' => 'guest',
        'userid' => '2'
    } ]
};

my @plugins = qw(
    Labyrinth::Plugin::Event::Talks
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
    skip "Unable to prep the test environment", 39  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Admin Link methods

    my $vars;

    # test bad access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 2 } );

    # test bad access to admin
    for my $call ( 'Event::Talks::Admin', 'Event::Talks::Add', 'Event::Talks::Edit', 'Event::Talks::Save', 'Event::Talks::Delete' ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Add a sponsor
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Add'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{add},'add variables are as expected');


    # Edit - no data given
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit1},"base data provided, when no talk given");


    # Edit - missing data given
    $loader->refresh( \@plugins, { data => undef }, { eventid => 1, talkid => 9 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit2},"talk 9 data provided");

    
    # Edit - valid data given, without event
    $loader->refresh( \@plugins, { data => {} }, { eventid => 0, talkid => 1 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit3},"talk 1 data provided");

    
    # Edit - valid data given
    $loader->refresh( \@plugins, { data => {} }, { eventid => 1, talkid => 1 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit3},"talk 1 data provided");

    
    # Admin access
    $loader->refresh( \@plugins, { data => {} } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Talks::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin list variables are as expected');


    # Save a new sponsor
    $loader->refresh( \@plugins, { data => {}, errcode => '' },
        { eventid => 1, talkid => 0, userid => 1, guest => 0, talktitle => 'A New Talk', abstract => 'blah blah blah', resources => '' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, { data => {}, errcode => '' });

    $res = is($loader->action('Event::Talks::Save'),1);
    diag($loader->error)    unless($res);
    my $params = $loader->params;
    is($params->{talkid},2);

    $loader->refresh( \@plugins, { data => {} }, { eventid => 1, talkid => 2 } );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save1 edit4 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit4},'admin list variables are as expected');

    # Update an existing sponsor
    $loader->refresh( \@plugins, { data => {} },
        { eventid => 1, talkid => 2, userid => 2, guest => 1, talktitle => 'A Guest Talk', abstract => 'blah blah blah', resources => '' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, { data => {}, errcode => '' });

    $res = is($loader->action('Event::Talks::Save'),1);
    diag($loader->error)    unless($res);

    $loader->refresh( \@plugins, { data => {} }, { eventid => 1, talkid => 2 } );
    $res = is($loader->action('Event::Talks::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save2 edit5 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit5},'admin list variables are as expected');


    # -------------------------------------------------------------------------
    # Select method
    
    is(Labyrinth::Plugin::Event::Talks->EventSelect(1),      '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>');
    is(Labyrinth::Plugin::Event::Talks->EventSelect(1,1),    '<select id="eventid" name="eventid"><option value="0">Select Event</option><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>');
    is(Labyrinth::Plugin::Event::Talks->EventSelect(1,0),    '<select id="eventid" name="eventid"><option value="1" selected="selected">1-3 January 2011 - Test Conference</option></select>');
    is(Labyrinth::Plugin::Event::Talks->EventSelect(undef,1),'<select id="eventid" name="eventid"><option value="0">Select Event</option><option value="1">1-3 January 2011 - Test Conference</option></select>');
    is(Labyrinth::Plugin::Event::Talks->EventSelect(undef,0),'<select id="eventid" name="eventid"><option value="1">1-3 January 2011 - Test Conference</option></select>');

    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # test delete via adminEventSelect
    $res = is($loader->action('Event::Talks::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete before vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin2},'reduced admin list as expected');

    # refresh instance
    $loader->refresh( \@plugins, { data => {} }, { doaction => 'Delete', LISTED => [ 1 ] } );
    $loader->login( 1 );

    # test delete via adminEventSelect
    $res = is($loader->action('Event::Talks::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete after vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin3},'reduced admin list as expected');
}
