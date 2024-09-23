use utf8;

use Test2::V0;
use FindBin;
use lib "${FindBin::Bin}/proto";

package Foo {
  use Google::Protobuf::Loader;
  use Test2::V0;
  try_ok { eval 'use Proto::Main::Simple;'; die $@ if $@ };
  is(Proto::Main::Simple->message_descriptor()->full_name(), 'main.Simple');
}

package Bar {
  use Test2::V0;
  like(dies { eval 'use Proto::Main::Test;'; die $@ if $@ }, qr{Proto/Main/Test.pm});
}

done_testing();
