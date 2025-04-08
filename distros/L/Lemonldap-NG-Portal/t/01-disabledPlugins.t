use warnings;
use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

subtest "Disable module by full name" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                loginHistoryEnabled => 1,
                disabledPlugins => "Lemonldap::NG::Portal::Plugins::History",
            }
        }
    );

    ok(
        !exists(
            $client->p->loadedModules->{
                "Lemonldap::NG::Portal::Plugins::History"}
        ),
        "Plugin was not loaded"
    );
};

subtest "Disable module by short name" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                loginHistoryEnabled => 1,
                disabledPlugins     => "::Plugins::History",
            }
        }
    );

    ok(
        !exists(
            $client->p->loadedModules->{
                "Lemonldap::NG::Portal::Plugins::History"}
        ),
        "Plugin was not loaded"
    );
};

clean_sessions();

done_testing();
