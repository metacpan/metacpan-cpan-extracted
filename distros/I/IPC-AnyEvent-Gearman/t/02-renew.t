#!/usr/bin/perl
use Test::More tests=>7;
use Log::Log4perl qw(:easy); 
Log::Log4perl->easy_init($ERROR);

use IPC::AnyEvent::Gearman;

use AnyEvent;

my $ig = IPC::AnyEvent::Gearman->new(job_servers=>['localhost:9999']);

isnt $ig->channel,$$;

$ig->listen();
my $worker = $ig->worker;
my $client = $ig->client;

$ig->channel('MYCH');
my $client2 = $ig->client;
my $worker2 = $ig->worker;
isnt $worker, $worker2, 'renew worker by pid';
is $client, $client, 'renew not client by pid';

$worker = $ig->worker;
$client = $ig->client;
$ig->channel("test_prefix");
$client2 = $ig->client;
$worker2 = $ig->worker;
isnt $worker, $worker2, 'renew worker by prefix';
is $client, $client, 'renew not client by prefix';

$worker = $ig->worker;
$client = $ig->client;
$ig->job_servers(['localhost:9999']);
$client2 = $ig->client;
$worker2 = $ig->worker;
isnt $worker, $worker2, 'renew worker by job_servers';
isnt $client, $client2, 'renew client bt job_servers';


done_testing();

