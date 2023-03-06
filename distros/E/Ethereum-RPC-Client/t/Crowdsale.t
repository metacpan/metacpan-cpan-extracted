use strict;
use warnings;
use Test::More;
use Ethereum::RPC::Client;
use Ethereum::RPC::Contract::Helper::ImportHelper;
use Ethereum::RPC::Contract::Helper::UnitConversion;
use Math::BigInt;
use JSON;

BEGIN {
    plan skip_all => 'Needs Travis setup'
        unless $ENV{CIRCLECI};
}

my $rpc_client = Ethereum::RPC::Client->new;

my $coinbase = $rpc_client->eth_coinbase;

my $truffle_project = Ethereum::RPC::Contract::Helper::ImportHelper::from_truffle_build("./t/resources/SimpleCrowdsale.json");

die "can't read json" unless $truffle_project;

my $contract = $rpc_client->contract({
    contract_abi => $truffle_project->{abi},
    rpc_client   => $rpc_client,
    from         => $coinbase,
    gas          => 4000000
});

my $block = $rpc_client->eth_getBlockByNumber('latest', JSON->true);
ok $block;

my $timestamp  = hex $block->{timestamp};
my $start_time = $timestamp + 86400;
my $end_time   = $start_time + (86400 * 20);
my $rate       = Math::BigInt->new(1000);
my $wallet     = $coinbase;

my $response = $contract->invoke_deploy($truffle_project->{bytecode}, $start_time, $end_time, $rate, $wallet)->get_contract_address(35);
ok !$response->is_failed;

$contract->contract_address($response->get->response);
$contract->gas(undef);

my @account_list = @{$rpc_client->eth_accounts()};

$response = $contract->invoke("startTime")->call_transaction();
ok !$response->is_failed;
is $response->get->to_big_int, $start_time;

$response = $contract->invoke("endTime")->call_transaction();
ok !$response->is_failed;
is $response->get->to_big_int, $end_time;

$response = $contract->invoke("hasEnded")->call_transaction();
ok !$response->is_failed;
is $response->get->to_big_int, 0;

$response = $contract->invoke("token")->call_transaction();
ok !$response->is_failed;
ok $response->get->to_hex;

done_testing();
