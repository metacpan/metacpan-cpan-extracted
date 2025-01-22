use warnings;
use strict;
use Test::More;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            customPlugins =>
              "t::PluginEntryPoints::Consumer t::PluginEntryPoints::Target"
        }
    }
);

is_deeply(
    $client->p->getService("MyListeningService")->get_log,
    [
        [ 't::PluginEntryPoints::Target', 'param1' ],
        [ 't::PluginEntryPoints::Target', 'param2' ],
        [ 't::PluginEntryPoints::Target', 'param3' ]
    ]

    ,
    "Check that entrypoints were called"
      . " in the correct order with correct params"
);

done_testing();
