#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Test::Harness;
use Test::More tests => 17;

my $test_data = {
    'list' => [
           {
             'body' => [
                         {
                           'paraid' => '1',
                           'body' => 'Born in the Red House, as The Wind Cries Mary',
                           'align' => undef,
                           'link' => undef,
                           'orderno' => '1',
                           'type' => 2,
                           'href' => undef,
                           'articleid' => '1',
                           'imageid' => '0'
                         }
                       ],
             'data' => {
                         'createdate' => '1383350400',
                         'quickname' => 'pete',
                         'publish' => '3',
                         'latest' => '0',
                         'title' => 'Pete',
                         'front' => '0',
                         'name' => 'guest',
                         'userid' => '1',
                         'folderid' => '1',
                         'postdate' => '2nd November 2013',
                         'sectionid' => '5',
                         'articleid' => '1',
                         'snippet' => 'Guitars, Mandolin and Vocals',
                         'imageid' => '0'
                       }
           }
    ],
    'item2' => {
           'body' => [
                       {
                         'paraid' => '1',
                         'align' => undef,
                         'imageid' => '0',
                         'orderno' => '1',
                         'body' => 'Born in the Red House, as The Wind Cries Mary',
                         'link' => undef,
                         'type' => 2,
                         'articleid' => '1',
                         'href' => undef
                       }
                     ],
           'data' => {
                       'front' => '0',
                       'title' => 'Pete',
                       'userid' => '1',
                       'publish' => '3',
                       'latest' => '0',
                       'name' => 'guest',
                       'postdate' => '2nd November 2013',
                       'articleid' => '1',
                       'createdate' => '1383350400',
                       'quickname' => 'pete',
                       'snippet' => 'Guitars, Mandolin and Vocals',
                       'folderid' => '1',
                       'sectionid' => '5',
                       'imageid' => '0'
                     }
    },
    'edit1' => {
           'data' => {
                       'ddpublish' => '<select id="publish" name="publish"><option value="1" selected="selected">Draft</option><option value="2">Submitted</option><option value="3">Published</option><option value="4">Archived</option></select>',
                       'publish' => '1',
                       'metadata' => '',
                       'body' => '',
                       'front' => '',
                       'width' => '',
                       'height' => '',
                       'latest' => '',
                       'name' => undef,
                       'quickname' => '',
                       'snippet' => '',
                       'title' => '',
                       'postdate' => '30/11/2014'
                     },
           'body' => [],
           'blocks' => ''
    },
    'edit2' => {
           'data' => {
                       'front' => '',
                       'createdate' => '1383350400',
                       'width' => '',
                       'latest' => '',
                       'publish' => '3',
                       'ddpublish' => '<select id="publish" name="publish"><option value="1">Draft</option><option value="2">Submitted</option><option value="3" selected="selected">Published</option><option value="4">Archived</option></select>',
                       'userid' => '1',
                       'metadata' => '',
                       'postdate' => '02/11/2013',
                       'folderid' => '1',
                       'name' => 'guest',
                       'quickname' => 'pete',
                       'snippet' => 'Guitars, Mandolin and Vocals',
                       'sectionid' => '5',
                       'imageid' => '0',
                       'height' => '',
                       'body' => '',
                       'title' => 'Pete',
                       'articleid' => '1'
                     },
           'body' => [
                       {
                         'align' => undef,
                         'orderno' => 1,
                         'imageid' => '0',
                         'type' => 2,
                         'paraid' => '1',
                         'link' => undef,
                         'body' => 'Born in the Red House, as The Wind Cries Mary',
                         'href' => undef,
                         'articleid' => '1'
                       }
                     ],
           'blocks' => '1'
    }
};

my @plugins = qw(
    Labyrinth::Plugin::Articles::Profiles
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
    skip "Unable to prep the test environment", 17  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    # list
    $res = is($loader->action('Articles::Profiles::List'),1);
    diag($loader->error)    unless($res);
    my $vars = $loader->vars;
    #diag("list vars=".Dumper($vars->{profiles}));
    is_deeply($vars->{profiles},$test_data->{list},'list variables are as expected');

    # item, with no id/name
    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, articles => undef }, { articleid => 0, id => 0, name => undef } );
    $res = is($loader->action('Articles::Profiles::Item'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("item1 vars=".Dumper($vars->{who}));
    is_deeply($vars->{who},undef,'item variables are as expected');

    # item with id
    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2, articles => undef }, { articleid => 1 } );
    $res = is($loader->action('Articles::Profiles::Item'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("item2 vars=".Dumper($vars->{who}));
    is_deeply($vars->{who},$test_data->{item2},'item variables are as expected');

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access
    $loader->refresh( \@plugins, { loggedin => 0, loginid => 2 } );
    for my $call ( 'Articles::Profiles::Admin', 'Articles::Profiles::Edit' ) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);
        $vars = $loader->vars;
        #diag("$call vars=".Dumper($vars->{data}));
        is($vars->{data},undef,"no permission: $call");
    }   

    # admin list
    $res = is($loader->action('Articles::Profiles::Admin'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    #diag("list vars=".Dumper($vars->{profiles}));
    is_deeply($vars->{profiles},$test_data->{list},'list variables are as expected');

    # item, with no id/name
    $loader->refresh( \@plugins, { articles => undef }, { articleid => undef, who => undef } );
    $loader->login(1);
    $res = is($loader->action('Articles::Profiles::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit1}{data}{$_} = $vars->{who}{data}{$_}  for(qw(postdate)); # these will always be the current timestamp
    #diag("edit1 vars=".Dumper($vars->{who}));
    is_deeply($vars->{who},$test_data->{edit1},'edit variables are as expected');

    # item with id
    $loader->refresh( \@plugins, { articles => undef, who => undef }, { articleid => 1 } );
    $res = is($loader->action('Articles::Profiles::Edit'),1);
    diag($loader->error)    unless($res);
    $vars = $loader->vars;
    $test_data->{edit2}{data}{$_} = $vars->{who}{data}{$_}  for(qw(createdate postdate)); # these will always be the current timestamp
    #diag("edit2 vars=".Dumper($vars->{who}));
    is_deeply($vars->{who},$test_data->{edit2},'edit variables are as expected');
}
