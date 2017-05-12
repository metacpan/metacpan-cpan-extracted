use AnyEvent;
use EV;
use IPC::AnyEvent::Gearman;

@childs;
$recv;

my $cv = AE::cv;
my $ppid = $$;
foreach (1..10){
    print "#$_\n";
    $pid = fork();
    if( $pid ){
        push(@childs, IPC::AnyEvent::Gearman->new(servers=>['localhost:9999'],pid=>$pid) );
    }

    else{
        $recv = IPC::AnyEvent::Gearman->new(servers=>['localhost:9999']);
        print "<<<<< start CHILD ".$recv->channel."\n";
        $recv->on_receive(sub{ 
            print "<<<<< RECV $_[0]\n";
            $cv->send if( $_[0] eq 'kill' );
        });
        $recv->listen();
        $cv->recv;
        print "DEAD CHILD $$\n";
        exit;
    }
}


$t = AE::timer 5,0,sub{
    print ">>>>> SEND killall\n";
    foreach my $ch (@childs){
        $ch->send('kill');
    }
};
$t2 = AE::timer 8,0,sub{$cv->send;};

$cv->recv;
print "DEAD $$\n";
