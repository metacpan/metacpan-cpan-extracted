#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 46;

my $test_vars = {
    'basedir' => 't/_DBDIR',
    'maxpasslen' => '20',
    'cookiename' => 'session',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'timeout' => '3600',
    'cgipath' => '/cgi-bin',
    'randpicwidth' => '400',
    'minpasslen' => '6',
    'script' => '',
    'webdir' => 't/_DBDIR/html',
    'icode' => 'testsite',
    'realm' => 'public',
    'lastpagereturn' => '0',
    'iname' => 'Test Site',
    'ipaddr' => '',
    'autoguest' => '1',
    'evalperl' => '1',
    'htmltags' => '+img',
    'maxpicwidth' => '500',
    'cgiroot' => 'http://example.com',
    'mailhost' => '',
    'administrator' => 'admin@example.com',
    'copyright' => '2013-2014 Me',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'blank' => 'images/blank.png',
    'docroot' => 'http://example.com',
    'webpath' => '',
    'host' => 'example.com',
    'testing' => '0'
};

my $test_data = { 
    add => {
        'body' => [
            {
                'orderno' => 1,
                'type' => 2,
                'paraid' => '1'
            }
        ],
        'blocks' => '1',
        'htmltags' => 'a, address, b, br, center, em, h1, h2, h3, h4, h5, h6, hr, i, img, li, ol, p, pre, strike, strong, sup, table, tbody, td, th, thead, tr, u and ul',
        'data' => {
            'quickname' => 'ID1',
            'postdate' => '26/11/2014',
            'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
            'folderid' => 1,
            'articleid' => '1',
            'name' => 'Barbie',
            'sectionid' => 6,
            'userid' => 2
        }
    },

    edit1 => {
        'blocks' => '',
        'body' => [],
        'data' => {
            'width' => '',
            'snippet' => '',
            'publish' => '1',
            'title' => '',
            'body' => '',
            'latest' => '',
            'height' => '',
            'quickname' => '',
            'postdate' => '26/11/2014',
            'front' => '',
            'name' => undef,
            'comments' => 0,
            'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
            'metadata' => ''
        },
    },
    edit2 => {
        'blocks' => '',
        'body' => [],
        'data' => {
            'width' => '',
            'snippet' => '',
            'publish' => '1',
            'title' => '',
            'body' => '',
            'latest' => '',
            'height' => '',
            'quickname' => '',
            'postdate' => '26/11/2014',
            'front' => '',
            'name' => undef,
            'comments' => 0,
            'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
            'metadata' => ''
        },
    },
    edit3 => {
        'body' => [],
        'data' => {
                    'latest' => 1,
                    'snippet' => undef,
                    'title' => 'A New Article',
                    'postdate' => 'Sunday, 26th November 2014',
                    'userid' => 2,
                    'sectionid' => 6,
                    'quickname' => '1414340977',
                    'folderid' => undef,
                    'articleid' => undef,
                    'imageid' => 0,
                    'createdate' => undef,
                    'front' => 0,
                    'publish' => 1
                  },
        'blocks' => ''
    },
    edit4 => {
        'body' => [],
        'data' => {
                    'sectionid' => 6,
                    'userid' => '2',
                    'quickname' => '1414340977',
                    'folderid' => '1',
                    'articleid' => 1,
                    'imageid' => 0,
                    'latest' => 1,
                    'snippet' => '',
                    'title' => 'A Different Article',
                    'postdate' => 'Sunday, 26th November 2014',
                    'publish' => 1,
                    'createdate' => '1414340977',
                    'front' => 0
                  },
        'blocks' => ''
    },

    admin1 => [
        {
            'sectionid' => '6',
            'publish' => '1',
            'quickname' => 'draft0',
            'createdate' => '1414332640',
            'userid' => '2',
            'title' => 'DRAFT',
            'folderid' => '1',
            'snippet' => '',
            'imageid' => '0',
            'postdate' => '26/11/2014',
            'front' => '0',
            'latest' => '0',
            'name' => 'Barbie',
            'comments' => '',
            'articleid' => '1',
            'publishstate' => 'Draft'
        }
    ],
};

