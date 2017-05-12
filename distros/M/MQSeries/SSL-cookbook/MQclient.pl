#!/opt/smm/bin/perl -w
#$Id: MQclient.pl,v 32.1 2008/03/27 18:20:10 biersma Exp $

# MQ client test script
# morten.bjornsvik@experian-scorex.no April 2006-2008

use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(time);
use Data::Dumper;

use MQSeries;
use MQSeries::QueueManager;
use MQSeries::Message;
use MQSeries::Queue;

  
#default values
my $queue    = undef;     # mandatory queue
my $qmgr     = undef;     # mandatory queuemanager to connect to
my $type     = 'get';     # 'get' is default   
my $channel  = undef;
my $server   = undef;     #MQservers IP or hostname
my $sslkey   = undef;
my $sslcipherspec = 'NULL_MD5'; #'NULL_MD5' is simplest and fastest
my $port     = 1414;      #1414 is the default MQ channel port
my $backout  = undef;
my $dump     = undef;
my $file     = undef;
my $help     = undef;     # if this becomes set, just print the legend
my $debug    = 1;         # default debuglevel is just some statistics
my $wait     = 1000;			# wait in ms before returning empty_queue
my $waitnline = 0;         # wait between each message in ms
my $waitfull = 10000;     # wait 10 sec when queue is full
my $ncount   = 100;       # count number of messages before issuing statistics

my ($t0,$t1,$t2);
my $exitflag=0;
my $FILE=undef;
my $num=0;
my $oldnum=0;

##################################################
# Subroutines
##################################################
sub legend {
  print<<EOF;
$0 - WebsphereMQ client script
(c) morten.bjornsvik\@experian-scorex.no 2006-2008

Simple program to put or get messages from an IBM WebsphereMQ queue
see the perldoc for full examples on how to set up WebsphereMQ and extensive
use of this program. 

Mandatory parameters:
-s|server=ip|hostname    - server running the queueumanager we connect to
-qm=queuemanager         - queuemanager on server
-q=queuename             - queue on server
-ch|channel=channelname  - channel the client connects to
-p|port=N                - port N the channel is running on
-t|type=(get|put)        - "get" = download from queue, "put" = add to queue, default:"get" 

Optional parameters:
-file=filename              - write messages to filename, not defined: STDOUT (if -type=get)
-file=filename|dir          - read messages from filename/dir (if -type=put)
-debug=0|1|2                - default is 1 (0=none, 1=filestatus, 2=messages)
-dump                       - dump the objects with Dumper()
-wait=#                     - wait # millisec when queue is empty
-ncount=#                   - process # messages before reporting stat and waiting
-wl|waitnline='rN1-N2|rN|N' - wait N, randomN or random [N1,N2] millisec between block
                              of ncount messages.
-wf|waitfull='rN1-N2|rN|N1' - wait # millisecs before retrying if queue is full (default is 1sec)
-backout                    - do not commit, do a backout to keep message on queue
-sslkey=dir                 - directory where to find ssl keyrepository made by gsk7ikm, gsk7cmd
                              (need more testing, works for verisign certificates)
-sslcipherspec=chiper-name  - what type of cipher do we use, default 'NULL_MD5'

Press ctrl+c to quit, and then a summary of all transactions will be printed.
Please notice the random waiting is very approximate, it is just to create some variance
in streams.
EOF
  exit();
}

# accepting inputformat as 'rand(low,high)' or 'rand(high)' or
# just number
sub mywait {
  my $str = shift;
  my $low=undef;
  my $high=undef;
  my $w=undef;
  return 0 if(!defined $str);
  if($str =~ /^r(\d+)\-(\d+)$/) {
    $low=$1;
    $high=$2;
  }
  elsif($str =~ /^r(\d+)$/) {
    $low=0;   
    $high=$1;
  }
  elsif($str =~ /(\d+)/) {
    $low=$1;    
  }
  else {
    return 0;
  }
  if(!defined $high) {
    $w=$low;
  }
  else {
    $w= int rand( abs($high-$low) );
    $w+=$low if(defined $low);
  }
  print "Waiting $w ms\n" if($debug>=2);
  select(undef,undef,undef,$w/1000);
  
  return $w;
}


