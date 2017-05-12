#!/usr/bin/env perl

use strict;
use warnings;

# This script demonstrates...
my $descr  = "POST request, cookie, and redirect";

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

# Add some flexibility to run alongside other examples
my $script = basename(__FILE__);

# And some HTML boilerplate.
my $tpl = <<"TT";
<html><head><title>$descr - $script</title></head>
<body><h1>$script</h1><h2>$descr</h2>
<h3>[% IF name %]Hello, [% name %]![% ELSE %]What's your name?[% END %]</h3>
<form method="POST" action="/cgi/$script/form">
    Change name: <input name="name"/><input type="submit" value="&gt;&gt;"/>
</form>
</body>
</html>
TT

MVC::Neaf->route(cgi => $script => form => sub {
    my $req = shift;

    my $name = $req->param( name => qr/[-\w ]+/, '' );
    if (length $name) {
        $req->set_cookie( name => $name );
    };

    $req->redirect( $req->referer || "/" );
}, method => "POST");

MVC::Neaf->route(cgi => $script => sub {
    my $req = shift;

    my $name = $req->get_cookie( name => qr/[-\w ]+/ );
    return {
        -view => 'TT',
        -template => \$tpl,
        title => 'Hello',
        name => $name,
    };
}, description => $descr);

MVC::Neaf->run;

