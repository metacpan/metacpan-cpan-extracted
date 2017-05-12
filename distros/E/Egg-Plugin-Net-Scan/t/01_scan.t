use Test::More tests => 3;
use Egg::Helper;

my $e= Egg::Helper->run( Vtest => {
  vtest_plugins=> [qw/ Net::Scan /],
  });

ok my $scan= $e->port_scan('127.0.0.1', 666, timeout=> 1 ),
   q{my $scan= $e->port_scan('127.0.0.1', 666, timeout=> 1 )};
ok $scan->is_error, q{$scan->is_error};
like $scan->is_error, qr{Cannot\s+connect\s+\d+},
   q{$scan->is_error, qr{Cannot\s+connect\s+\d+}};
