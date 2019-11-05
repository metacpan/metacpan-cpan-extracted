use strict;
use warnings;
use Test::Lib;
use Test::More 0.96;
use Test::Deep;
use Test::Exception;

use Dist::Zilla::PluginBundle::TestAirplane;

{
    my $bundle = Dist::Zilla::PluginBundle::TestAirplane->new(
        name    => 'connected',
        payload => { },
    );
    $bundle->configure;

    cmp_deeply(
        $bundle->plugins,
        [
            [
                "connected/PromptIfStale",
                'Dist::Zilla::Plugin::PromptIfStale',
                {}
            ]
        ],
        "Has PromptIfStale without payload"
    );
}

{
    my $bundle = Dist::Zilla::PluginBundle::TestAirplane->new(
        name    => 'connected',
        payload => { airplane => 0 },
    );
    $bundle->configure;

    cmp_deeply(
        $bundle->plugins,
        [
            [
                "connected/PromptIfStale",
                'Dist::Zilla::Plugin::PromptIfStale',
                {}
            ]
        ],
        ".. also with a payload",
    );
}

{
    my $bundle = Dist::Zilla::PluginBundle::TestAirplane->new(
        name    => 'airplane',
        payload => { airplane => 1 },
    );
    $bundle->configure;

    cmp_deeply(
        $bundle->plugins,
        [
            [
                "airplane/BlockRelease",
                'Dist::Zilla::Plugin::BlockRelease',
                {}
            ]
        ],
        ".. not with airplane mode, we have BlockRelease instead"
    );
}

{
    my $bundle = Dist::Zilla::PluginBundle::TestAirplane->new(
        name          => 'airplane',
        payload       => { airplane => 1 },
        airplane_type => 'array',
    );
    $bundle->configure;

    cmp_deeply(
        $bundle->plugins,
        [
            [
                "airplane/BlockRelease",
                'Dist::Zilla::Plugin::BlockRelease',
                {}
            ]
        ],
        ".. add_plugin->([['Plugin']]) also works",
    );
}

{
    my $bundle = Dist::Zilla::PluginBundle::TestAirplane->new(
        name          => 'airplane',
        payload       => { airplane => 1 },
        airplane_type => 'unsupported',
    );
    throws_ok(sub {
        $bundle->configure;
        }, qr/unable/,
    );
}
done_testing;
