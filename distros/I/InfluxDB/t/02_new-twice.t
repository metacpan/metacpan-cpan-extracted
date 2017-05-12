use strict;
use Test::More;

require InfluxDB;
InfluxDB->import;
note("new");
my $obj = new_ok("InfluxDB" => [
    host => '127.0.0.1',
    username => 'dummy',
    password => 'dummy',
    database => 'dummy',
]);

my $obj2 = new_ok("InfluxDB" => [
    host => '127.0.0.1',
    username => 'dummy',
    password => 'dummy',
    database => 'dummy',
]);

# diag explain $obj

done_testing;
