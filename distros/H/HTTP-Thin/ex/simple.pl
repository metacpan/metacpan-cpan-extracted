#!/usr/bin/env perl
use 5.12.1;
use HTTP::Thin;
use HTTP::Request::Common;

my $ua = HTTP::Thin->new();
say $ua->request( GET 'http://tamarou.com' )->as_string;
