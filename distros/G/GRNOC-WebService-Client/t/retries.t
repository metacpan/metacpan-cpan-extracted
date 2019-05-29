use Test::More tests => 9;

use strict;
use GRNOC::WebService::Client;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Helper;

my $counter_file = "$FindBin::Bin/count.json";
my $retries;
my $retry_interval;
my $res;
my $svc = GRNOC::WebService::Client->new( url => "http://localhost:8529/hello.cgi",
                                          raw_output => 1,
                                          retry_error_codes => { '408' => 1,
                                                                 '429' => 1,
                                                                 '503' => 1       
                                                                 }                     
                                                            );


#verify default retries is 0
$retries = $svc->get_retries();
is($retries, 0, "Default retries is zero");

#verify default retry interval is 5 secs
$retry_interval = $svc->get_retry_interval();
is($retry_interval, 5 , "Default retry interval is 5 secs");

#clear the counter
Helper::clear_counter( $counter_file);

#should not be retried
$svc->foo( status => '408' );

$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 1, "408 - tried once" );


#clear the counter
Helper::clear_counter( $counter_file);

#Set the number of retries to 3
$svc->set_retries(3);

#Set retry interval to 2 seconds
$svc->set_retry_interval(2);


$svc->foo( status => '408' );

#get the retry counter
$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 4, "408 - retried 3 times");

#clear the counter
Helper::clear_counter( $counter_file);

#verify default retries is 0                                                                                         
$retries = $svc->get_retries();                                                                                     

is($retries, 3, "No of retries is 3");

#should not be retried
$svc->foo( status => '404' );

#get the retry counter
$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 1, "404 - tried once" );

#clear the counter                                                                                                    
Helper::clear_counter( $counter_file);

#test failure twice in a row
$svc->foo( status => '429');

$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 4, "429 - retried thrice");

Helper::clear_counter( $counter_file );

$svc->foo( status => '503');

$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 4, "503 - retried thrice");

#clear the counter
Helper::clear_counter( $counter_file );

$svc->set_retries( 5 );
#retry twice and return 200 the thrird time
$svc->foo( status => '408', max_retries => '2');

#get the retry counter
$res = Helper::get_counter( $counter_file );
is( $res->{'retries'}, 3, "408 - retries twice" );