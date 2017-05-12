package main;

use lib 't/lib','./lib';
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::SlotManager;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");

gstart($port);

my $cv = AE::cv;

my $sig = AE::signal 'INT'=> sub{ 
    DEBUG "TERM!!";
    $cv->send;
};

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
            min=>20, 
            max=>50,
            workleft=>0,
            }
        }
    }
);

$slotman->start();

my $res = $cv->recv;
undef($tt);
$slotman->stop;
undef($slotman);
gstop();

