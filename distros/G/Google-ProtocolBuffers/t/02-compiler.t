
use Test::More tests => 7;
use Carp;
use strict;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

my @classes;

@classes = Google::ProtocolBuffers->parse("package my.test_case; message A{}");
is(scalar @classes, 1);
is($classes[0], 'My::TestCase::A');

@classes = Google::ProtocolBuffers->parse(
	"package my.test_case; message B{}", 
	{no_camel_case => 1}
);
is(scalar @classes, 1);
is($classes[0], 'my::test_case::B');


@classes = Google::ProtocolBuffers->parse("
     message Person {
       required string name  = 1;
       required int32 id     = 2; // Unique ID number for this person.
       optional string email = 3;

       enum PhoneType {
         MOBILE = 0;
         HOME = 1;
         WORK = 2;
       }

       message PhoneNumber {
         required string number = 1;
         optional PhoneType type = 2 [default = HOME];
       }

       repeated PhoneNumber phone = 4;
     }
");

is(scalar(@classes), 3);
@classes = sort @classes;
is_deeply(\@classes, ['Person', 'Person::PhoneNumber', 'Person::PhoneType']);


@classes = Google::ProtocolBuffers->parsefile("google/protobuf/unittest.proto", {include_dir => 't'});
is(scalar(@classes), 35);

