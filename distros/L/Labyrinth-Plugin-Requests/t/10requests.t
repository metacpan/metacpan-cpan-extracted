#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 53;

my $test_data = { 
    add => {
        'secure' => 1,
        'ddsecure' => '<select id="typeid" name="typeid"><option value="1" selected="selected">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>',
        'rewrite' => '',
        'onsuccess' => '',
        'onerror' => '',
        'command' => '',
        'onfailure' => '',
        'layout' => '',
        'section' => '',
        'content' => '',
        'actions' => ''
    },

    edit1 => {
        'secure' => 1,
        'ddsecure' => '<select id="typeid" name="typeid"><option value="1" selected="selected">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>',
        'rewrite' => '',
        'onsuccess' => '',
        'onerror' => '',
        'command' => '',
        'onfailure' => '',
        'layout' => '',
        'section' => '',
        'content' => '',
        'actions' => ''
    },
    edit2 => {
        'rewrite' => '',
        'content' => '',
        'onsuccess' => '',
        'onerror' => '',
        'command' => 'public',
        'onfailure' => '',
        'ddsecure' => '<select id="typeid" name="typeid"><option value="1">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>',
        'actions' => 'Content::GetVersion,Hits::SetHits,Menus::LoadMenus',
        'section' => 'realm',
        'requestid' => '3',
        'layout' => 'public/layout.html',
        'secure' => 'off'
    },

    admin1 => {
          'section' => 'arts',
          'rewrite' => '',
          'requestid' => '36',
          'onsuccess' => '',
          'actions' => 'Site::Add',
          'secure' => 'off',
          'content' => 'articles/arts-adminedit.html',
          'onerror' => '',
          'onfailure' => '',
          'layout' => '',
          'secured' => undef,
          'command' => 'add'
    },
    admin2 => {
          'onfailure' => '',
          'secure' => '',
          'section' => 'aaaa',
          'layout' => '',
          'requestid' => '61',
          'rewrite' => '',
          'content' => '',
          'actions' => 'AAAA::AAAA',
          'onsuccess' => '',
          'secured' => 'off',
          'command' => 'aaaa',
          'onerror' => ''
    },
    admin3 => {
          'onerror' => '',
          'requestid' => '61',
          'rewrite' => '',
          'section' => 'aaaa',
          'layout' => '',
          'actions' => 'BBBB::BBBB',
          'secure' => '',
          'secured' => 'off',
          'onfailure' => '',
          'content' => '',
          'command' => 'aaaa',
          'onsuccess' => ''
    },
    'delete' => {
          'rewrite' => '',
          'onfailure' => '',
          'onerror' => '',
          'actions' => 'Site::Admin',
          'requestid' => '34',
          'onsuccess' => '',
          'layout' => '',
          'command' => 'admin',
          'secured' => undef,
          'content' => 'articles/arts-adminlist.html',
          'secure' => 'off',
          'section' => 'arts'
    },
};

my @plugins = qw(
    Labyrinth::Plugin::Requests
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
    skip "Unable to prep the test environment", 53  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Admin methods

    my $vars;

    # test bad access
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 2 } );
    for my $call ('Requests::Admin','Requests::Add',,'Requests::Edit','Requests::Save','Requests::Delete') {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);
        $vars = $loader->vars;
        is($vars->{data},undef,"no permission: $call");
    }
    

    # List request
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef } );
    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{admin1},'admin1 list variables are as expected');
    is( scalar(@{ $vars->{data} }),60,'request count as expected');


    # Add a request
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef } );
    $res = is($loader->action('Requests::Add'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("add vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{add},'add variables are as expected');


    # no request given
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );
    $res = is($loader->action('Requests::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit1},"base data provided, when no request given");


    # basic request given
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { requestid => 3 } );
    $res = is($loader->action('Requests::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("edit2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{edit2},"request 2 data provided");

    
    # Save a new request
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { section => 'aaaa', command => 'aaaa', actions => 'AAAA::AAAA', layout => '', content => '', onsuccess => '', onerror => '', onfailure => '', secure => '', rewrite => '' } );
    $res = is($loader->action('Requests::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'saved successfully');

    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin2 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{admin2},'admin2 list variables are as expected');
    is( scalar(@{ $vars->{data} }),61,'request count as expected');


    # Update an existing request
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1, data => undef },
        { requestid => 61, section => 'aaaa', command => 'aaaa', actions => 'BBBB::BBBB', layout => '', content => '', onsuccess => '', onerror => '', onfailure => '', secure => '', rewrite => '' } );
    $res = is($loader->action('Requests::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'saved successfully');
    
    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin3 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{admin3},'admin3 list variables are as expected');
    is( scalar(@{ $vars->{data} }),61,'request count as expected');


    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # delete a request
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { 'LISTED' => 61 } );
    $res = is($loader->action('Requests::Delete'),1);
    diag($loader->error)    unless($res);

    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{admin1},'admin1 list variables are as expected');
    is( scalar(@{ $vars->{data} }),60,'request count as expected');

    # empty delete request
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { 'LISTED' => '' } );
    $res = is($loader->action('Requests::Delete'),1);
    diag($loader->error)    unless($res);

    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{admin1},'admin1 list variables are as expected');
    is( scalar(@{ $vars->{data} }),60,'request count as expected');

    
    # delete a request - via Admin
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { doaction => 'Delete', 'LISTED' => 36 } );
    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{delete},'delete list variables are as expected');
    is( scalar(@{ $vars->{data} }),59,'request count as expected');

    # delete a request - bad action
    $loader->clear;
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 },
        { doaction => 'DoNothing', 'LISTED' => 34 } );
    $res = is($loader->action('Requests::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars->{data}));
    is_deeply($vars->{data}[0],$test_data->{delete},'delete list variables are as expected');
    is( scalar(@{ $vars->{data} }),59,'request count as expected');


    # -------------------------------------------------------------------------
    # Local Methods

    # drop downs
    is(Labyrinth::Plugin::Requests::SecureSelect(),     '<select id="typeid" name="typeid"><option value="1">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>');
    is(Labyrinth::Plugin::Requests::SecureSelect(1),    '<select id="typeid" name="typeid"><option value="1" selected="selected">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>');
    is(Labyrinth::Plugin::Requests::SecureSelect(undef),'<select id="typeid" name="typeid"><option value="1">off</option><option value="2">on</option><option value="3">either</option><option value="4">both</option></select>');

    # id => name
    my %types = (
        1 => 'off',
        2 => 'on',
        3 => 'either',
        4 => 'both',
    );

    for my $id (keys %types) {
        is(Labyrinth::Plugin::Requests::SecureName($id),$types{$id});
    }
    
    is(Labyrinth::Plugin::Requests::SecureName(),     'off');
    is(Labyrinth::Plugin::Requests::SecureName(undef),'off');

}
