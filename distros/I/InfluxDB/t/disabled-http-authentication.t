use strict;
use Test::More;

require InfluxDB;
InfluxDB->import;
note("disabled-http-authentication");
my $obj = new_ok("InfluxDB" => [
    host => '127.0.0.1',
    database => 'dummy',
]);

{
    my $obj = InfluxDB->new(
        username => 'user',
        password => 'pwd',
        database => 'dummy',
        host     => 'a.dummy.influxdb.host',
        port     => 8086,
    );
    my $url = $obj->_build_url(path => '');

    is($url, 'http://user:pwd@a.dummy.influxdb.host:8086', 'URL correctly formatted when user & pwd are set');
};

{
   my $obj = InfluxDB->new(
        database => 'dummy',
        host     => 'a.dummy.influxdb.host',
        port     => 8086,
    );
    my $url = $obj->_build_url(path => '');

    is($url, 'http://a.dummy.influxdb.host:8086', 'URL correctly formatted when user & pwd are NOT set');
};


done_testing;
