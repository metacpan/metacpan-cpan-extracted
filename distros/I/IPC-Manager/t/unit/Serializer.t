use Test2::V0;

use IPC::Manager::Serializer;

subtest 'base class methods croak' => sub {
    like(
        dies { IPC::Manager::Serializer->serialize("x") },
        qr/Not Implemented/,
        "serialize croaks",
    );
    like(
        dies { IPC::Manager::Serializer->deserialize("x") },
        qr/Not Implemented/,
        "deserialize croaks",
    );
};

done_testing;
