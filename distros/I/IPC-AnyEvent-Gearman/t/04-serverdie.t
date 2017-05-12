use Test::More tests=>1;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use AnyEvent;
use EV;
use IPC::AnyEvent::Gearman;
my $gid = fork();
if( !$gid )
{
    sleep(2);
    DEBUG "######## start_gearmand ########";
    exec('gearmand -p 9999');
    die('cannot gearmand');
}
#sleep(1);
my $cv = AE::cv;
my @childs;

my $ppid = $$;

eval{
$recv = IPC::AnyEvent::Gearman->new(job_servers=>['localhost:9999']);
DEBUG "<<<<< start CHILD ".$recv->channel."\n";
$recv->on_recv(sub{ 
    DEBUG "<<<<< RECV $_[0]\n";
    return "OK";
});
$recv->listen();
};
if( $@){
    ERROR $@;
    kill 9,$gid;
    exit;
}

my $ch = IPC::AnyEvent::Gearman->new(job_servers=>['localhost:9999']);
$ch->on_sent(sub{
    my ($ch,$res) = @_;
    DEBUG "res : $res";
    is $res,'OK';
    $cv->send if( $res eq 'OK' );
});

my $t = AE::timer 5,0,sub{
        DEBUG ">>>>> SEND to child \n";
        $ch->send($recv->channel,'kill');
};

my $t2 = AE::timer 8,0,sub{$cv->send;};

$cv->recv;
undef $t;
undef $t2;
DEBUG "DEAD $$\n";
kill 9,$gid;
done_testing();
