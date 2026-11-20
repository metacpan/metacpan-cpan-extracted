use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTTP/Message/Signature.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-base.t',
    't/01-structured-split.t',
    't/02-test-data.t',
    't/web_bot_auth_architecture_v2.json'
);

notabs_ok($_) foreach @files;
done_testing;
