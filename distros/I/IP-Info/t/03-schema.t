#!perl

use strict; use warnings;
use IP::Info;
use Test::More tests => 1;

my $api_key = 'Your_API_Key';
my $secret  = 'Your_shared_secret';
my $info    = IP::Info->new({ api_key => $api_key, secret => $secret });

eval { $info->schema() };
like($@, qr/ERROR: Please supply the file name for the schema document/);
