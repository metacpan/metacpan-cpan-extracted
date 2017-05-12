#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib lib => glob 'modules/*/lib';

use LWP::Simple qw($ua);
use HTML::Microdata;
use JSON;

my $uri = shift;

my $res = $ua->get($uri);
unless ($res->is_success) {
	warn $res->status_line;
	exit 1;
}


my $microdata = HTML::Microdata->extract($res->decoded_content, base => $uri);

print JSON->new->pretty->encode($microdata->items);
