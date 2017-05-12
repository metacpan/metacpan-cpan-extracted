use Test::More tests => 6;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

my $r_filename = 't/MyTestR.pm';
unlink($r_filename);
ok(-w 't');
ok(! -f $r_filename);
Google::ProtocolBuffers->parse(
"
    package my.test;
    message R { optional int32 a = 1; extensions 10 to max; }
    extend  R { optional int32 b = 10; }
    message RFoo {
        extend  R { optional int32 c = 11; }
    }

",
    {   create_accessors    => 1,
        simple_extensions   => 1,
        generate_code       => $r_filename,
        package_name        => 'MyPackage::Name::NotUsed',
    }
);
ok(-f $r_filename);

my $u_filename = 't/MyTestU.pm';
unlink($u_filename);
ok(! -f $u_filename);
Google::ProtocolBuffers->parse(
"
    package my.test;
    message U { optional int32 a = 1; extensions 10 to max; }
    extend  U { optional int32 a = 10; }
    message UFoo {
        extend  U { optional int32 a = 11; }
    }
",
    { create_accessors => 1, generate_code => $u_filename }
);

my $t_filename = 't/UnitTest.pm';
unlink($t_filename);
ok(! -f $t_filename);
Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto",
    { include_dir => 't', generate_code => $t_filename, create_accessors => 1 }
);
ok(-f $t_filename);
