use utf8;

use Google::Protobuf::Loader map_options => {accessor_style => 'single_accessor'};
use Test2::V0;
use FindBin;
use lib "${FindBin::Bin}/proto";

ok(eval "use Proto::Main::Simple;1;");

is(Proto::Main::Simple->message_descriptor()->full_name(), 'main.Simple');

ok(eval "use Proto::Main::Test;1;");

is(Proto::Main::Test->message_descriptor()->full_name(), 'main.Test');
is(Proto::Foo::Bar->message_descriptor()->full_name(), 'foo.Bar');

my $pb = Proto::Main::Simple->new();
$pb->name("foo");
is($pb->name(), "foo");

done_testing();
