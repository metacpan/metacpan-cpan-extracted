use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/TestApp/lib";
    chdir("$FindBin::Bin/TestApp") || die;
}

use Jifty::Test tests => 4;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $server_url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new();
$mech->get_ok(Jifty::Test->web->url , "get /");
$mech->get_ok("/model_map"          , "get /model_map");
$mech->get_ok("/model_map/graph"    , "get /model_map/graph");

1;
