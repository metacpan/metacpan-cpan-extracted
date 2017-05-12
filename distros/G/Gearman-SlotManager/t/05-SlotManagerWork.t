package main;

use lib 't/lib';
use Test::More tests=>12;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::SlotManager;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");

use_ok('Gearman::Server');
gstart($port);

my $cv = AE::cv;

my $sig = AE::signal 'INT'=> sub{ 
DEBUG "TERM!!";
$cv->send;
};

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};
my $slotman = Gearman::SlotManager->new(
    config=>
    {
        global=>{
            job_servers=>\@js,
            libs=>['t/lib','./lib'],
            max=>3,
            },
        slots=>{
            'TestWorker'=>{
            min=>3, 
            max=>5,
            workleft=>10,
            }
        }
    },
    port=>55595,
);

$slotman->start();

my $c = gearman_client @js;
foreach (1 .. 10){
    my $n = $_;
    my $str = "HELLO$n";
    DEBUG 'cl';

    $c->add_task(
        'TestWorker::reverse'=>$str,
        on_complete=>sub{is $_[1], reverse($str),"check $n";},
    );
}
my $tt = AE::timer 5,0,sub{ 
    $cv->send;
};

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($tt);
$slotman->stop;
undef($slotman);
gstop();

done_testing();
