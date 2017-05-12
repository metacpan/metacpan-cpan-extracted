
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Finance/Bank/Bankwest.pm',
    'lib/Finance/Bank/Bankwest/Account.pm',
    'lib/Finance/Bank/Bankwest/Error.pm',
    'lib/Finance/Bank/Bankwest/Error/BadResponse.pm',
    'lib/Finance/Bank/Bankwest/Error/ExportFailed.pm',
    'lib/Finance/Bank/Bankwest/Error/ExportFailed/UnknownReason.pm',
    'lib/Finance/Bank/Bankwest/Error/NotLoggedIn.pm',
    'lib/Finance/Bank/Bankwest/Error/NotLoggedIn/BadCredentials.pm',
    'lib/Finance/Bank/Bankwest/Error/NotLoggedIn/SubsequentLogin.pm',
    'lib/Finance/Bank/Bankwest/Error/NotLoggedIn/Timeout.pm',
    'lib/Finance/Bank/Bankwest/Error/NotLoggedIn/UnknownReason.pm',
    'lib/Finance/Bank/Bankwest/Error/ServiceMessage.pm',
    'lib/Finance/Bank/Bankwest/Error/WithResponse.pm',
    'lib/Finance/Bank/Bankwest/Parser/Accounts.pm',
    'lib/Finance/Bank/Bankwest/Parser/Login.pm',
    'lib/Finance/Bank/Bankwest/Parser/Logout.pm',
    'lib/Finance/Bank/Bankwest/Parser/ServiceMessage.pm',
    'lib/Finance/Bank/Bankwest/Parser/TransactionExport.pm',
    'lib/Finance/Bank/Bankwest/Parser/TransactionSearch.pm',
    'lib/Finance/Bank/Bankwest/Parsers.pm',
    'lib/Finance/Bank/Bankwest/Session.pm',
    'lib/Finance/Bank/Bankwest/SessionFromLogin.pm',
    'lib/Finance/Bank/Bankwest/Transaction.pm'
);

notabs_ok($_) foreach @files;
done_testing;
