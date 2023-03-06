#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;
use Path::Tiny;

use Ethereum::RPC::Client;

BEGIN {
    plan skip_all => 'Needs Travis setup'
        unless $ENV{CIRCLECI};
}

my $rpc_client = Ethereum::RPC::Client->new;

my $abi      = path("./t/resources/abi_encoding/abi_encoding.abi")->slurp_utf8;
my $bytecode = path("./t/resources/abi_encoding/abi_encoding.bin")->slurp_utf8;

my $coinbase = $rpc_client->eth_coinbase();

my $contract = $rpc_client->contract({
    contract_abi => $abi,
    from         => $coinbase,
    gas          => 4000000,
});

# DEPLOY

my $deploy_transaction = $contract->_prepare_transaction($bytecode, "constructor", [[10, 15]]);

my $remix_deploy_data_input = path("./t/resources/abi_encoding/remix_deploy.bin")->slurp_utf8;
$remix_deploy_data_input =~ s/^\s+|\s+$//g;

is $deploy_transaction->data, $remix_deploy_data_input, "correct deploy encoding";

# STRING

my $function_id = substr($contract->get_function_id("testString", 3), 0, 10);

my @dynamic_array           = ("ha",     "ta", "tu");
my @static_array            = ("double", "string");
my $test_string_transaction = $contract->_prepare_transaction($function_id, "testString", ["ha", \@dynamic_array, \@static_array]);

my $remix_string_test_data = path("./t/resources/abi_encoding/remix_testString.bin")->slurp_utf8;
$remix_string_test_data =~ s/^\s+|\s+$//g;

is $test_string_transaction->data, $remix_string_test_data, "correct string params encoding";

# BYTES

$function_id = substr($contract->get_function_id("testBytes", 4), 0, 10);

@dynamic_array = ("0x4c31");
my @dynamic_array2 = ("0x4c31", "0x4c32");
@static_array = ("0x64736163736163646173", "0x64736163736163646173");
my $test_bytes_transaction =
    $contract->_prepare_transaction($function_id, "testBytes", ["0x6279746573", \@dynamic_array, \@dynamic_array2, \@static_array]);

my $remix_bytes_test_data = path("./t/resources/abi_encoding/remix_testBytes.bin")->slurp_utf8;
$remix_bytes_test_data =~ s/^\s+|\s+$//g;

is $test_bytes_transaction->data, $remix_bytes_test_data, "correct bytes deploy encoding";

done_testing;

