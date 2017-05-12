#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Plugin::Event::Sponsors;
use Labyrinth::Test::Harness;
use Test::More tests => 34;

my $test_data = { 
    public => [
        {
             'venue' => 'Venue A',
             'venueid' => 2
        },
        {
             'venueid' => 1,
             'venue' => 'Venue Z'
        }

    ],
    edit1 => undef,
    edit2 => undef,
    edit3 => {
        'venue' => 'To Be Confirmed',
        'addresslink' => '',
        'venueid' => '1',
        'address' => 'More details soon',
        'info' => '',
        'venuelink' => ''
    },
    edit4 => {
        'venue' => 'A New Venue',
        'address' => 'Here',
        'info' => 'Blah',
        'venuelink' => 'http://venue.example.com',
        'addresslink' => 'http://address.example.com',
        'venueid' => '2'
    },
    edit5 => {
        'venue' => 'A Different Venue',
        'address' => 'There',
        'info' => 'Yada',
        'venuelink' => 'http://venue2.example.com',
        'addresslink' => 'http://address2.example.com',
        'venueid' => '2'
    },
    admin1 => [ {
        'venue' => 'To Be Confirmed',
        'addresslink' => '',
        'venueid' => '1',
        'info' => '',
        'address' => 'More details soon',
        'venuelink' => ''
    } ],
    admin2 => [ {
    } ]
};

my @plugins = qw(
    Labyrinth::Plugin::Event::Venues
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
    skip "Unable to prep the test environment", 34  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    # Current
    $loader->clear;
    $loader->refresh( \@plugins, { future => [ { venueid => 1, venue => 'Venue Z' }, { venueid => 2, venue => 'Venue A' } ] } );
    $res = is($loader->action('Event::Venues::Current'),1);
    diag($loader->error)    unless($res);
    my $vars = $loader->vars;
    #diag("venues vars=".Dumper($vars->{venues}));
    is_deeply($vars->{venues},$test_data->{public},'reduced admin list as expected');

    
    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access to admin
    $loader->clear;
    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2 } );
    for my $call ( 'Event::Venues::Admin', 'Event::Venues::Add', 'Event::Venues::Edit', 'Event::Venues::Save', 'Event::Venues::Delete' ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Add a venue
    $loader->clear;
    $loader->refresh( \@plugins, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Add'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},{},'add variables are as expected');


    # Edit - no data given
    $loader->clear;
    $loader->refresh( \@plugins, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit1},"base data provided, when no sponsor given");


    # Edit - missing data given
    $loader->clear;
    $loader->refresh( \@plugins, {}, { venueid => 3 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit2},"venue 3 data provided");

    
    # Edit - valid data given
    $loader->clear;
    $loader->refresh( \@plugins, {}, { venueid => 1 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit3 vars=".Dumper($vars));
    is_deeply($vars->{data},$test_data->{edit3},"venue 1 data provided");

    
    # Admin access
    $loader->clear;
    $loader->refresh( \@plugins, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin list variables are as expected');


    # Save a new sponsor
    $loader->clear;
    $loader->refresh( \@plugins, {},
        { venueid => 0, venue => 'A New Venue', venuelink => 'http://venue.example.com', address => 'Here', addresslink => 'http://address.example.com', info => 'Blah' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, { data => {}, errcode => '' });
    $res = is($loader->action('Event::Venues::Save'),1);
    diag($loader->error)    unless($res);
    my $params = $loader->params;
    is($params->{venueid},2,'created new venue');

    $loader->clear;
    $loader->refresh( \@plugins, {}, { venueid => 2 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save1 edit4 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit4},'admin list variables are as expected');

    # Update an existing sponsor
    $loader->clear;
    $loader->refresh( \@plugins, {},
        { venueid => 2, venue => 'A Different Venue', venuelink => 'http://venue2.example.com', address => 'There', addresslink => 'http://address2.example.com', info => 'Yada' } );
    $loader->login( 1 );
    $loader->refresh( \@plugins, {} );
    $res = is($loader->action('Event::Venues::Save'),1);
    diag($loader->error)    unless($res);

    $loader->clear;
    $loader->refresh( \@plugins, {}, { venueid => 2 } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save2 edit5 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit5},'admin list variables are as expected');


    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # test base admin
    $loader->clear;
    $loader->refresh( \@plugins, {}, {} );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    is(scalar(@{ $vars->{data} }),2,'start admin as expected');

    # test delete via admin
    $loader->clear;
    $loader->refresh( \@plugins, {}, { doaction => 'Delete', LISTED => [ 1 ] } );
    $loader->login( 1 );
    $res = is($loader->action('Event::Venues::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    is(scalar(@{ $vars->{data} }),1,'delete admin as expected');

}
