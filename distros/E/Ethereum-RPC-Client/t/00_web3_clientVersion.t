use strict;
use warnings;
use Test::More;
use Ethereum::RPC::Client;

BEGIN {
    plan skip_all => 'Needs Travis setup'
        unless $ENV{TRAVIS};
}

my $eth                = Ethereum::RPC::Client->new();
my $web3_clientVersion = $eth->web3_clientVersion;
diag "Got $web3_clientVersion";
ok($web3_clientVersion);

done_testing();
