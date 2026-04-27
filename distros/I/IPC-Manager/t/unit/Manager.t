use Test2::V0;
use Test2::Require::Module 'Compress::Zstd' => '0.20';

use IPC::Manager qw/ipcm_default_serializer ipcm_spawn ipcm_connect/;
use IPC::Manager::Serializer::JSON;
use IPC::Manager::Serializer::JSON::Zstd;
use Scalar::Util qw/blessed refaddr/;

subtest 'string serializer parses to full class name' => sub {
    is(
        IPC::Manager::_parse_serializer('JSON'),
        'IPC::Manager::Serializer::JSON',
        "short name expanded",
    );

    is(
        IPC::Manager::_parse_serializer('IPC::Manager::Serializer::JSON'),
        'IPC::Manager::Serializer::JSON',
        "fully qualified passthrough",
    );

    is(
        IPC::Manager::_serializer_class('+My::Custom'),
        'My::Custom',
        "leading + strips and skips prefix",
    );
};

subtest 'arrayref serializer constructs and caches' => sub {
    my $a = IPC::Manager::_parse_serializer(['JSON::Zstd', level => 5]);
    my $b = IPC::Manager::_parse_serializer(['JSON::Zstd', level => 5]);
    my $c = IPC::Manager::_parse_serializer(['JSON::Zstd', level => 9]);

    ok(blessed($a) && $a->isa('IPC::Manager::Serializer::JSON::Zstd'), "got blessed instance");
    is(refaddr($a), refaddr($b), "same args reuse cached instance");
    isnt(refaddr($a), refaddr($c), "different args produce different instance");

    is($a->level, 5, "level honored");
    is($c->level, 9, "second instance has its own level");
};

subtest 'blessed serializer passthrough' => sub {
    my $inst = IPC::Manager::Serializer::JSON::Zstd->new(level => 7);
    my $out  = IPC::Manager::_parse_serializer($inst);
    is(refaddr($out), refaddr($inst), "blessed instance returned as-is");
};

subtest 'cinfo round-trip with arrayref serializer spec' => sub {
    require IPC::Manager::Spawn;
    require IPC::Manager::Client::LocalMemory;

    my $route = IPC::Manager::Client::LocalMemory->spawn();
    my $inst  = IPC::Manager::Serializer::JSON::Zstd->new(level => 6);
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => 'IPC::Manager::Client::LocalMemory',
        route      => $route,
        serializer => $inst,
        guard      => 0,
    );

    my $info = $spawn->info;
    ok($info, "info string produced");

    my $decoded = IPC::Manager::Serializer::JSON->deserialize($info);
    is(
        $decoded->[1],
        ['IPC::Manager::Serializer::JSON::Zstd', level => 6],
        "info encodes serializer as [class, %args]",
    );

    # Round-trip: parse cinfo, get instance back from cache
    my @parsed = IPC::Manager::_parse_cinfo($info);
    isa_ok($parsed[1], ['IPC::Manager::Serializer::JSON::Zstd'], "cinfo parses serializer to instance");
    is($parsed[1]->level, 6, "cached instance has matching level");

    IPC::Manager::Client::LocalMemory->unspawn($route);
};

subtest 'spawn with arrayref serializer round-trips' => sub {
    my $spawn = ipcm_spawn(
        protocol   => 'LocalMemory',
        serializer => ['JSON::Zstd', level => 4],
        guard      => 0,
    );
    isa_ok($spawn->serializer, ['IPC::Manager::Serializer::JSON::Zstd'], "spawn serializer is instance");
    is($spawn->serializer->level, 4, "instance carries configured level");

    my $info  = $spawn->info;
    my @cinfo = IPC::Manager::_parse_cinfo($info);
    isa_ok($cinfo[1], ['IPC::Manager::Serializer::JSON::Zstd'], "round-tripped through info string");
    is($cinfo[1]->level, 4, "round-trip preserves level");

    $spawn->unspawn;
};

done_testing;
