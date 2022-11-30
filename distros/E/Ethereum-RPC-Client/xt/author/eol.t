use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_web3_clientVersion.t',
    't/ABI_encoding.t',
    't/Crowdsale.t',
    't/ERC20.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/resources/SimpleCrowdsale.json',
    't/resources/SimpleToken.json',
    't/resources/abi_encoding/abi_encoding.abi',
    't/resources/abi_encoding/abi_encoding.bin',
    't/resources/abi_encoding/remix_deploy.bin',
    't/resources/abi_encoding/remix_testBytes.bin',
    't/resources/abi_encoding/remix_testString.bin',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
