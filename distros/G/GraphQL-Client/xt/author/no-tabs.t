use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/graphql',
    'lib/GraphQL/Client.pm',
    'lib/GraphQL/Client/CLI.pm',
    'lib/GraphQL/Client/http.pm',
    'lib/GraphQL/Client/https.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/cli.t',
    't/client.t',
    't/http.t',
    't/https.t',
    't/lib/MockTransport.pm',
    't/lib/MockUA.pm',
    'xt/author/clean-namespaces.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/consistent-version.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
