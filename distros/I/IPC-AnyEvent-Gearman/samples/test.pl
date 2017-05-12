use lib qw(../lib);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use AnyEvent;
use EV;
use AnyEvent::Gearman;

use AnyEvent::Gearman::Worker::RetryConnection;


my $gid;

    $gid = fork();
    if( !$gid )
    {
        DEBUG "######## start_gearmand ########";
        exec('gearmand -p 9999');
        die('cannot gearmand');
    }



my $cv = AE::cv;

my $ppid = $$;

use Data::Dumper;



    my $work = gearman_worker 'localhost:9999';
    $work = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($work);

    $work->register_function(
    'reverse' => sub {
        my $job = shift;
        my $res = reverse $job->workload;
        DEBUG 'recv : '.$job->workload;
        $job->complete($res);
    },
    );

if( $@){
    ERROR $@;
    kill 9,$gid;
    exit;
}

my $tt = AE::timer 5,0,sub{
    kill 9,$gid;
    sleep(2);
    $gid = fork();
    if( !$gid )
    {
        DEBUG "######## start_gearmand ########";
        exec('gearmand -p 9999');
        die('cannot gearmand');
    }
};
my $t = AE::timer 13,0,sub{
        DEBUG ">>>>> SEND to child \n";
my $client = gearman_client 'localhost:9999';
 
$client->add_task(
    'reverse' => 'ABCDE',
    on_complete => sub {
        my $result = $_[1];
        DEBUG $result;
        # ...
    },
    on_fail => sub {
        # job failed
        DEBUG 'faile';
    },
);
};


my $t2 = AE::timer 18,0,sub{$cv->send;};

$cv->recv;
undef $t;
undef $t2;
DEBUG "DEAD $$\n";
kill 9,$gid;
