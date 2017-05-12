#!/usr/bin/perl -w
use strict;

use FUSE::Client;

my $client = new FUSE::Client({Port => 35008});

$client->connect('localhost');

while(my $input = <STDIN>){
	chomp($input);
	my @parts = split(/ /,$input,2);
	$client->send($parts[0],$parts[1]);
}
