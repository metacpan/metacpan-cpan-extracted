#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Plugin::Event::Sponsors;
use Labyrinth::Test::Harness;
use Test::More tests => 36;

my $test_data = { 
    add => {
        'sponsorlink' => '',
        'sponsor' => 'Sponsor'
    },
    edit1 => undef,
    edit2 => undef,
    edit3 => {
        'sponsor' => 'Miss Barbell Productions',
        'sponsorlink' => 'http://www.missbarbell.co.uk',
        'sponsorid' => '1'
    },
    edit4 => {
        'sponsor' => 'A New Sponsor',
        'sponsorid' => '2',
        'sponsorlink' => 'http://sponsor.example.com'
    },
    edit5 => {
        'sponsor' => 'A Different Sponsor',
        'sponsorid' => '2',
        'sponsorlink' => 'http://another.example.com'
    },
    admin1 => [ {
        'sponsor' => 'Miss Barbell Productions',
        'sponsorlink' => 'http://www.missbarbell.co.uk',
        'sponsorid' => '1'
    } ],
    admin2 => [ {
        'sponsorlink' => 'http://another.example.com',
        'sponsorid' => '2',
        'sponsor' => 'A Different Sponsor'
    } ]
};

my @plugins = qw(
    Labyrinth::Plugin::Event::Sponsors
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
    skip "Unable to prep the test environment", 36  unless($res);

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
    for my $call ( 'Event::Sponsors::Admin', 'Event::Sponsors::Add', 'Event::Sponsors::Edit', 'Event::Sponsors::Save', 'Event::Sponsors::Delete' ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Add a sponsor
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 1 );

    # test adding a sponsor
    $res = is($loader->action('Event::Sponsors::Add'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{add},'add variables are as expected');


    # Edit - no data given
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 1 );

    $res = is($loader->action('Event::Sponsors::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit1},"base data provided, when no sponsor given");


    # Edit - missing data given
    $loader->refresh( \@plugins, { data => undef }, { sponsorid => 3 } );
    $loader->login( 1 );

    $res = is($loader->action('Event::Sponsors::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit2},"sponsor 3 data provided");

    
    # Edit - valid data given
    $loader->refresh( \@plugins, { data => {} }, { sponsorid => 1 } );
    $loader->login( 1 );

    $res = is($loader->action('Event::Sponsors::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit3},"sponsor 1 data provided");

    
    # Admin access
    $loader->refresh( \@plugins, { data => {} } );
    $loader->login( 1 );

    # test basic admin
    $res = is($loader->action('Event::Sponsors::Admin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin list variables are as expected');


    # Save a new sponsor
    $loader->refresh( \@plugins, { data => {}, errcode => '' },
        { sponsorid => 0, 'sponsor' => 'A New Sponsor', 'sponsorlink' => 'http://sponsor.example.com' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, { data => {}, errcode => '' });

    $res = is($loader->action('Event::Sponsors::Save'),1);
    diag($loader->error)    unless($res);
    my $params = $loader->params;
    is($params->{sponsorid},2);

    $loader->refresh( \@plugins, { data => {} }, { sponsorid => 2 } );
    $res = is($loader->action('Event::Sponsors::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save1 edit4 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit4},'admin list variables are as expected');

    # Update an existing sponsor
    $loader->refresh( \@plugins, { data => {} },
        { sponsorid => 2, 'sponsor' => 'A Different Sponsor', 'sponsorlink' => 'http://another.example.com' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, { data => {}, errcode => '' });

    $res = is($loader->action('Event::Sponsors::Save'),1);
    diag($loader->error)    unless($res);

    $loader->refresh( \@plugins, { data => {} }, { sponsorid => 2 } );
    $res = is($loader->action('Event::Sponsors::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save2 edit5 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit5},'admin list variables are as expected');


    # -------------------------------------------------------------------------
    # Select method
    
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(),       '<select id="sponsorid" name="sponsorid"><option value="2">A Different Sponsor</option><option value="1">Miss Barbell Productions</option></select>');
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(1),      '<select id="sponsorid" name="sponsorid"><option value="2">A Different Sponsor</option><option value="1" selected="selected">Miss Barbell Productions</option></select>');
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(1,1),    '<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="2">A Different Sponsor</option><option value="1" selected="selected">Miss Barbell Productions</option></select>');
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(1,0),    '<select id="sponsorid" name="sponsorid"><option value="2">A Different Sponsor</option><option value="1" selected="selected">Miss Barbell Productions</option></select>');
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(undef,1),'<select id="sponsorid" name="sponsorid"><option value="0">Select Sponsor</option><option value="2">A Different Sponsor</option><option value="1">Miss Barbell Productions</option></select>');
    is(Labyrinth::Plugin::Event::Sponsors->SponsorSelect(undef,0),'<select id="sponsorid" name="sponsorid"><option value="2">A Different Sponsor</option><option value="1">Miss Barbell Productions</option></select>');

    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # refresh instance
    $loader->refresh( \@plugins, { data => {} }, { doaction => 'Delete', LISTED => [ 1 ] } );
    $loader->login( 1 );

    # test delete via admin
    $res = is($loader->action('Event::Sponsors::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin2},'reduced admin list as expected');
}
