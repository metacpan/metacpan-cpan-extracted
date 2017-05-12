use strict;
use warnings;
use HTTP::Request::FromLog;
use Data::Dumper;
use YAML;
use Test::More tests => 4;

my @test_data = YAML::Load( join '', <DATA> );

{
    my %conf = ( host => 'localhost', );
    my $log2hr = HTTP::Request::FromLog->new(%conf);
    for (@test_data) {
        my $log = $_->{log};
        my $obj;
        eval( $_->{obj} );
        my $http_request = $log2hr->convert($log);
        isa_ok( $http_request, 'HTTP::Request' );
        is_deeply( $http_request, $obj, "object is deeply matched" );
    }
}

__DATA__
---
log: 192.168.1.1 - - [26/Jun/2008:19:13:53 +0900] "GET /test.html HTTP/1.1" 200 123 "-" "PEAR HTTP_Request class ( http://pear.php.net/ )"
obj: |
  $obj = bless(
      {
          '_content' => '',
          '_uri'     => bless(
              do { \( my $o = 'http://localhost/test.html' ) }, 'URI::http'
          ),
          '_headers' => bless(
              {
                  'user-agent' =>
                    'PEAR HTTP_Request class ( http://pear.php.net/ )',
                  'referer' => '-',
                  'host'    => 'localhost'
              },
              'HTTP::Headers'
          ),
          '_method' => 'GET'
      },
      'HTTP::Request'
  );
---
log: 127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326
obj: |
  $obj = bless(
      {
          '_content' => '',
          '_uri'     => bless(
              do { \( my $o = 'http://localhost/apache_pb.gif' ) }, 'URI::http'
          ),
          '_headers' => bless( { 'host' => 'localhost' }, 'HTTP::Headers' ),
          '_method'  => 'GET'
      },
      'HTTP::Request'
  );



