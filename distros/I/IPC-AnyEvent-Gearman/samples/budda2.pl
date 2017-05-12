use AnyEvent;
use EV;
use IPC::AnyEvent::Gearman;


@childs;
$recv;
$p = 1;

my $cv = AE::cv;

foreach (1..1){
    print "#$_\n";
    $pid = fork();
    if( $pid ){
        $p = 1;
        push(@childs, IPC::AnyEvent::Gearman->new(servers=>['localhost:9999'],pid=>$pid) );
    }
    else{
        $p =0;
        $recv = IPC::AnyEvent::Gearman->new(servers=>['localhost:9999']);
        print "<<<<< start CHILD ".$recv->channel."\n";
        $recv->on_receive(sub{ 
            print "<<<<< RECV $_[0]\n";
            $cv->send if( $_[0] eq 'kill' );
        });
        $recv->listen();
        last;
    }
}


if( $p ){
    $t = AE::timer 5,0,sub{
        print ">>>>> SEND killall\n";
        foreach my $ch (@childs){
            $ch->send('kill');
        }
    };
    $t2 = AE::timer 6,0,sub{$cv->send;};
}

$cv->recv;
print "DEAD $$\n";
