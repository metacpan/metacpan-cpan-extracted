#!/usr/bin/env perl

# This is a very stupid example demonstrating the simplicity
# of Not Even A Framework

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

# Some HTML boilerplate
# This is going to be a separate file in a real world app
my $tpl = <<'HTML';
<html>
<head>
    <title>[% title | html %] - [% file | html %]</title>
</head>
<body>
    <h1>[% title | html %]</h1>
    <form method="GET">
        <input name="name"><input type="submit" value="Greet">
    </form>
</body>
</html>
HTML

# Set up some application-wide defaults
# These will be merged into every controller response,
#     provided that the URI path starts with /01
neaf default => '/01' =>
    { -view => 'TT', file => 'example/01 NEAF '.MVC::Neaf->VERSION };

# Define some routes
get '/01/get' => sub {
    # The $request object has all you need to know about the outside world
    my $req = shift;

    # Parameter must be cleansed through validation
    #     think perl -T
    my $name = $req->param( name => qr/[-'\w ]+/ ) || "Unknown wanderer";

    # Return a hash. Rendering happens outside controller
    #     but this MAY be overridden with -content switch
    return {
        -template => \$tpl,
        title     => 'Hello, '.$name,
        name      => $name,
    };
}, description => 'Hello world GET request';

# The last statement of the application
neaf->run;

