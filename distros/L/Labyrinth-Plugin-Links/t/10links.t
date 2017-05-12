#!/usr/bin/perl -w
use strict;

use lib qw(t/lib);
use Fake::Loader;

use Test::More tests => 89;

my $test_vars = {
    'testing' => '0',
    'copyright' => '2002-2014 Barbie',
    'cgiroot' => 'http:/',
    'lastpagereturn' => '0',
    'autoguest' => '1',
    'administrator' => 'barbie@cpan.org',
    'timeout' => '3600',
    'docroot' => 'http:/',
    'blank' => 'images/blank.png',
    'realm' => 'public',
    'iname' => 'Test Site',
    'mailhost' => '',
    'maxpasslen' => '20',
    'minpasslen' => '6',
    'cookiename' => 'session',
    'webdir' => 't/_DBDIR/html',
    'links' => [
         {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 1',
             'title' => 'Example Link 1',
             'orderno' => '1',
             'catid' => '1',
             'linkid' => '1'
         },
         {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 2',
             'title' => 'Example Link 2',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '2'
         },
         {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 3',
             'title' => 'Example Link 3',
             'orderno' => '3',
             'catid' => '3',
             'linkid' => '3'
           }
       ],
    'ipaddr' => '',
    'script' => '',
    'maxpicwidth' => '500',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'host' => '',
    'cgipath' => '/cgi-bin',
    'basedir' => 't/_DBDIR',
    'htmltags' => '+img',
    'icode' => 'testsite',
    'evalperl' => '1',
    'webpath' => '',
    'randpicwidth' => '400'
};

my $test_data = { 
    'links' => [
        {
            'body' => undef,
            'href' => 'http://www.example.com',
            'category' => 'Category 2',
            'title' => 'Example Link 2',
            'orderno' => '2',
            'catid' => '2',
            'linkid' => '2'
        },
        {
            'body' => undef,
            'href' => 'http://www.example.com',
            'category' => 'Category 3',
            'title' => 'Example Link 3',
            'orderno' => '3',
            'catid' => '3',
            'linkid' => '3'
        }
    ],
    'cats' => [
        {
            'category' => 'Category 2',
            'orderno' => '2',
            'catid' => '2'
        },
        {
            'category' => 'Category 3',
            'orderno' => '3',
            'catid' => '3'
        }
    ],
    'newcats' => [
        {
            'category' => 'Category 2',
            'orderno' => '2',
            'catid' => '2'
        },
        {
            'category' => 'Category 3',
            'orderno' => '3',
            'catid' => '3'
        },
        {
            'category' => 'Test',
            'orderno' => '4',
            'catid' => '4'
        }
    ],
    'newlinks2' => [
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 1',
             'title' => 'Example Link 1',
             'orderno' => '1',
             'catid' => '1',
             'linkid' => '1'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 2',
             'title' => 'Example Link 2',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '2'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 3',
             'title' => 'Example Link 3',
             'orderno' => '3',
             'catid' => '3',
             'linkid' => '3'
           }
    ],
    'newlinks3' => [
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 1',
             'title' => 'Example Link 1',
             'orderno' => '1',
             'catid' => '1',
             'linkid' => '1'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 2',
             'title' => 'Example Link 2',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '2'
           },
           {
             'body' => 'Labyrinth',
             'href' => 'http://labyrinth.missbarbell.co.uk',
             'category' => 'Category 2',
             'title' => 'Labyrinth',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '4'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 3',
             'title' => 'Example Link 3',
             'orderno' => '3',
             'catid' => '3',
             'linkid' => '3'
           }
    ],
    'newlinks4' => [
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 1',
             'title' => 'Example Link 1',
             'orderno' => '1',
             'catid' => '1',
             'linkid' => '1'
           },
           {
             'body' => 'Labyrinth',
             'href' => 'http://labyrinth.missbarbell.co.uk',
             'category' => 'Category 2',
             'title' => 'Labyrinth',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '4'
           },
           {
             'body' => 'Labyrinth2',
             'href' => 'http://labyrinth.technology',
             'category' => 'Category 2',
             'title' => 'Labyrinth2',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '2'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 3',
             'title' => 'Example Link 3',
             'orderno' => '3',
             'catid' => '3',
             'linkid' => '3'
           }
    ],
    'dellinks' => [
           {
             'body' => 'Labyrinth',
             'href' => 'http://labyrinth.missbarbell.co.uk',
             'category' => 'Category 2',
             'title' => 'Labyrinth',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '4'
           },
           {
             'body' => 'Labyrinth2',
             'href' => 'http://labyrinth.technology',
             'category' => 'Category 2',
             'title' => 'Labyrinth2',
             'orderno' => '2',
             'catid' => '2',
             'linkid' => '2'
           },
           {
             'body' => undef,
             'href' => 'http://www.example.com',
             'category' => 'Category 3',
             'title' => 'Example Link 3',
             'orderno' => '3',
             'catid' => '3',
             'linkid' => '3'
           }
    ],
    'newcats2' => [
           {
             'category' => 'Category 2',
             'orderno' => '2',
             'catid' => '2'
           },
           {
             'category' => 'Category 3',
             'orderno' => '3',
             'catid' => '3'
           },
           {
             'category' => 'Test',
             'orderno' => '4',
             'catid' => '4'
           }
    ],
    'newcats3' => [
           {
             'category' => 'Another Test',
             'orderno' => '1',
             'catid' => '5'
           },
           {
             'category' => 'Category 2',
             'orderno' => '2',
             'catid' => '2'
           },
           {
             'category' => 'Category 3',
             'orderno' => '3',
             'catid' => '3'
           },
           {
             'category' => 'Test',
             'orderno' => '4',
             'catid' => '4'
           }
    ],
    'newcats4' => [
           {
             'category' => 'Another Test',
             'orderno' => '1',
             'catid' => '5'
           },
           {
             'category' => 'Category 3',
             'orderno' => '3',
             'catid' => '3'
           },
           {
             'category' => 'Test',
             'orderno' => '4',
             'catid' => '4'
           },
           {
             'category' => 'Update Test',
             'orderno' => '5',
             'catid' => '2'
           }
    ],
    'delcats' => [
           {
             'category' => 'Another Test',
             'orderno' => '1',
             'catid' => '5'
           },
           {
             'category' => 'Category 3',
             'orderno' => '3',
             'catid' => '3'
           },
           {
             'category' => 'Test',
             'orderno' => '4',
             'catid' => '4'
           },
           {
             'category' => 'Update Test',
             'orderno' => '5',
             'catid' => '2'
           }
    ]
};

