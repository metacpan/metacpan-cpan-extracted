#!/usr/bin/env perl

use LWP::UserAgent::Caching::Simple qw/get_from_json/;

# $HTTP::Caching::DEBUG = 1;

my $data = get_from_json(shift,
    'Cache-Control' => 'max-stale=3600',
    'Cache-Control' => 'no-transform'
);

use Data::Dumper;
print Dumper $data;
