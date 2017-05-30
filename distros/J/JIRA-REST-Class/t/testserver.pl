
use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

my $port = shift || die;
use TestServer;
TestServer->new($port)->run();
