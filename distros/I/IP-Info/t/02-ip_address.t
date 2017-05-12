#!perl

use strict; use warnings;
use IP::Info;
use Test::More tests => 3;

my $api_key = 'Your_API_Key';
my $secret  = 'Your_shared_secret';
my $info    = IP::Info->new({ api_key => $api_key, secret => $secret });

eval { $info->ip_address() };
like($@, qr/ERROR: Missing parameter IP Address/);

eval { $info->ip_address('abcde') };
like($@, qr/ERROR: Invalid IP Address \[abcde\]/);

eval { $info->ip_address('4.4.1') };
like($@, qr/ERROR: Invalid IP Address \[4\.4\.1\]/);
