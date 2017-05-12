use Test::More tests => 27;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Math::BigInt;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't' }
);

is(ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), 1);
is(ProtobufUnittest::TestAllTypes::NestedEnum::BAR(), 2);
is(ProtobufUnittest::TestAllTypes::NestedEnum::BAZ(), 3);

ProtobufUnittest::TestAllTypes::NestedEnum->import(':constants');
is(FOO(), 1);
is(BAR(), 2);
is(BAZ(), 3);

ProtobufUnittest::ForeignEnum->import(':constants');
is(FOREIGN_FOO(), 4);
is(FOREIGN_BAR(), 5);
is(FOREIGN_BAZ(), 6);

{
    no warnings 'redefine'; ## doesn't help, since redefine occurs
                            ## in Exporter block of code

    package ImportHere;
    ProtobufUnittest::TestEnumWithDupValue->import(':constants');
    package main;  

    is(ImportHere::FOO1(), 1);
    is(ImportHere::BAR1(), 2);
    is(ImportHere::BAZ(), 3); ## redefined!
    is(ImportHere::FOO2(), 1);
    is(ImportHere::BAR2(), 2);
}
    
ProtobufUnittest::TestSparseEnum->import(':constants');
is(SPARSE_A(), 123);
is(SPARSE_B(), 62374);
is(SPARSE_C(), 12589234);
is(SPARSE_D(), -15);
is(SPARSE_E(), -53452);
is(SPARSE_F(), 0);
is(SPARSE_G(), 2);


ProtobufUnittestImport::ImportEnum->import(':constants');
is(IMPORT_FOO(), 7);
is(IMPORT_BAR(), 8);
is(IMPORT_BAZ(), 9);

Google::ProtocolBuffers->parsefile(
    "extra/enumalias.proto", 
    { include_dir => 't' }
);

is(EnumAlias::Status::UNKNOWN(), 0);
is(EnumAlias::Status::STARTED(), 1);
is(EnumAlias::Status::RUNNING(), 1);