my @plugins = qw(
    Labyrinth::Plugin::Articles::Diary
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
    skip "Unable to prep the test environment", 46  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Articles::Diary::List'),1);
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
    for my $call (
            'Articles::Diary::Access',          'Articles::Diary::Admin',           'Articles::Diary::Add',
            'Articles::Diary::Edit',            'Articles::Diary::Save',            'Articles::Diary::Delete',
            'Articles::Diary::ListComment',     'Articles::Diary::EditComment',     'Articles::Diary::SaveComment',
            'Articles::Diary::PromoteComment',  'Articles::Diary::DeleteComment',   'Articles::Diary::MarkIP'
        ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }
    

    # Add a page
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 2 );

    # test adding a link
    $res = is($loader->action('Articles::Diary::Add'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    $test_data->{add}{data}{$_} = $vars->{article}{data}{$_}    for(qw(postdate)); # these will always be the current timestamp
    #diag("add vars=".Dumper($vars->{article}));
    is_deeply($vars->{article},$test_data->{add},'add variables are as expected');


    # Edit - no page given
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 2 );

    $res = is($loader->action('Articles::Diary::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    $test_data->{edit1}{data}{$_} = $vars->{article}{data}{$_}  for(qw(postdate)); # these will always be the current timestamp
    #diag("edit1 vars=".Dumper($vars));
    is_deeply($vars->{article},$test_data->{edit1},"base data provided, when no page given");


    # Edit - missing page given
    $loader->refresh( \@plugins, { data => undef }, { articleid => 3 } );
    $loader->login( 2 );

    $res = is($loader->action('Articles::Diary::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    $test_data->{edit2}{data}{$_} = $vars->{article}{data}{$_}  for(qw(postdate)); # these will always be the current timestamp
    #diag("edit2 vars=".Dumper($vars));
    is_deeply($vars->{article},$test_data->{edit2},"page 2 data provided, with no reordering");

    
    # Admin access
    $loader->refresh( \@plugins, { data => undef } );
    $loader->login( 2 );

    # test basic admin
    $res = is($loader->action('Articles::Diary::Admin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    $test_data->{admin1}[0]{$_} = $vars->{data}[0]{$_}  for(qw(createdate postdate)); # these will always be the current timestamp
    #diag("admin1 vars=".Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{admin1},'admin list variables are as expected');


    # Save a new page
    $loader->refresh( \@plugins, { data => undef, errcode => '' },
        { 'title' => 'A New Article', 'front' => 0, latest => 1, articleid => 0, publish => 1 } );
    $loader->login( 2 );
    $loader->refresh( \@plugins, { data => undef, errcode => '' });

    $res = is($loader->action('Articles::Diary::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save1 vars=".Dumper($vars));
    is($vars->{thanks},1,'saved successfully');

    $loader->refresh( \@plugins, { data => undef }, { articleid => 2 } );
    $res = is($loader->action('Articles::Diary::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit3}{data}{$_} = $vars->{draft0}{data}{$_}   for(qw(quickname createdate postdate)); # these will always be the current timestamp
    #diag("save1 edit3 vars=".Dumper($vars->{draft0}));
    is_deeply($vars->{draft0},$test_data->{edit3},'admin list variables are as expected');

    # Update an existing page
    $loader->refresh( \@plugins, { data => undef, thanks => undef },
        { 'title' => 'A Different Article', 'quickname' => 'blah2', 'front' => 0, latest => 1, articleid => 1, publish => 1 } );
    $loader->login( 2 );
    $loader->refresh( \@plugins, { data => undef, errcode => '' });

    $res = is($loader->action('Articles::Diary::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("save2 vars=".Dumper($vars));
    is($vars->{thanks},1,'saved successfully');

    $loader->refresh( \@plugins, { data => undef }, { articleid => 1 } );
    $res = is($loader->action('Articles::Diary::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit4}{data}{$_} = $vars->{draft0}{data}{$_}   for(qw(quickname createdate postdate)); # these will always be the current timestamp
    #diag("save2 edit4 vars=".Dumper($vars->{draft0}));
    is_deeply($vars->{draft0},$test_data->{edit4},'admin list variables are as expected');


    
    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # refresh instance
    $loader->refresh( \@plugins, { articles => undef }, { LISTED => 1 } );
    $loader->login( 2 );

    # test delete via admin
    $res = is($loader->action('Articles::Diary::Delete'),1);
    diag($loader->error)    unless($res);

    # test delete via admin
    $loader->refresh( \@plugins, { articles => undef } );
    $res = is($loader->action('Articles::Diary::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("delete vars=".Dumper($vars));
    is_deeply($vars->{articles},undef,'no admin list as expected');
}
