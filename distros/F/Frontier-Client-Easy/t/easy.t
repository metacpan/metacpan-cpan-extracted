#!/usr/bin/perl
use Frontier::Client::Easy;
use Test::More tests =>1;

print "Testing easy..\n";
ok ( $easy = Frontier::Client::Easy->new(url=>"dummy"), 'Create easy object' );
