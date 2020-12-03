use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/kraken-cli.pl',
    'lib/Finance/Crypto/Exchange/Kraken.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Private.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Private/User/Data.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Private/User/Funding.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Private/User/Trading.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Private/Websockets.pm',
    'lib/Finance/Crypto/Exchange/Kraken/REST/Public.pm',
    't/00-compile.t',
    't/01-basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
