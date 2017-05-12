#!/usr/bin/env perl

use strict;
use warnings;

# always use latest & greatest Neaf
use File::Basename qw(basename dirname);
my $Bin;
BEGIN { $Bin = dirname( __FILE__ ) || "." };
use lib $Bin."/../lib";
use MVC::Neaf;
use MVC::Neaf::X::Session::Cookie;

my $script = basename(__FILE__);

MVC::Neaf->set_session_handler(
    engine => MVC::Neaf::X::Session::Cookie->new( key => 'foobared' ),
    view_as => 'session'
);

my $tpl_main = <<"TT";
<html>
<head><title>Session example</title></head>
<body>
<h1>Session example</h1>
<h2>Hello, [% user || "Stranger" %]</h2>
<form action="/cgi/$script/login" method="POST">
    <input name="user">
    <input type="submit" value="Log in!">
</form>
[% IF user %]
<br>
<form action="/cgi/$script/logout" method="POST">
    <input type="submit" value="Log out">
</form>
[% END %]
[% IF session %]
    <h3>Raw session data</h3>
    <ul>
    [% FOREACH key IN session.keys %]
        <li><b>[% key %] = </b>[% session.\$key %];</li>
    [% END %]
    </ul>
[% END %]
</body>
</html>
TT

MVC::Neaf->route( cgi => $script => sub {
    my $req = shift;

    return {
        -template => \$tpl_main,
        user => $req->session->{user},
    };
}, description => "File-based session example" );

MVC::Neaf->route( cgi => $script => login => sub {
    my $req = shift;

    my $user = $req->param( user => qr/\w+/ );

    if ($user) {
        $req->session->{user} = $user;
        $req->session->{logged_in} = time;
        $req->save_session;
    };

    $req->redirect( "/cgi/$script" );
}, method => "POST" );

MVC::Neaf->route( cgi => $script => logout => sub {
    my $req = shift;

    $req->delete_session;
    $req->redirect( "/cgi/$script" );
}, method => "POST" );

# TODO logout as well

MVC::Neaf->run;
