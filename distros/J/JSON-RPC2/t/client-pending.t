use warnings;
use strict;
use t::share;

my ($json_request, $call);

my $client = JSON::RPC2::Client->new();


# no pending
is_deeply [$client->pending()], [],
    'no pending';

# one pending
# pending return same on each call
($json_request, $call) = $client->call('qwe');
$call->{id} = 1;
is_deeply [$client->pending()], [$call],
    'one pending';
is_deeply [$client->pending()], [$call],
    'pending return same on each call';

# two pending
($json_request, my $call2) = $client->call_named('asd');
$call2->{id} = 2;
is_deeply [sort $client->pending()], [sort $call, $call2],
    'two pending';

# many pending
($json_request, my $call3) = $client->call('zxc');
($json_request, my $call4) = $client->call('qqq');
$call3->{id} = 3;
$call4->{id} = 4;
is_deeply [sort $client->pending()], [sort $call, $call2, $call3, $call4],
    'many pending';

# cancel works
$client->cancel($call);
$client->response(fake_result($json_request, 10));
is_deeply [sort $client->pending()], [sort $call2, $call3],
    'some canceled';

done_testing();
