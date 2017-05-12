#!/usr/bin/env perl

use strict;
use warnings;

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

my $tt = <<"TT";
<html><head><title>Index of examples</title></head>
<body><h1>Index of examples</h1>
<ul>
[% FOREACH item IN list %]
    <li>
    <a href="[% item.path %]">[% item.path %] - [% item.description %]</a>
    </li>
[% END %]
</ul>
TT

my $n;
foreach my $file( glob "$Bin/*.pl" ) {
    $n++;
    ## no critic
    eval "package My::Isolated::$n;
        ref require \$file eq 'CODE' or die 'Script not PSGI-compatible\n'";
    if ($@) {
        warn "Failed to load $file: $@";
    };
};

my $routes = MVC::Neaf->get_routes;

my @list = sort { $a->{path} cmp $b->{path} }
    grep { $_->{description} }
    map  { $_->{GET} || $_->{HEAD} }
    values %$routes;

MVC::Neaf->route( "/" => sub {
    my $req = shift;

    return {
        -template => \$tt,
        list => \@list,
    };
}, path_info_regex => '');

MVC::Neaf->run;
