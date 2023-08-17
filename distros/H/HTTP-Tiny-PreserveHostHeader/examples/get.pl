#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', '../lib';

use HTTP::Tiny::PreserveHostHeader;

my $url = shift(@ARGV) || 'https://httpbin.org/headers';

my %headers = (
    Host => shift(@ARGV) || 'example.com',
);

my $response = HTTP::Tiny::PreserveHostHeader->new->get($url, { headers => \%headers });

print "$response->{status} $response->{reason}\n";

while (my ($k, $v) = each %{ $response->{headers} }) {
    for (ref $v eq 'ARRAY' ? @$v : $v) {
        print "$k: $_\n";
    }
}

print $response->{content} if length $response->{content};
