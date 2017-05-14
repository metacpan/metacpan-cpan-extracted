#!perl

use strict;
use warnings;

use Test::More;
use MongoDB;
use Log::Dispatch;

my $HOST = $ENV{MONGOD} || "localhost";

my $conn = eval { MongoDB::Connection->new( host => $HOST ) };
plan skip_all => $@ if $@;

use_ok "Log::Dispatch::MongoDB";

my $db         = $conn->get_database('log-dispatch-mongodb-test');
my $collection = $db->get_collection('my_logger');

{
    my $log = Log::Dispatch->new;

    $log->add(
        Log::Dispatch::MongoDB->new(
            name       => 'my_logger',
            min_level  => 'debug',
            collection => $collection
        )
    );

    $log->debug("Debugging feature X");

    $log->log(
        level   => 'info',
        message => 'Started processing web page',
        info    => {
            referer     => 'http://www.example.org',
            user_agent  => 'Lynx',
            remote_addr => '10.0.0.1',
        }
    );
}

{
    my $message = $collection->find_one({ level => 'debug' });
    is($message->{level}, 'debug', '... got the right level');
    is($message->{message}, 'Debugging feature X', '... got the right message');
}

{
    my $message = $collection->find_one({ level => 'info' });
    is($message->{level}, 'info', '... got the right level');
    is($message->{message}, 'Started processing web page', '... got the right message');
    is_deeply(
        $message->{info},
        {
            referer     => 'http://www.example.org',
            user_agent  => 'Lynx',
            remote_addr => '10.0.0.1',
        },
        '... got the right additonal info'
    );
}

$db->drop(); # clean up

done_testing;
