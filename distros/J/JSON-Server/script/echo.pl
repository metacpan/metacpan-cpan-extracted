#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use lib "$Bin/../lib";
use JSON::Server;
my $server = JSON::Server->new (port => 3737, verbose => 1);
$server->serve ();