my $test_add = { 
    ddcats => '<select id="catid" name="catid"><option value="1">Category 1</option><option value="2">Category 2</option><option value="3">Category 3</option></select>'
};

my $test_edit = { 
    'body' => undef,
    'ddcats' => '<select id="catid" name="catid"><option value="1" selected="selected">Category 1</option><option value="2">Category 2</option><option value="3">Category 3</option></select>',
    'href' => 'http://www.example.com',
    'title' => 'Example Link 1',
    'ddpublish' => '<select id="publish" name="publish"><option value="0">Select Status</option><option value="1">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
    'linkid' => '1',
    'catid' => '1'
};

my $test_cats = [
    {
        'category' => 'Category 1',
        'orderno' => '1',
        'catid' => '1'
    },
    {
        'category' => 'Category 2',
        'orderno' => '2',
        'catid' => '2'
    },
    {
        'category' => 'Category 3',
        'orderno' => '3',
        'catid' => '3'
    }
];

# -----------------------------------------------------------------------------
# Set up

my $loader = Fake::Loader->new;
my $dir = $loader->directory;

my $res = $loader->prep("$dir/cgi-bin/db/plugin-base.sql","t/data/test-base.sql");
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 89  unless($res);

    $res = is($loader->labyrinth('Labyrinth::Plugin::Links'),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Links::List'),1);
    diag($loader->error)    unless($res);

    my $vars = $loader->vars;
    is_deeply($vars,$test_vars,'stored variables are the same');

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    # refresh instance
    refresh(
        $loader,
        { loggedin => 0, loginid => 2 } );

    # test bad access to admin
    for my $call (('Links::Admin','Links::Add','Links::Edit','Links::Save','Links::Delete',
                   'Links::CatAdmin','Links::CatEdit','Links::CatSave','Links::CatDelete')) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        is($vars->{data},undef,"no permission: $call");
    }
    

    # test no records
    for my $call ('Links::Edit','Links::Save','Links::CatEdit','Links::CatSave') {
        refresh(
            $loader,
            { loggedin => 1, loginid => 1 },
            { linkid => 9, catid => 9 });

        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        is($vars->{data},undef,"no stored records: $call");
    }

    # test regular access

    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1 } );

    # test basic admin
    $res = is($loader->action('Links::Admin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    is_deeply($vars->{data},$test_vars->{links},'stored variables are the same');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef } );

    # test adding a link
    $res = is($loader->action('Links::Add'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    is_deeply($vars->{data}{ddcats},$test_add->{ddcats},'dropdown variables are the same');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { linkid => 1 } );

    # test editing a link
    $res = is($loader->action('Links::Edit'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    is_deeply($vars->{data},$test_edit,'stored variables are the same');


    # check link changes
    my %hrefs = (
        ''                      => '',
        'www.example.com'       => 'http://www.example.com',
        'http://example.com'    => 'http://example.com',
        'ftp://example.com'     => 'ftp://example.com',
        'https://example.com'   => 'https://example.com',
        'git://www.example.com' => 'git://www.example.com',
        '/examples'             => '/examples',
        'blah://examples'       => 'http://blah://examples',
    );

    for my $href (keys %hrefs) {
        $loader->set_params( href => $href );
        $res = is($loader->action('Links::CheckLink'),1);
        diag($loader->error)    unless($res);

        my $params = $loader->params;
        is($params->{href},$hrefs{$href});
    }


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { 'title' => '', 'body' => 'blah', 'catid' => '2' } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},undef,'failed to saved');

    $res = is($loader->action('Links::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newlinks2},'previous list remains');

    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { 'title' => 'Labyrinth', 'body' => 'Labyrinth', 'href' => 'http://labyrinth.missbarbell.co.uk', 'catid' => '2', 'linkid' => 0 } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'successful save');

    $res = is($loader->action('Links::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newlinks3},'new link added');
    
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef, thanks => 0 },
        { 'title' => 'Labyrinth2', 'body' => 'Labyrinth2', 'href' => 'http://labyrinth.technology', 'catid' => '2', 'linkid' => 2 } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::Save'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'successful save');

    $res = is($loader->action('Links::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newlinks4},'old link updated');

    
    # -------------------------------------------------------------------------
    # Admin Link Category methods

    # refresh instance
    is($loader->labyrinth('Labyrinth::Plugin::Links'),1);

    # test basic admin
    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
    is_deeply($vars->{data},$test_cats,'stored variables are the same');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { catid => 1 } );

    # test editing a link
    is($loader->action('Links::CatEdit'),1);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_cats->[0],'stored variables are the same');


    # test select box list
    #is($loader->action('Links::CatSelect'),1);
    #$vars = $loader->vars;
    #use Data::Dumper;
    #diag(Dumper($vars));
    #is_deeply($vars,$test_vars,'stored variables are the same');


    # -------------------------------------------------------------------------
    # Admin Link Delete/Save methods - as we change the db

    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { LISTED => [ 1 ], doaction => 'Delete' } );

    # test delete via admin
    $res = is($loader->action('Links::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{dellinks},'stored variables are the same');


    # -------------------------------------------------------------------------
    # Admin Categories Delete/Save methods - as we change the db

    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { LISTED => [ 1 ], doaction => 'Delete' } );

    # test delete via admin
    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{cats},'stored variables are the same');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { 'category' => 'Test', 'orderno' => '4', 'catid' => '' } );

    # test saving a (new and existing) category
    $res = is($loader->action('Links::CatSave'),1);
    diag($loader->error)    unless($res);

    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newcats},'stored variables are the same');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef, thanks => undef },
        { 'category' => '', 'orderno' => '1', 'catid' => '0' } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::CatSave'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},undef,'failed save');

    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newcats2},'previous list remains');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { 'category' => 'Another Test', 'orderno' => '', 'catid' => '' } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::CatSave'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'successful save');

    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newcats3},'new category added');


    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef, thanks => 0 },
        { 'category' => 'Update Test', 'orderno' => '5', 'catid' => '2' } );

    # test saving a (new and existing) category without order
    $res = is($loader->action('Links::CatSave'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is($vars->{thanks},1,'successful update');

    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    is_deeply($vars->{data},$test_data->{newcats4},'category updated');

    # refresh instance
    refresh(
        $loader,
        { loggedin => 1, loginid => 1, data => undef },
        { LISTED => [ 1 ], doaction => 'Delete' } );

    # test delete via admin
    $res = is($loader->action('Links::CatAdmin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
#use Data::Dumper;
#diag(Dumper($vars->{data}));
    is_deeply($vars->{data},$test_data->{delcats},'stored variables are the same');
}


# -----------------------------------------------------------------------------
# Private Functions

sub refresh {
    my ($lab,$vars,$params) = @_;

    $lab->labyrinth('Labyrinth::Plugin::Links');
    $lab->set_vars( %$vars )        if($vars);
    $lab->set_params( %$params )    if($params);
}