###############################################
# Command line parameter checking
###############################################

if ( ! scalar(@ARGV) ) {
  print legend();
  die("\n");
}

my $nparam = GetOptions (
  "s|server=s"        => \$server,
  "qm|queuemanager=s" => \$qmgr,   
  "q|queue=s"         => \$queue,  
  "ch|channel=s"      => \$channel,
  "p|port=i"          => \$port,  
  "f|file=s"          => \$file,
  "debug=i"           => \$debug,
  "w|wait=i"          => \$wait,    
  "ncount=i"          => \$ncount, 
  "wl|waitnline=s"    => \$waitnline,
  "wf|waitfull=s"     => \$waitfull,
  "backout"           => \$backout,
  "dump"              => \$dump,
  "sslkeyr|sslkey=s"  => \$sslkey,
  "sslcipherspec|cipher=s"   => \$sslcipherspec,
  "t|type=s"          => \$type,
  "h|help"            => \$help,
) || print legend();

if(defined $help) {
  print legend();
}
die("Error SSL Key-repository $sslkey does not exists\n") if(defined $sslkey && ! -f $sslkey.".kdb");

my $find="/usr/bin/find";
die("Error: binary $find=$find is not correctly set\n") if($type eq "put" && -d $file && ! -x $find); 

if(!defined $server || !defined $qmgr || !defined $queue || !defined $channel ||
  !defined $port || !defined $type) {
  print "Error: missing mandatory parameter\n\n";
  print legend();
  die("\n");
}
elsif(defined $type && $type eq "put" && ! defined $file) {
  die("Error: When --type=put --file=<filename|dir> must be defined\n");
}
else {
  print "Connecting to $server:$qmgr:$queue:$channel:$port\n" if($debug);
}

if($waitnline !~ /^r[\d\-]+$/ && $waitnline !~ /^\d+$/) {
  die("Error: $waitnline is not in proper format 'r#-#' or '##'\n");
}
else {
  srand(time);
}
# interrupt handler, we just want to print out a summary when we quit
$SIG{INT} = sub {
  $exitflag=1;
  $t2 = time;
  printf("Total %s %d transactions in %.2f sec (%.2f trans/sec)\n",
    $type eq "get"?"output":"input",$num,$t2-$t0,$num/($t2-$t0));
  close($FILE) if($FILE);
};

my ($compcode, $reason);  # Errorcodes

$t0 = time;
# client connection
my $myqmgr = undef;

if(defined $sslkey) { #QueueManager setup with SSL has some changes
  $myqmgr = MQSeries::QueueManager->new (
    QueueManager => $qmgr,
    ClientConn   => { 
      Version        => 8,
      ChannelName    => $channel,
      TransportType  => 'TCP',
      SSLCipherSpec => $sslcipherspec,
      ConnectionName => $server."(".$port.")",
    },
    SSLConfig    => { 
      KeyRepository => $sslkey, 
    },
  );  
  print "Using SSLkey = $sslkey\n" if($debug>=2);
}
else {
  $myqmgr = MQSeries::QueueManager->new (
    QueueManager => $qmgr,
    ClientConn   => { 
      ChannelName    => $channel,
      TransportType  => 'TCP',
      ConnectionName => $server."(".$port.")",
    },
  );
}
die("Unable to connect to queuemanager: $qmgr\n") if(! defined $myqmgr);

print "\$myqmgr=",Dumper($myqmgr) if(defined $dump); 



