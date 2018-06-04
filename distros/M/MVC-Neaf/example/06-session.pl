#!/usr/bin/env perl

# This example demonstrates handling sessions & authorization
#     in Not Even A Framework
# It also shows how pre_logic hook and custom error handlers can be used.

use strict;
use warnings;

use MVC::Neaf;
use MVC::Neaf::X::Session::Cookie;

# Instantiate session engine
# One may want a server-side storage if you want more security
#    but the usage is generally the same
my $sess = MVC::Neaf::X::Session::Cookie->new(
    key    => 'not so secret key', # TODO change if you copy-n-paste this ^_^
    expire => 3600,
);
# Note that the session engine knows *nothing* about cookies, requests and web.
# It only stores and retreives data and generates unique ids.
neaf session => $sess, cookie => 'neaf.playground.session';

# Configure a custom template
neaf view => TT6 => TT =>
    INCLUDE_PATH => __FILE__.".data",
    PRE_PROCESS  => 'head.html',
    POST_PROCESS => 'foot.html';
# As always, some default values
neaf default => {
    -view => 'TT6',
    file  => 'example/06 NEAF '.MVC::Neaf->VERSION,
    root  => '/06',
}, path => '/06';

# pre_logic hooks are executed right before the controller,
#    if the path matches.
# Should such hook die, controller code is never reached.
# Looks about right for authorization
neaf pre_logic => sub {
    my $req = shift;

    die 403
        unless $req->session->{user};
}, path => '/06', exclude => '/06/login';

# Define a custom error handler. Any 3-digit command will be
#    understood as an error hook by Neaf
neaf 403 => sub {
    my $req = shift;

    # Defaults not getting in here - will need to provide -view
    return {
        -view     => 'TT6',
        -template => '403.html',
        title     => 'Permission denied',
        back      => $req->path,
        root      => '/06',
    };
};

# Just display the form.
get '/06/login' => sub {
    my $req = shift;

    return {
        -template => 'login.html',
        title     => "Log in",
        back      => $req->param(back => '/.*'),
    };
};

# User validation is hard (and we also must handle new registrations etc)
# Plus, we must return user to login page, preserving already-entered data.
# But this would make this example even bigger.
post  '/06/login' => sub {
    my $req = shift;

    my $login    = $req->param( login    => '[\w\s\.\-]+' );
    my $password = $req->param( password => '.+' );

    # Of course, a more robust check shouldbe done in a real application
    # NOTE we cannot just make it in-memory because of possible
    #     preforking server.
    $req->redirect( $req->get_url_rel( back => $req->param( back => '/.*' )))
        unless $login and $password;

    # A simple way to determine admin password
    my $admin = 0;
    $password =~ /\W/ and $password =~ /\d/
        and $password =~ /\l\w/ and $password =~ /\u\w/
        and $admin = 1;

    $req->save_session( { user => $login, admin => $admin } );
    $req->redirect( $req->param( back => '/.*' ) || '/06/my' );
};

# Yes, this simple
post '/06/logout' => sub {
    my $req = shift;
    $req->delete_session;
    $req->redirect( $req->referer || '/06/my' );
};

# Finally, this is the precious information we pretend to care about
get '/06/my' => sub {
    my $req = shift;

    my $user  = $req->session->{user};
    my $admin = $req->session->{admin};

    return {
        -template => 'my.html',
        title => 'Welcome, '.($admin ? 'admin' : 'user').' '.$user,
        user  => $user,
        admin => $admin,
    };
}, description => "Session and custom error template demo";

neaf->run;
