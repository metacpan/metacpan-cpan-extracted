#!/usr/bin/env perl

# Generally Neaf is best suited for short-lived request
# However, a long-running operationsalsomay be performed
#     with the help of -continue control flag.
# This script demonstrates a 3n+1 problem simulation.
# Of course, real-life examples of continued requests probably
#     would involve some interaction with the system.

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

my $tpl =<<'HTML';
<html>
<head>
    <title>[% title | html %] - [% file | html %]</title>
</head>
<h1>[% title %]</h1>
<div>Enter an integer number, n.</div>
<div>On each step, each even n is divided by 2 and each odd n becomes 3n+1</div>
<div>The script stops when n reaches 1.</div>
<form method="GET">
    <input name="start" value="[% start | html %]">
    <input type="submit" value="Generate 3n+1">
</form>
<hr>
<div>0: [% start | html %]</div>

HTML

# just adding a normal handler...
get '/09/continue' => sub {
    my $req = shift;

    my $start = $req->param( start => '[1-9]\d*' );

    # Return as usual, headers and first part of page rendered via template
    return {
        title => '3n+1 (Collatz conjecture) generator',
        file  => 'example/09 NEAF '.MVC::Neaf->VERSION,
        start => $start,
    };
    # No headers can be sent beyond this point
}, -continue => sub {
    # The one and only parameter is still the request
    my $req = shift;

    # 'reply' hash holds the original reply
    my $x = $req->reply->{start};
    return unless $x;

    # These write & close only become available here.
    # close can actually be omitted, no problem.
    my $n = 1;
    while ($x > 1) {
        $x = $x % 2 ? 3 * $x + 1 : $x / 2;
        $req->write("<div>$n: $x</div>\n");
        $n++;
    };
    $req->write('</body></html>');
    $req->close;
}, -view => 'TT', -template => \$tpl, description => "Unspecified length reply";
# And all these usual params & control keys - we're still in route definition

neaf->run;