if($type eq "get") {  
  # get messages from queue
  #
  # Open a queue for output, loop getting messages, updating some
  # database with the data.
  # 
  my $myqueue = MQSeries::Queue->new (
    QueueManager       => $myqmgr,
    Queue              => $queue,
    Mode               => 'input',
  )
  or die("Unable to open queue: $queue.\n");

  
  if(defined $file && $type eq "get") {
    my $op=">>";
    $op=">" if(! -e $file);
    open($FILE,"$op $file") || 
      die ("Error: unable to open file $file for ",$type eq "get"?"writing":"reading","\n");    
  }

  print "\$myqueue=",Dumper($myqueue) if(defined $dump); 
  while ( !$exitflag ) {
    $t1=time if($num==$oldnum);
    my $getmessage = MQSeries::Message->new();

    $myqueue->Get(
      Message => $getmessage,
      Sync => 1,
      Wait => $wait,
  #			GetMsgOpts => {
  #      	Options => MQGMO_FAIL_IF_QUIESCING | MQGMO_SYNCPOINT | MQGMO_WAIT, 
  #        WaitInterval => MQWI_UNLIMITED,
  #      }, 

    ) or die(
      "Unable to get message from $qmgr:$queue - " .
      "CompCode = " . $myqueue->CompCode() . " - " .
      "Reason = " . $myqueue->Reason() . "\n"
    );
    print "$qmgr:$queue - is empty\n" if( $debug && $myqueue->Reason() == 2033 );

    print "\$getmessage=",Dumper($getmessage) if(defined $dump);
    if ( my $mymessage = $getmessage->Data() ) {

      if(defined $file) {
        print $FILE "$mymessage\n";
      }
      else {
        print "$mymessage\n" if($debug >= 2);
      }
      $num++;
      if(defined $backout) {    #do not commit, just do backout
        my $rc = $myqueue->QueueManager()->Backout() ||
          die(
            "Unable to backout changes to queue - " .
            "CompCode = " . $myqueue->CompCode() . " - " .
            "Reason = " . $myqueue->Reason() . "\n"
          );
      }
      else { # commit ang go to next
        my $rc = $myqueue->QueueManager()->Commit()
          or die(
            "Unable to commit changes to queue - " .
            "CompCode = " . $myqueue->CompCode() . " - " .
            "Reason = " . $myqueue->Reason() . "\n"
        );
      }
      if($num >= $oldnum + $ncount)	{
	$t2 = time;
	printf("Popped %d transactions in %.2f sec (%.2f trans/sec)\n",
	$num-$oldnum,$t2-$t1,($num-$oldnum)/($t2-$t1)) if($debug);
	$oldnum=$num;
        # this is only to be able to test slower input
        mywait($waitnline);
      }      
    } 
    else {  # if no message on queue
      my $rc = $myqueue->QueueManager()->Backout() ||
        die(
          "Unable to backout changes to queue - " .
          "CompCode = " . $myqueue->CompCode() . " - " .
          "Reason = " . $myqueue->Reason() . " - "
        );
    }
  }
}
else { 
################################
# put messages onto the queue
################################
  my $myqueue = MQSeries::Queue->new (
    QueueManager       => $myqmgr,
    Queue              => $queue,
    Mode               => 'output',
  )
  or die("Unable to open queue: $queue.\n");

  print "Dump of \$myqueue=",Dumper($myqueue) if(defined $dump); 

  my @dirs = ();
  if(defined $file && -d $file) {
    chomp(@dirs =`cd $file; $find -L`);
    for(my $i=0;$i<scalar(@dirs); $i++) {      
      $dirs[$i] = $file ."/". $dirs[$i] if(-f $file."/".$dirs[$i]);
    }
    print "Will try reading ",scalar(@dirs)," file",
      scalar(@dirs)>1?'s':''," from $file\n" if($debug);
    my $i=0;
  }
  else {
    $dirs[0]=$file;
  }
  for(my $i=0;$i<scalar(@dirs); $i++) {
    open($FILE,"<$dirs[$i]") || next;
    while( !$exitflag && (my $line = <$FILE>) ) {
      chomp($line);
      $t1=time if($num==$oldnum);

      my $putmessage = MQSeries::Message->new(
        Data    => $line,
        MSGDesc => { Format => MQFMT_STRING },
      );
      
      do {
        $myqueue->Put(
          Message => $putmessage,
          Sync => 0,    # do not sync just add as fast as possible
        );
        
        if( $myqueue->Reason() == 2053 ) {
          print "Queue $qmgr:$queue is full\n" if($debug);
          mywait($waitfull);
        } 
        elsif($myqueue->Reason()){
          die("Killed  $qmgr:$queue due to reason: $myqueue->Reason()\n");
        }
      }while ( $myqueue->Reason() == 2053 );
      
      $num++;
      print "#$num <$line> put on $qmgr:$queue\n" if($debug>=2);      

      if($num >= $oldnum + $ncount)	{
	$t2 = time;
	printf("Pushed %d transactions in %.2f sec (%.2f trans/sec)\n",
	$num-$oldnum,$t2-$t1,($num-$oldnum)/($t2-$t1)) if($debug);
	$oldnum=$num;
        # wait between ncount blocks of messages, if you like a slower input
        mywait($waitnline);
      }            
    }
  }
  $t2 = time;
  printf("Pushed %d transactions in %.2f sec (%.2f trans/sec)\n",
    $num,$t2-$t0,$num/($t2-$t0)) if($debug);

}
close($FILE) if(defined $FILE);

