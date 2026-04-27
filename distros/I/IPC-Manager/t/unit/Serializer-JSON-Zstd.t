use Test2::V0;
use Test2::Require::Module 'Compress::Zstd' => '0.20';

use IPC::Manager::Serializer::JSON::Zstd;

subtest 'viable' => sub {
    ok(IPC::Manager::Serializer::JSON::Zstd->viable, "viable when Compress::Zstd is loadable");
};

subtest 'isa JSON' => sub {
    isa_ok('IPC::Manager::Serializer::JSON::Zstd', ['IPC::Manager::Serializer::JSON']);
    isa_ok('IPC::Manager::Serializer::JSON::Zstd', ['IPC::Manager::Serializer']);
};

subtest 'round-trip hash' => sub {
    my $data  = {foo => 'bar', num => 42};
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($data);
    ok(defined $bytes, "serialize returns bytes");
    my $back = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes);
    is($back, $data, "round-trip preserves data");
};

subtest 'round-trip array' => sub {
    my $data  = [1, 'two', {three => 3}];
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($data);
    my $back  = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes);
    is($back, $data, "round-trip array");
};

subtest 'round-trip scalar' => sub {
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize("hello");
    my $back  = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes);
    is($back, "hello", "round-trip scalar");
};

subtest 'convert_blessed' => sub {
    require IPC::Manager::Message;
    my $msg   = IPC::Manager::Message->new(from => 'a', to => 'b', content => 'x');
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($msg);
    my $back  = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes);
    is($back->{from}, 'a', "blessed object serialized via TO_JSON");
};

subtest 'compresses repetitive payload' => sub {
    my $data  = {blob => 'A' x 4096};
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($data);
    my $json  = IPC::Manager::Serializer::JSON->serialize($data);
    ok(length($bytes) < length($json), "zstd output is smaller than raw JSON for repetitive input")
        or diag("zstd=", length($bytes), " json=", length($json));
    my $back = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes);
    is($back, $data, "round-trip large payload");
};

subtest 'rejects truncated payload' => sub {
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize({a => 1});
    my $bad   = substr($bytes, 0, length($bytes) - 4);
    like(
        dies { IPC::Manager::Serializer::JSON::Zstd->deserialize($bad) },
        qr/Failed to decompress|decompress|Compress::Zstd/i,
        "truncated payload throws",
    );
};

subtest 'instance with custom level round-trips' => sub {
    my $s    = IPC::Manager::Serializer::JSON::Zstd->new(level => 9);
    my $data = {foo => 'bar', payload => 'X' x 1024};
    my $bytes = $s->serialize($data);
    my $back  = $s->deserialize($bytes);
    is($back, $data, "level=9 instance round-trips");
    is($s->level, 9, "level accessor reflects ctor arg");
};

subtest 'instance default level is 3' => sub {
    my $s = IPC::Manager::Serializer::JSON::Zstd->new();
    is($s->level, 3, "default level 3");
    is($s->dictionary, undef, "default dictionary undef");
};

subtest 'higher level produces smaller output for compressible data' => sub {
    my $data  = {blob => join('', map { 'abcdefgh' x 64 } 1 .. 8)};
    my $small = IPC::Manager::Serializer::JSON::Zstd->new(level => 1)->serialize($data);
    my $big   = IPC::Manager::Serializer::JSON::Zstd->new(level => 19)->serialize($data);
    ok(length($big) <= length($small), "level=19 not larger than level=1")
        or diag("l1=", length($small), " l19=", length($big));
};

subtest 'bytes from class form decodable via class form' => sub {
    my $data  = {hello => "world"};
    my $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($data);
    my $inst  = IPC::Manager::Serializer::JSON::Zstd->new(level => 3);
    my $back  = $inst->deserialize($bytes);
    is($back, $data, "instance with no dict can decode class-form output (both use plain compress)");
};

subtest 'TO_JSON returns class+args round-trip' => sub {
    require IPC::Manager::Serializer::JSON;
    my $s = IPC::Manager::Serializer::JSON::Zstd->new(level => 5);
    my $json = IPC::Manager::Serializer::JSON->serialize($s);
    my $back = IPC::Manager::Serializer::JSON->deserialize($json);
    is(
        $back,
        ['IPC::Manager::Serializer::JSON::Zstd', level => 5],
        "TO_JSON emits class + non-default args",
    );

    my $defaults = IPC::Manager::Serializer::JSON::Zstd->new();
    my $json2    = IPC::Manager::Serializer::JSON->serialize($defaults);
    my $back2    = IPC::Manager::Serializer::JSON->deserialize($json2);
    is(
        $back2,
        ['IPC::Manager::Serializer::JSON::Zstd'],
        "default-level instance round-trips bare class name",
    );
};

subtest 'dictionary support' => sub {
    require File::Temp;
    require Compress::Zstd::CompressionDictionary;

    my ($fh, $path) = File::Temp::tempfile('ipcm-zstd-dict-XXXXXX', UNLINK => 1);
    binmode $fh;
    # Write a small repetitive blob — not a "trained" dict, but loadable as one.
    print $fh ('foobar' x 256);
    close $fh;

    my $s    = IPC::Manager::Serializer::JSON::Zstd->new(level => 3, dictionary => $path);
    my $data = {note => 'foobar foobar foobar foobar foobar foobar', n => 7};

    my $bytes = $s->serialize($data);
    ok(defined $bytes && length($bytes) > 0, "dictionary serialize produces output");

    my $back = $s->deserialize($bytes);
    is($back, $data, "round-trip with dictionary");

    is($s->dictionary, $path, "dictionary accessor returns path");

    my $no_dict = IPC::Manager::Serializer::JSON::Zstd->new(level => 3);
    like(
        dies { $no_dict->deserialize($bytes) },
        qr/Failed to decompress/i,
        "dict-encoded payload undecodable without dictionary",
    );
};

done_testing;
