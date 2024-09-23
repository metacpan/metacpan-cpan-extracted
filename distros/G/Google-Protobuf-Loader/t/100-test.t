use utf8;

use Google::Protobuf::Loader;
use Test2::V0;
use FindBin;
use lib "${FindBin::Bin}/proto";

ok(eval "use Proto::Main::Simple;1;");

is(Proto::Main::Simple->message_descriptor()->full_name(), 'main.Simple');

ok(eval "use Proto::Main::Test;1;");

is(Proto::Main::Test->message_descriptor()->full_name(), 'main.Test');
is(Proto::Foo::Bar->message_descriptor()->full_name(), 'foo.Bar');

my $pb = Proto::Main::Simple->new();
$pb->set_name("foo");
is($pb->get_name(), "foo");

done_testing();
