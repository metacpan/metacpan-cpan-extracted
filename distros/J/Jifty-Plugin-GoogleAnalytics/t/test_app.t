use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/TestApp/lib";
    chdir("$FindBin::Bin/TestApp") || die;
}

use Jifty::Test tests => 11;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $server_url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok(Jifty::Test->web->url , "get /");
$mech->content_like( qr|google-analytics.com/ga.js|, "like google analytics js. (mason)");

$mech->get_ok("/test_mason_disable", "get /test_mason_disable");
$mech->content_unlike( qr|google-analytics.com/ga.js|, "unlike google analytics js. (mason)");

$mech->get_ok("/test_td_enable", "get /test_td_enable");
$mech->content_like( qr|google-analytics.com/ga.js|, "like google analytics js. (td)");

$mech->get_ok("/test_td_disable", "get /test_td_disable");
$mech->content_unlike( qr|google-analytics.com/ga.js|, "unlike google analytics js. (td)");

$mech->get_ok("/test_dispatcher", "get /test_dispatcher");
$mech->content_unlike( qr|google-analytics.com/ga.js|, "unlike google analytics js. (dispatcher)");

1;
