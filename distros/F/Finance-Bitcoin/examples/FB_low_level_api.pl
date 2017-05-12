#!/usr/bin/perl

use 5.010;
use Finance::Bitcoin::API;

my $creds   = shift @ARGV or die "Please provide username:password as a parameter.\n";
my $uri     = 'http://'.$creds.'@127.0.0.1:8332/';
my $api     = Finance::Bitcoin::API->new( endpoint => $uri );
my $balance = $api->call('getbalance');
say($balance || $api->error);

