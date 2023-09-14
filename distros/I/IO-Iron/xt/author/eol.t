use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
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
    't/lib/IO/Iron/Test/Util.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
