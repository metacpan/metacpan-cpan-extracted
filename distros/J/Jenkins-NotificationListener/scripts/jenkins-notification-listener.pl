#!/usr/bin/env perl
use Net::Jenkins;
use Jenkins::NotificationListener;
use Getopt::Long;
use AnyEvent;
use JSON::XS;
use YAML;

my $host = '127.0.0.1';
my $port = 8888;
my $debug;
my $result = GetOptions(
    'host=s'   => \$host,
    'port=i'   => \$port,
    'd|debug'    => \$debug,
);

print "Listening at $host:$port...\n";
Jenkins::NotificationListener->new( host => $host , port => $port , on_notify => sub {
    my $payload = shift;   # Jenkins::Notification;

    if( $debug ) {
        my $args = decode_json $payload->raw_json;
        print "===== Payload Start =====\n";
        print Dump $args;
    }


    print $payload->name , " #" , $payload->build->number, " : " , $payload->status 
                , " : " , $payload->phase
                , " : " , $payload->url
                , "\n";

})->start;


AnyEvent->condvar->recv;
