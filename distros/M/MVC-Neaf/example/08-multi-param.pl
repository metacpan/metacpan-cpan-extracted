#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(basename dirname);
use lib dirname(__FILE__)."/../lib";
use MVC::Neaf;

my @days = qw(Mon Tue Wed Thu Fri Sat Sun);

my $tpl = <<'TT';
<h1>Multi-value checkbox</h1>
<form method="POST">
[% FOREACH day IN days %]
    <input type="checkbox" name="day" value="[% day %]"[% IF on.$day %] checked[% END %]>
    [% day %]
    [% IF on.$day %](selected)[% END %]
    <br>
[% END %]
    <input type="submit" value="Update">
</form>
Non-multi value: [% day_single %]<br>
All values: [% day_multi.join(",") %]<br>
Query value: [% day_url %]<br>
TT

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    my $req = shift;

    my @select = $req->multi_param( day => join "|", @days );
    my %on;
    $on{$_}++ for @select;

    return {
        -template  => \$tpl,
        on         => \%on,
        days       => \@days,
        day_multi  => \@select,
        day_single => $req->param( day => '.*' ),
        day_url    => $req->url_param( day => '.*' ),
    };
}, description => "Multi-value parameters");

MVC::Neaf->run;