__END__

=pod

=head1 NAME

MQclient.pl - Client access program for WebsphereMQ

=head1 SYNOPSIS

 Mandatory parameters:
 -s|server=ip|hostname    - server running the queueumanager we connect to
 -qm=queuemanager         - queuemanager on server
 -q=queuename             - queue on server
 -ch|channel=channelname  - channel the client connects to
 -p|port=N                - port N the channel is running on
 -t|type=(get|put)        - 'get'-download from queue, 'put'-add to queue, default:"get" 

 Optional parameters:
 -file=filename              - write messages to filename, not defined: STDOUT(if -type=get)
 -file=filename|dir          - read messages from filename/dir (if -type=put)
 -debug=0|1|2                - default is 1 (0=none, 1=filestatus, 2=messages)
 -dump                       - dump the objects with Dumper()
 -wait=#                     - wait # millisec when queue is empty
 -ncount=#                   - process # messages before reporting stat and waiting
 -wl|waitnline='rN1-N2|rN|N' - wait N, randomN or random [N1,N2] millisec between block
                              of ncount messages.
 -wf|waitfull='rN1-N2|rN|N1' - wait # millisecs before retrying if queue is full (default is 1sec)
 -backout                    - do not commit, do a backout to keep message on queue
 -sslkey=dir                 - directory where to find ssl keyrepository made by gsk7ikm, gsk7cmd
                               (need more testing, works for verisign certificates)
 -sslcipherspec=spec         - spec is the cipher used by mq

Press ctrl+c to quit, and then a summary of all transactions will be printed.
Please notice the random waiting is very approximate, it is just to create some variance
in streams.

=head1 SETUP AND TESTING

To run this program you need IBM WebsphereMQ client >= v6 and Perl module MQSeries >= 1.23 installed.
The MQserver can reside anywhere in your network or on localhost, just ensure the socket you'll use
is not firewalled.

 Client needs minimum the following packages:
 MQSeriesRuntime
 MQSeriesClient
 
 Server needs minimum:
 MQSeriesRuntime
 MQSeriesServer

 If you need ssl install on server:
 MQSeriesKeyMan
 gsk7bas (holds gsk7cmd which creates the certificates which is created with script mq-ca.pl)
 
=head2 SETUP A TEST QUEUE ON A WEBSPHEREMQ QUEUEMANAGER

This program is useless without a MQserver to connect to, So if you do not have one around to
test with here is a recipe to setup a simple setup. WebsphereMQ has a 60 day free trial period.
You can reinstall afterwards to get 60 new days.

