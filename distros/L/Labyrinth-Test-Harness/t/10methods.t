#!/usr/bin/perl -w
use strict;

use lib qw(t/lib);
use Labyrinth::Test::Harness;

use Test::More tests => 32;

my @plugins = ( 'Labyrinth::Plugin::Base' );

my $test_vars1 = {
    'testing' => '0',
    'copyright' => '2013-2014 Me',
    'cgiroot' => 'http://example.com',
    'lastpagereturn' => '0',
    'autoguest' => '1',
    'administrator' => 'admin@example.com',
    'timeout' => '3600',
    'docroot' => 'http://example.com',
    'blank' => 'images/blank.png',
    'realm' => 'public',
    'iname' => 'Test Site',
    'mailhost' => '',
    'maxpasslen' => '20',
    'minpasslen' => '6',
    'cookiename' => 'session',
    'webdir' => 't/_DBDIR/html',
    'ipaddr' => '',
    'script' => '',
    'maxpicwidth' => '500',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'host' => 'example.com',
    'cgipath' => '/cgi-bin',
    'basedir' => 't/_DBDIR',
    'htmltags' => '+img',
    'icode' => 'testsite',
    'evalperl' => '1',
    'webpath' => '',
    'randpicwidth' => '400',
    'errcode' => 'ERROR'
};

my $test_vars2 = {
    'testing' => '0',
    'copyright' => '2013-2014 Me',
    'cgiroot' => 'http://example.com',
    'administrator' => 'admin@example.com',
    'timeout' => '3600',
    'user' => {
        'email' => 'barbie@example.com',
        'realname' => 'Barbie',
        'nickname' => 'Barbie'
    },
    'docroot' => 'http://example.com',
    'blank' => 'images/blank.png',
    'iname' => 'Test Site',
    'cookiename' => 'session',
    'webdir' => 't/_DBDIR/html',
    'ipaddr' => '',
    'maxpicwidth' => '500',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'data' => [
        {
            'search' => '1',
            'nickname' => 'Barbie',
            'accessid' => '5',
            'userid' => '1',
            'aboutme' => '',
            'email' => 'barbie@example.com',
            'realname' => 'Barbie',
            'password' => 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3',
            'url' => '',
            'realm' => 'admin',
            'imageid' => '1'
        },
        {
            'search' => '0',
            'nickname' => 'Guest',
            'accessid' => '1',
            'userid' => '2',
            'aboutme' => undef,
            'email' => 'GUEST',
            'realname' => 'guest',
            'password' => 'c8d6ea7f8e6850e9ed3b642900ca27683a257201',
            'url' => undef,
            'realm' => 'public',
            'imageid' => '1'
        }
    ],
    'htmltags' => '+img',
    'loginid' => 1,
    'webpath' => '',
    'lastpagereturn' => '0',
    'autoguest' => '1',
    'mailhost' => '',
    'realm' => 'public',
    'minpasslen' => '6',
    'maxpasslen' => '20',
    'loggedin' => 1,
    'script' => '',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'basedir' => 't/_DBDIR',
    'cgipath' => '/cgi-bin',
    'host' => 'example.com',
    'icode' => 'testsite',
    'evalperl' => '1',
    'randpicwidth' => '400',
    'errcode' => 'BADACCESS'
};

my $test_vars3 = {
    'testing' => '0',
    'copyright' => '2013-2014 Me',
    'cgiroot' => 'http://example.com',
    'lastpagereturn' => '0',
    'autoguest' => '1',
    'administrator' => 'admin@example.com',
    'timeout' => '3600',
    'docroot' => 'http://example.com',
    'blank' => 'images/blank.png',
    'realm' => 'public',
    'iname' => 'Test Site',
    'mailhost' => '',
    'maxpasslen' => '20',
    'minpasslen' => '6',
    'cookiename' => 'session',
    'webdir' => 't/_DBDIR/html',
    'ipaddr' => '',
    'script' => '',
    'maxpicwidth' => '500',
    'requests' => 't/_DBDIR/cgi-bin/config/requests',
    'cgidir' => 't/_DBDIR/cgi-bin',
    'host' => 'example.com',
    'cgipath' => '/cgi-bin',
    'basedir' => 't/_DBDIR',
    'htmltags' => '+img',
    'icode' => 'testsite',
    'evalperl' => '1',
    'webpath' => '',
    'randpicwidth' => '400'
};


# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new;
my $dir = $loader->directory;
#diag("directory=$dir");

my $res = $loader->prep(
    sql => [ "$dir/cgi-bin/db/plugin-base.sql","t/data/test-base.sql" ]
);
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 32  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    $res = is($loader->action('Base::List'),1);
    diag($loader->error)    unless($res);

    my $vars = $loader->vars;
#use Data::Dumper;
#diag(Dumper($vars));
    is_deeply($vars,$test_vars1,'stored variables are the same');

    # -------------------------------------------------------------------------
    # Admin Link methods

    # test bad access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 0, loginid => 2 } );

    # test bad access to admin
    for my $call (('Base::Admin')) {
        $res = is($loader->action($call),1);
        diag($loader->error)    unless($res);

        $vars = $loader->vars;
        is($vars->{data},undef,"no permission: $call");
    }
    

    # test regular access

    # refresh instance
    $loader->refresh(
        \@plugins,
        { loggedin => 1, loginid => 1 } );

    # test basic admin
    $res = is($loader->action('Base::Admin'),1);
    diag($loader->error)    unless($res);

    $vars = $loader->vars;
#use Data::Dumper;
#diag(Dumper($vars));
    is_deeply($vars,$test_vars2,'stored variables are the same');

    $loader->{error} = 'Test';
    is($loader->error,'Test');

    $loader->set_params( name => 'Test', test => 1 );;
    is_deeply($loader->params,{ name => 'Test', test => 1 });

    is($loader->copy_files(),0);
    is($loader->error,'no source directory given');
    is($loader->copy_files('blah'),0);
    is($loader->error,'no target directory given');
    is($loader->copy_files('blah','bleh'),0);
    is($loader->error,'failed to find source directory/file: blah');
    is($loader->copy_files($loader->config,$loader->directory),1);

    $loader->clear();
    is_deeply($loader->vars,{});
    is_deeply($loader->params,{});
    my $settings = $loader->settings;
    is($settings->{test3},undef);

    $loader->refresh( \@plugins );
    is_deeply($loader->vars,    { %$test_vars3 });
    is_deeply($loader->params,  { });

    $loader->refresh(
        \@plugins,
        { test1 => 1 },
        { test2 => 2 },
        { test3 => 3 } );
    is_deeply($loader->vars,    { test1 => 1, %$test_vars3 });
    is_deeply($loader->params,  { test2 => 2 });
    $settings = $loader->settings;
    is($settings->{test3},3);
    
    $loader->refresh(
        \@plugins,
        { test1 => 3 } );
    is_deeply($loader->vars,    { test1 => 3, %$test_vars3 });
    is_deeply($loader->params,  { test2 => 2 });

    $loader->refresh( \@plugins );
    is_deeply($loader->vars,    { test1 => 3, %$test_vars3 });
    is_deeply($loader->params,  { test2 => 2 });

    
    # can we clean up?
    is(-d $loader->directory ? 1 : 0, 1);
    $loader->cleanup;
    if($^O =~ /Win32/i) {   # Windows cannot delete until after process has stopped
        ok(1);
    } else {
        is(-d $loader->directory ? 1 : 0, 0, 'directory removed');
    }

    $loader = Labyrinth::Test::Harness->new(
        config    => 'foo',
        directory => 'bar'
    );

    is($loader->config,'foo');
    is($loader->directory,'bar');
}
