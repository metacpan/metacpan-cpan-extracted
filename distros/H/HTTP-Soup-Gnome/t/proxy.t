#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup::Gnome');
}

sub main {

    my $resolver = HTTP::Soup::Gnome::ProxyResolverGNOME->new();
    isa_ok($resolver, 'HTTP::Soup::Gnome::ProxyResolverGNOME');

    return 0;
}

exit main() unless caller;