=head2 Security

The user which runs MQclient.pl on the client is member of mqm group on client.
It _MUST_ also exists on mqserver with the same username and being member of group mqm there
aswell. Otherwhise you will get MQRC 2035 - 'not authorized to connect' in non SSL mode.
With SSL you only get MQRC 2059 - 'MQRC_Q_MGR_NOT_AVAILABLE'.

 MQclient.pl -> put -> MQserver -> get -> MQclient.pl
 
=head2 MQSERVER SETUP

I recommend creating a script which set up the mqserver, This example set up mqserver swolinux
using self signed ssl 'NULL_MD5' certificate where all the certificates are generated using
gsk7cmd on the same server using the my script mq-ca.pl. See the perldoc on mq-ca.pl.

 root@swolinux$ ./MQmanager-swolinux-sslclient.sh
 (output is abbreviated for readability)
     1 : DEFINE QLOCAL('secana.queue') REPLACE +
       :         DESCR('queue used for secana transactions') +
       :         PUT(ENABLED) +
       :         DEFPRTY(0) +
       :         DEFPSIST(YES) +
       :         GET(ENABLED) +
       :         MAXDEPTH(10000) +
       : *       MAXMSGL(15000) +
       :         DEFSOPT(SHARED) +
       :         NOHARDENBO         +
       :         USAGE(NORMAL) +
       :         NOTRIGGER;
 AMQ8006: WebSphere MQ queue created.
       :
     1 : DIS Q('secana.queue') ALL;
 AMQ8409: Display Queue details.
   QUEUE(secana.queue)                     TYPE(QLOCAL)
   ACCTQ(QMGR)                             ALTDATE(2008-03-05)
   ALTTIME(09.47.27)                       BOQNAME( )
   BOTHRESH(0)                             CLUSNL( )
   CLUSTER( )                              CLWLPRTY(0)
   CLWLRANK(0)                             CLWLUSEQ(QMGR)
   CRDATE(2008-03-04)                      CRTIME(15.49.27)
   CURDEPTH(0)                             DEFBIND(OPEN)
   DEFPRTY(0)                              DEFPSIST(YES)
   DEFSOPT(SHARED)                         DEFTYPE(PREDEFINED)
   DESCR(queue used for secana transactions)
   DISTL(NO)                               GET(ENABLED)
   NOHARDENBO                              INITQ( )
   IPPROCS(0)                              MAXDEPTH(10000)
   MAXMSGL(4194304)                        MONQ(QMGR)
   MSGDLVSQ(PRIORITY)                      NOTRIGGER
   NPMCLASS(NORMAL)                        OPPROCS(0)
   PROCESS( )                              PUT(ENABLED)
   QDEPTHHI(80)                            QDEPTHLO(20)
   QDPHIEV(DISABLED)                       QDPLOEV(DISABLED)
   QDPMAXEV(ENABLED)                       QSVCIEV(NONE)
   QSVCINT(999999999)                      RETINTVL(999999999)
   SCOPE(QMGR)                             SHARE
   STATQ(QMGR)                             TRIGDATA( )
   TRIGDPTH(1)                             TRIGMPRI(0)
   TRIGTYPE(FIRST)                         USAGE(NORMAL)
       :
     1 : DEFINE LISTENER('listener') +
       :         TRPTYPE(TCP) PORT(6666) CONTROL(QMGR) +
       :         DESCR('TCP/IP Listener for this queue-manager') +
       :         REPLACE;
 AMQ8626: WebSphere MQ listener created.
       :
       : * SVRCONN channels are used for clients to connect to
     1 : DEFINE CHANNEL('secana.ssl') +
       :   CHLTYPE(SVRCONN) TRPTYPE(TCP) +
       :   MCAUSER('') +
       :   SSLCAUTH(REQUIRED) +
       : * SSLPEER('OU=Decision Analytics*') +
       :   SSLCIPH('NULL_MD5') +
       :   REPLACE;
 AMQ8014: WebSphere MQ channel created.
       :
     1 : ALTER QMGR SSLKEYR('/var/mqm/ssl/swolinux')
 AMQ8005: WebSphere MQ queue manager changed.
       : * display channel
     1 : DIS CHANNEL('secana.ssl') ALL;
 AMQ8414: Display Channel details.
   CHANNEL(secana.ssl)                     CHLTYPE(SVRCONN)
   ALTDATE(2008-03-05)                     ALTTIME(09.47.27)
   COMPHDR(NONE)                           COMPMSG(NONE)
   DESCR( )                                HBINT(300)
   KAINT(AUTO)                             MAXMSGL(4194304)
   MCAUSER( )                              MONCHL(QMGR)
   RCVDATA( )                              RCVEXIT( )
   SCYDATA( )                              SCYEXIT( )
   SENDDATA( )                             SENDEXIT( )
   SSLCAUTH(REQUIRED)                      SSLCIPH(NULL_MD5)
   SSLPEER( )                              TRPTYPE(TCP)
       :
       : * start channel
     1 : START CHANNEL('secana.ssl')
 AMQ8018: Start WebSphere MQ channel accepted.
       :
       : * start listener
     1 : START LISTENER('listener')
 AMQ8021: Request to start WebSphere MQ Listener accepted. 

     1 : dis listener('listener') all
 AMQ8630: Display listener information details.
   LISTENER(listener)                      CONTROL(QMGR)
   TRPTYPE(TCP)                            PORT(6666)
   IPADDR( )                               BACKLOG(0)
   DESCR(TCP/IP Listener for this queue-manager)
   ALTDATE(2008-03-05)                     ALTTIME(09.53.54)

