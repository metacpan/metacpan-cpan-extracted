use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Ethereum/RPC/Client.pm',
    'lib/Ethereum/RPC/Contract.pm',
    'lib/Ethereum/RPC/Contract/ContractResponse.pm',
    'lib/Ethereum/RPC/Contract/ContractTransaction.pm',
    'lib/Ethereum/RPC/Contract/Helper/ImportHelper.pm',
    'lib/Ethereum/RPC/Contract/Helper/UnitConversion.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
