use Test2::V0;

use IPC::Manager::Serializer::JSON;

subtest 'round-trip hash' => sub {
    my $data = {foo => 'bar', num => 42};
    my $json = IPC::Manager::Serializer::JSON->serialize($data);
    ok(defined $json, "serialize returns a string");
    is(ref($json), '', "serialize returns a plain string");
    my $back = IPC::Manager::Serializer::JSON->deserialize($json);
    is($back, $data, "round-trip preserves data");
};

subtest 'round-trip array' => sub {
    my $data = [1, 'two', {three => 3}];
    my $json = IPC::Manager::Serializer::JSON->serialize($data);
    my $back = IPC::Manager::Serializer::JSON->deserialize($json);
    is($back, $data, "round-trip array");
};

subtest 'round-trip scalar' => sub {
    my $json = IPC::Manager::Serializer::JSON->serialize("hello");
    my $back = IPC::Manager::Serializer::JSON->deserialize($json);
    is($back, "hello", "round-trip scalar");
};

subtest 'isa Serializer' => sub {
    isa_ok('IPC::Manager::Serializer::JSON', ['IPC::Manager::Serializer']);
};

subtest 'convert_blessed' => sub {
    require IPC::Manager::Message;
    my $msg = IPC::Manager::Message->new(from => 'a', to => 'b', content => 'x');
    my $json = IPC::Manager::Serializer::JSON->serialize($msg);
    my $back = IPC::Manager::Serializer::JSON->deserialize($json);
    is($back->{from}, 'a', "blessed object serialized via TO_JSON");
};

done_testing;
