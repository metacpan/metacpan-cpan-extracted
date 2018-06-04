#!/usr/bin/env perl

# This example demonstrates differences between
#     param, multi_param, and url_param
# Neaf avoids relying on context in request.
# Instead, different variants of param method exist
#     just in case someone wants multi-value params

use strict;
use warnings;

use MVC::Neaf;

my $tpl = <<'TT';
<h1>Multi-value checkbox - [% file %]</h1>
<form method="POST">
[% FOREACH day IN days %]
    <input type="checkbox" name="day" value="[% day %]"[% IF on.$day %] checked[% END %]>
    [% day %]
    [% IF on.$day %](selected)[% END %]
    <a href="[% self | html %]?day=[% day %]">add to url</a>
    <br>
[% END %]
    <input type="submit" value="Update">
</form>
Non-multi value: [% day_single %]<br>
All values: [% day_multi.join(",") %]<br>
Query value: [% day_url %]<br>
TT

# Prepare some data...
my @days = qw(Mon Tue Wed Thu Fri Sat Sun);

get+post '/10/multi' => sub {
    my $req = shift;

    # param_multi will return empty lists if some of the given parameters
    #     fail validation
    my @select = $req->multi_param( day => join "|", @days );
    my %on;
    $on{$_}++ for @select;

    return {
        self       => $req->path,
        on         => \%on,
        days       => \@days,
        day_multi  => \@select,
        day_single => $req->param( day => '.*' ),
        day_url    => $req->url_param( day => '.*' ),
    };
}, default => {
    -view      => 'TT',
    -template  => \$tpl,
    file       => 'example/10 NEAF '.MVC::Neaf->VERSION,
}, description => "Multi-value parameters";

neaf->run;
