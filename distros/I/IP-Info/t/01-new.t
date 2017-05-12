#!perl

use strict; use warnings;
use IP::Info;
use Test::More tests => 2;

my $api_key = 'Your_API_Key';
my $secret  = 'Your_shared_secret';

eval { IP::Info->new(); };
like($@, qr/Missing required arguments: api_key, secret/);

eval { IP::Info->new({ api_key => $api_key }); };
like($@, qr/Missing required arguments: secret/);
