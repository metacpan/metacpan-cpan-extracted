use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Ethereum/RPC/Client.pm',
    'lib/Ethereum/RPC/Client.pod',
    'lib/Ethereum/RPC/Contract.pm',
    'lib/Ethereum/RPC/Contract.pod',
    'lib/Ethereum/RPC/Contract/ContractResponse.pm',
    'lib/Ethereum/RPC/Contract/ContractResponse.pod',
    'lib/Ethereum/RPC/Contract/ContractTransaction.pm',
    'lib/Ethereum/RPC/Contract/ContractTransaction.pod',
    'lib/Ethereum/RPC/Contract/Helper/ImportHelper.pm',
    'lib/Ethereum/RPC/Contract/Helper/UnitConversion.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/00_web3_clientVersion.t',
    't/ABI_encoding.t',
    't/Crowdsale.t',
    't/ERC20.t'
);

notabs_ok($_) foreach @files;
done_testing;
