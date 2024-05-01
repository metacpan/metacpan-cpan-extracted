use Test::More;
use t::TestPsgi;
use t::TestLogger;
use Plack::Test;
use HTTP::Request;

my $logger = new_ok( 't::TestLogger' => [ {} ] );

$logger->debug("my_debug_1");
$logger->debug("my_debug_2");
$logger->info("my_info");

#diag explain $logger;
#is_deeply($logger->{_logs}, {}, "Logs were saved");
$logger->contains( "info",  "my_info" );
$logger->contains( "debug", qr/^my_debug_/ );

done_testing();
