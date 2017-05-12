$SIG{CHLD} = sub { wait };

BEGIN { $|=1;print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::FDpasser;

$loaded = 1;

print "ok 1\n";
$|=0;
$pid = fork;
if (!defined($pid)) { die "fork failed: $!\n"; }

my($rin,$rout,$wout,$eout,$timeout,$uid);
$uid=0;
if ($pid) { # parent
    $LS=endp_create("/tmp/openserver") || die "endp_create: $!\n";

    
    $rin = '';
    vec($rin,fileno($LS),1) = 1;
    $timeout=0.5;
    for($i=0;$i<20;$i++) {
	($nfound,$timeleft) = select($rout=$rin, '', $eout=$rin, $timeout);
	  print "#server i=$i\n";
	  print "#server nfound=$nfound\n";
	  print "#server timeleft=$timeleft\n";
	  print "#server rout=",unpack("b*",$rout),"\n";
	  print "#server eout=",unpack("b*",$eout),"\n";
	  last if $nfound >0;
    }

    $fh=serv_accept_fh($LS,$uid) || die "serv_accept: $!\n";
    print "#server fh=$fh\n#server uid=$uid\n";

    open(FH,">test.txt") || die "parent - open(): $!\n";
    print FH "testing - hello world, etc..\n\n";
    close(FH);
    open(FH,"test.txt") || die "parent - open(): $!\n";

    $rc=send_file($fh,*FH{IO});
    print "#server: rc=$rc\n";
    print "ok\n";
} else { # child
    print "#child sleeping for 2 seconds\n";
    sleep(2);
    $fh=endp_connect("/tmp/openserver") || die "endp_connect: $!\n";
    print "#client: fh=$fh!\n";

    $newfh=recv_fh($fh);
    while(<$newfh>) { print "# ".$_; }

    print "ok\n";
}