=head2 PUSH DATA TO TEST QUEUE

We now have a channel 'secana.ssl' waiting. First we need to set up the clients
we'll use and copy across the client certificate we created with mq-ca.pl with
the username which will run MQclient.pl --sslkey (mqsslkeyrepository) is copied to /tmp/mqssl/

 mbj@demolinux$ ./MQclient.pl -s=192.168.2.100 -qm=swolinux -q=secana.queue \
  -channel=secana.ssl -p=6666 --sslkey=/tmp/mqssl/mbj -t=put -file=/raid/scp21_bench/authdata/all
 Connecting to 192.168.2.100:swolinux:secana.queue:secana.ssl:6666
 Will try reading 1412 files from /raid/scp21_bench/authdata/all
 Pushed 100 transactions in 0.15 sec (662.40 trans/sec)
 Pushed 100 transactions in 0.15 sec (662.88 trans/sec)
 Pushed 100 transactions in 0.15 sec (654.99 trans/sec)
 Pushed 100 transactions in 0.16 sec (641.30 trans/sec)
 Pushed 100 transactions in 0.15 sec (652.76 trans/sec)
 Pushed 100 transactions in 0.15 sec (650.14 trans/sec)
 Pushed 100 transactions in 0.16 sec (643.36 trans/sec)
 <ctrl+c>
 Total input 770 transactions in 2.40 sec (320.53 trans/sec)
 Pushed 771 transactions in 2.43 sec (317.52 trans/sec)

if --file points to a directory it pushes all files in directory

You can see how many messages are waiting on the queue with the following command:
 root@swolinux$ echo "dis q('secana.queue') CURDEPTH;" | runmqsc swolinux
 :
    CURDEPTH(771)
 :

You see there are 188 messages waiting.


=head2 GET DATA from TEST QUEUE

