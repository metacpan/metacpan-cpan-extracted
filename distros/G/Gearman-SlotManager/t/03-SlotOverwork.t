package main;

use lib 't/lib';
use Test::More tests=>5;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::Slot;
use Scalar::Util qw(weaken);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($ERROR);
Log::Log4perl->easy_init($ERROR);
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $slot = Gearman::Slot->new(
    job_servers=>\@js,
    libs=>['t/lib','./lib'],
    workleft=>1,
    worker_package=>'TestWorker',
    worker_channel=>'child'
);

$slot->start();

my $cpid = $slot->worker_pid;

my $c = gearman_client @js;
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';

    $c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
        my $job = shift;
        my $res = shift;
        is $res,'OLLEH','client result ok';

        isnt $slot->worker_pid, $cpid,'worker respawned';
        $cv->send;
    });
});

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
$slot->stop();
undef($t);
undef($c);
undef($slot);
gstop();

done_testing();
