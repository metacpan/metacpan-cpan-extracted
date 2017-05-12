#!/usr/bin/perl
use Test::More tests=>1;

use Log::Log4perl qw(:easy); 
Log::Log4perl->easy_init($ERROR);

use IPC::AnyEvent::Gearman;

use AnyEvent;

my $pid = fork();
if( !$pid )
{
    exec('gearmand -p 9999');
    die('cannot gearmand');
}
sleep(3);
my $cv = AE::cv;
my $ig = IPC::AnyEvent::Gearman->new(job_servers=>['localhost:9999']);

$ig->on_recv(sub{
    my $data = shift;
    is $data, 'TEST';
    $cv->send;
});

$ig->listen();

my $ig2 = IPC::AnyEvent::Gearman->new(job_servers=>['localhost:9999']);
$ig2->send($ig->channel,'TEST');

$cv->recv;
kill 9,$pid;

done_testing();
