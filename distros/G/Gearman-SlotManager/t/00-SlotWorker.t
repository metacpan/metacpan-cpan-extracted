package main;

use lib 't/lib';
use Test::More tests=>3;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use TestWorker;
use POSIX;
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $ww = fork;
if( !$ww ){
    my $w = TestWorker->new(job_servers=>\@js,cv=>$cv,parent_channel=>undef, channel=>'test');
    $w->work;
}


my $c = gearman_client @js;
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';
    
#    kill SIGINT,$$;
    $cv->send;
});




my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($t);
undef($c);
kill INT => $ww;
gstop();


done_testing();
