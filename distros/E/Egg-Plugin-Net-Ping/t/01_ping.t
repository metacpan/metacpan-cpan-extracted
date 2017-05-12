use Test::More tests => 4;
use Egg::Helper;

my $e= Egg::Helper->run( Vtest => {
  vtest_plugins=> [qw/ Net::Ping /],
  vtest_config=> {
    plugin_net_ping => {
      timeout => 1,
      retry   => 3,
      wait    => 0.2,
      },
    },
  });

ok my $result= $e->ping('127.0.0.1');
is $result, 3;
ok $result= $e->ping('127.0.0.1', retry=> 2 );
is $result, 2;
