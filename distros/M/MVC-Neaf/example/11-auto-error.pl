#!/usr/bin/env perl

use strict;
use warnings;
use MVC::Neaf qw(:sugar);

my $tpl = <<"HTML";
<html>
<head>
    <title>[% title | html %] - [% file | html %]</title>
</head>
<body>
<h1>[% title | html %]</h1>
<script lang="javascript">
"use strict";
var post_to = "/11/js";

function upd(arg) {
    document.getElementById("content").innerHTML = "Waiting for response...";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState != XMLHttpRequest.DONE)
            return;
        // pretend we forgot to check for http status
        document.getElementById("content").innerHTML = xhr.responseText;
    };
    xhr.open( "get", post_to+arg, true );
    xhr.send();
    return false;
};
</script>
<div id="content">Not ready yet...</div>
<input type="submit" value="Route error" onClick="return upd('?die=pre_route')">
<input type="submit" value="Controller error" onClick="return upd('')">
<input type="submit" value="Bad return error" onClick="return upd('?ret=1')">
<input type="submit" value="Render error" onClick="return upd('?tpl=1')">

<div>Don't forget to look at the server logs if you see anything unusual.</div>
</body>
</html>
HTML

get '/11/oops' => sub {
    my $req = shift;
    return {
        file  => 'example/11 NEAF '.MVC::Neaf->VERSION,
        title => 'Traceable error response',
    };
}, -template => \$tpl, -view => 'TT', description => "Unexpected error demo";

# This would affect other examples as well! C'est la vie
neaf pre_route => sub {
    my $req = shift;
    $req->param( die => "pre_route" )
        and die "Pre-route failed upon request";
};

# This never returns anything useful
get + post '/11/js' => sub {
    my $req = shift;
    return "Text"
        if $req->param( ret => 1 );
    return {
        -view     => 'TT',
        -template => \'[% END %]',
    }
        if $req->param( tpl => 1 );

    die "Foobared";
};

neaf->run;
