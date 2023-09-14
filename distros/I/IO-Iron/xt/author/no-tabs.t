use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Changes',
    'LICENSE',
    'META.json',
    'META.yml',
    'Makefile.PL',
    'README',
    'lib/IO/Iron.pm',
    'lib/IO/Iron/ClientBase.pm',
    'lib/IO/Iron/Common.pm',
    'lib/IO/Iron/Connection.pm',
    'lib/IO/Iron/Connector.pm',
    'lib/IO/Iron/ConnectorBase.pm',
    'lib/IO/Iron/IronCache/Api.pm',
    'lib/IO/Iron/IronCache/Cache.pm',
    'lib/IO/Iron/IronCache/Client.pm',
    'lib/IO/Iron/IronCache/Item.pm',
    'lib/IO/Iron/IronCache/Policy.pm',
    'lib/IO/Iron/IronMQ/Api.pm',
    'lib/IO/Iron/IronMQ/Client.pm',
    'lib/IO/Iron/IronMQ/Message.pm',
    'lib/IO/Iron/IronMQ/Queue.pm',
    'lib/IO/Iron/IronWorker/Api.pm',
    'lib/IO/Iron/IronWorker/Client.pm',
    'lib/IO/Iron/IronWorker/Task.pm',
    'lib/IO/Iron/PolicyBase.pm',
    'lib/IO/Iron/PolicyBase/CharacterGroup.pm',
    't/Iron/client_readconfig.t',
    't/Iron/common.t',
    't/Iron/load.t',
    't/IronCache/cache_policy.t',
    't/IronCache/cache_policy2.t',
    't/IronCache/load.t',
    't/IronMQ/load.t',
    't/IronWorker/load.t',
    't/lib/IO/Iron/Test/Util.pm',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-linkcheck.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/synopsis.t',
    'xt/author/test-version.t',
    'xt/release/cpan-changes.t',
    'xt/release/kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
