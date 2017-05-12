use Test::More tests => 7;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Math::BigInt;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't', create_accessors=>1 }
);

my $data = ProtobufUnittest::TestAllTypes->new({optional_int32 => 10});
is($data->optional_int32, 10);

$data->optional_int32(100);
is($data->optional_int32, 100);


$data->optional_int32(20);
is($data->optional_int32, 20);

$data->optional_int32(0);
is($data->optional_int32, 0);


$data->RepeatedGroup([
    ProtobufUnittest::TestAllTypes::RepeatedGroup->new({a => 11 }),
    ProtobufUnittest::TestAllTypes::RepeatedGroup->new({a => 12 }),
    ProtobufUnittest::TestAllTypes::RepeatedGroup->new({a => 13 }),
]);

is($data->RepeatedGroup->[0]->{a}, 11);
is($data->RepeatedGroup->[1]->{a}, 12);
is($data->RepeatedGroup->[2]->{a}, 13);
