package main;

use lib 't/lib';
use Test::More tests=>3;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use TestWorker;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $ww = fork;
if( !$ww ){
    DEBUG "PID : $$";
    my $w = TestWorker->new(job_servers=>\@js,cv=>$cv,parent_channel=>undef,channel=>'test',workleft=>2);
    $w->work;
}

my $cnt = 2;
my $c = gearman_client @js;
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';
    $cv->send if( --$cnt == 0 );
});
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';
    $cv->send if( --$cnt == 0 );
});



my $res = $cv->recv;
undef($t);
undef($c);
kill INT => $ww;
gstop();


done_testing();
