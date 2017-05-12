use warnings;
use strict;
use t::share;

my ($json, @call);

my $client = JSON::RPC2::Client->new();

my ($json1, $call1) = $client->call('method1');
my ($json2, $call2) = $client->call('method2');


throws_ok { ($json,@call) = $client->batch()                } qr/request required/;
throws_ok { ($json,@call) = $client->batch($call1, $call2)  } qr/request required/;

($json, @call) = $client->batch($json2, $call2, $json1, $call1);
ok length($json) > length($json2) + length($json1);
is_deeply \@call, [$call2, $call1];

($json, @call) = $client->batch($json1);
ok length($json) > length($json1);
is_deeply \@call, [];


done_testing();