MQclient.pl in get mode works as a daemon reading from the queues for a defined period.
Add --debug=2 if you like to see the messages.

 mbj@mbjlinux$ ./MQclient.pl -s=192.168.2.100 -qm=swolinux -q=secana.queue \
 -channel=secana.ssl -p=6666 --sslkey=/tmp/mqssl/mbj
 Connecting to 192.168.2.100:swolinux:secana.queue:secana.ssl:6666
 Popped 100 transactions in 0.22 sec (463.16 trans/sec)
 Popped 100 transactions in 0.22 sec (464.90 trans/sec)
 Popped 100 transactions in 0.22 sec (458.82 trans/sec)
 Popped 100 transactions in 0.22 sec (460.90 trans/sec)
 Popped 100 transactions in 0.21 sec (465.57 trans/sec)
 Popped 100 transactions in 0.22 sec (458.80 trans/sec)
 Popped 100 transactions in 0.22 sec (461.81 trans/sec)
 swolinux:secana.queue - is empty
 swolinux:secana.queue - is empty
 <ctrl+c>
 Total output 771 transactions in 4.87 sec (158.47 trans/sec)
 swolinux:secana.queue - is empty

=head2 MONITOR QUEUEMANAGER

While communication is running you can browse the channelstatus on queuemanager:

 echo "dis chs('secana.ssl') all" | runmqsc swolinux
 
AMQ8417: Display Channel Status details.
   CHANNEL(secana.ssl)                     CHLTYPE(SVRCONN)
   BUFSRCVD(20206)                         BUFSSENT(20205)
   BYTSRCVD(15818375)                      BYTSSENT(10909372)
   CHSTADA(2008-03-05)                     CHSTATI(10.19.33)
   COMPHDR(NONE,NONE)                      COMPMSG(NONE,NONE)
   COMPRATE(0,0)                           COMPTIME(0,0)
   CONNAME(192.168.2.28)                   CURRENT
   EXITTIME(0,0)                           HBINT(300)
   JOBNAME(0000534000000006)               LOCLADDR(::ffff:192.168.2.100(6666))
   LSTMSGDA(2008-03-05)                    LSTMSGTI(10.20.15)
   MCASTAT(RUNNING)                        MCAUSER(mbj)
   MONCHL(OFF)                             MSGS(20203)
   RAPPLTAG(MQclient.pl)                   RQMNAME( )
   SSLCERTI(CN=Experian Secana CA,OU=Decision Analytics,O=Experian,L=Oslo,C=NO)
   SSLKEYDA( )                             SSLKEYTI( )
   SSLPEER(CN=mbj - client,OU=Decision Analytics,O=Experian,L=Oslo,C=NO)
   SSLRKEYS(0)                             STATUS(RUNNING)
   STOPREQ(NO)                             SUBSTATE(RECEIVE)
   XMITQ( )

If the channel is not used, channel status will not show.

=head2 SSL KEYREPOSITORY

There are several ways to create ssl certificates, you can optain from a trusted commercial ca-issuer,
like verisign (tested well at customer), or you can do it yourselves with openssl, makecert, or
IBM's gsk7cmd (command line) or gsk7ikm (java GUI)

Please see the script mq-ca.pl for more info. it uses gsk7cmd.

=head3 SSLCIPHERSPEC

We must use the same cipher on each side, below are the different valid ciphers, I've only used
NULL_MD5 which is the default, Please look up the Global Security Kit manuals for more info.

 NULL_MD5
 NULL_SHA
 RC4_MD5_EXPORT
 RC4_MD4_US
 RC4_SHA_US
 RC2_MD5_EXPORT
 DES_SHA_EXPORT
 RC4_56_SHA_EXPORT1024
 DES_SHA_EXPORT1024
 TRIPLE_DES_SHA_US
 TLS_RSA_WITH_128_CBC_SHA
 TLS_RSA_WITH_256_CBC_SHA
 TLS_RSA_WITH_DES_CBC_SHA
 TLS_RSA_WITH_3DES_EDE_CBC_SHA
 FIPS_WITH_DES_CBC_SHA
 FIPS_WITH_3DES_EDE_CBC_SHA

=head1 AUTHOR

Morten Bjørnsvik - morten.bjornsvik@experian-scorex.no - 2006-2008


