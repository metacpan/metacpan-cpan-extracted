#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(basename dirname);

# always use latest & greatest Neaf
use lib dirname(__FILE__)."/../lib";
use MVC::Neaf;

my $endpoint = join "/", '', cgi => basename(__FILE__) => 'raw';

my $tpl = <<'TT';
<head>
    <title>Raw POST JavaScript-based demo</title>
</head>
<body>
<h1>Raw POST JavaScript-based demo</h1>
<script lang="javascript">
    function foo(evt) {
        // don't really submit form
        evt.preventDefault();

        // construct an HTTP request
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '[% endpoint %]', true);
        xhr.setRequestHeader('Content-Type', 'text/plain; charset=UTF-8');

        // send the collected data as plain text
        xhr.send(document.getElementById("raw_data").value);

        xhr.onloadend = function () {
            // done, receive result as plaintext as well
            document.getElementById("result").innerHTML
                = xhr.responseText;
        };

        return false;
    };
</script>
<div>
<b>Result:</b> <span id="result"></span>
</div>
<div>Please enter space-separated numbers below:</div>
<form onSubmit="return foo(event);">
    <textarea name="raw" id="raw_data"></textarea><br>
    <input type="submit" value="Submit">
</form>
<p>This form makes a JavaScript-based POST request with raw body
collected from the text area (see source).
Then, a reply is received (also in plain text) and reported in the
text field above.
</p>
<p><i>JavaScript code stolen from
<a href="http://stackoverflow.com/a/13038218/280449">Stackoverflow</a>.</i></p>
TT

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    my $req = shift;

    return {
        -template => \$tpl,
        endpoint => $endpoint,
    };
}, description => "Raw POST JavaScript-based demo");

MVC::Neaf->route( $endpoint => sub {
    my $req = shift;

    my $raw = $req->body;
    my $sum = 0;
    $sum += $_ for $raw =~ /(\d+)/g;

    return {
        -content => $sum,
    };
}, method => 'POST' );

MVC::Neaf->run;
