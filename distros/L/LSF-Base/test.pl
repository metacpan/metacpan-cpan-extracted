# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use LSF::Base;
use FileHandle;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $base;

print "not " unless $base = new LSF::Base;
print "ok 2\n";

my $myhost = $base->getmyhostname;
print "$myhost\n";
my $master = $base->getmastername;
print "$master\n";
my $cluster = $base->getclustername;
print $cluster,"\n";
my $hostType = $base->gethosttype($master);
print $hostType,"\n";
my $hostModel = $base->gethostmodel($master);
print "$hostModel\n";
my $factor = $base->getmodelfactor($hostModel);
print "$factor\n";
my $hostFactor = $base->gethostfactor($master);
print "$hostFactor\n";
my $lsinfo = $base->info();
my @resTable = $lsinfo->resTable;
my @types = $lsinfo->hostTypes;
my @models = $lsinfo->hostModels;
my @factors = $lsinfo->cpuFactor;
print scalar(@resTable)," ",scalar(@models),"\n";
print scalar(@types)," ", scalar(@factors),"\n";
print @resTable[MEM]->name,"\n";
print @resTable[MEM]->des,"\n";
print @resTable[MEM]->orderType == DECR,"\n";
print @resTable[MEM]->valueType == NUMERIC,"\n";
print @resTable[MEM]->flags == (RESF_BUILTIN|RESF_DYNAMIC|RESF_GLOBAL),"\n";
print @resTable[MEM]->interval,"\n";
unless( @resTable > 0                    and
    @resTable[MEM]->name eq "mem"        and
    @resTable[MEM]->des =~ /^Available/  and
    @resTable[MEM]->orderType == DECR    and
    @resTable[MEM]->valueType == NUMERIC and
    @resTable[MEM]->flags == RESF_BUILTIN|RESF_DYNAMIC|RESF_GLOBAL
	                                 and
    @resTable[MEM]->interval == 120      and
    @models > 0                          and
    @types > 0                           and
    @factors > 0                         and
    $cluster                             and
    $myhost                              and
    $factor == $hostFactor               and
    grep $factor == $_, @factors         and
    grep $hostModel eq $_, @models       and
    grep $hostType eq $_, @types
  ){
  print "not ";
}
print "ok 3\n";
  
##########################################

@hostinfo = $base->gethostinfo("r15m<2.0",NULL,EFFECTIVE);
if( @hostinfo ){
  foreach (@hostinfo){
    if( $master eq $_->hostName ){
      if( $_->cpuFactor eq $hostFactor and
	  $_->hostModel eq $hostModel  and
	  $_->hostType  eq $hostType   and
	  $_->isServer                 and
          $_->licensed
	){
	print "ok 4\n"
      }
      else{
	print "not ok 4\n";
      }
      last;
    }
  }
}
else{
  print "not ok 4\n";
}
#############################################
my @h, @load;
my $load_ok = 1;
@load = $base->load("r15m<2.0 && status==ok", 0, EFFECTIVE, undef);
$load_ok = 0 if $?;
foreach $hl (@load){
  @st = $hl->status;
  push @h , $hl->hostName;
  @li = $hl->li;
  if( $li[R15M] > 2.0 and ISOK(\@st) ){
    $load_ok = 0;
    last;
  }
}

@load = $base->loadofhosts("r15m<2.0", 0, EFFECTIVE, $h[0], \@h);
$load_ok = 0 if $?;
foreach $hl (@load){
  @li = $hl->li;
  if( $li[R15M] > 2.0 ){
    $load_ok = 0;
    last;
  }
}

if($load_ok){
  print "ok 5\n";
}
else{
  print "not ok 5\n";
}
#################################################
my @h1, %pl;
($place) = $base->placereq("r15m<2.0", 1, 0, undef);
$err = $?;
print "$place\n";
push @h1,$place;
($place2) = $base->placeofhosts("r15m<2.0", 1, 0, undef, \@h1);
$err2 = $?;
$pl{$place} = 1;
$err3 = !$base->loadadj("r1m",\%pl);
print "$@, $err, $err2, $err3, $place, $place2\n";
print "not " unless  !$err and !$err2 and !$err3 and $place eq $place2;
print "ok 6\n";
#################################################
$ok7 = 1;

$rtask = "testremote123";
$req = "r1m<1.0";
$ltask = "testlocal123";
$base->insertrtask("$rtask/$req") or $ok6 = 0;
$base->insertltask($ltask) or $ok6 = 0;

($ok, $resreq) = $base->eligible($rtask, LSF_LOCAL_MODE);
$ok7 = 0 unless $ok;
$ok7 = 0 unless $resreq eq $req;

$resreq = $base->resreq($rtask);
$ok7 = 0 unless $req eq $resreq;

($ok, $resreq) = $base->eligible($ltask, LSF_LOCAL_MODE);
$ok7 = 0 if $ok;

@rtasks = $base->listrtask(1);
@ltasks = $base->listltask(1);
$ok7 = 0 unless grep /^$rtask/, @rtasks;
$ok7 = 0 unless grep /^$ltask/, @ltasks;

$ok7 = 0 unless $base->deletertask($rtask);
$ok7 = 0 unless $base->deleteltask($ltask);

print "not " unless $ok7;
print "ok 7\n";


$p = $base->initrex(0,0);
$err1 = !defined $p;

if( $pid = open(CHILD,"-|") ){
  #parent
  $data = <CHILD>;
  $err3 = $data !~ /^this is a test/;
  $child = wait;
  $err2 = !defined $child;
}
elsif( defined $pid ){
  #child
  @arg = ("echo", "this is a test");
  $base->rexecv($place, \@arg, 0) or die $@;
  #should never get here
  $err2 = 1;
  exit;
}
else{
  #error
  $err2 = 1;
}


@arg = ("true");
$tid = $base->rtask($place, \@arg, REXF_TASKPORT);
$err4 = !($ru = $base->rwaittid($tid,0));

print "not " unless !$err1 and !$err2 and !$err3 and !$err4;
print "ok 8\n";

use Fcntl;

$fname = "/tmp/lsfbase.test";

$rfd = $base->ropen($place, $fname ,O_CREAT|O_WRONLY, 0777);
$buf = "1234567890";
$size = $base->rwrite($rfd, $buf, 10);
$err1 = $size != 10;
$err2 = !$base->rclose($rfd);

$rfd = $base->ropen($place, $fname, O_RDONLY, 0777);
$ret = $base->rlseek($rfd, 5, 0);
$ret2 = $base->rread(rfd, $buf2, 5);

$err3 = $buf2 ne "67890";

@stat1 = $base->rstat($place, $fname);
@stat2 = $base->rfstat($rfd);

$err4 = 0;
foreach(0..7){
  $err4 = 1 if $stat1[$_] != $stat2[$_];
}

$err5 = $stat1[7] ne 10;
$base->rclose($rfd);
$base->donerex;

print "not " if $err1 or $err2 or $err3 or $err4 or $err5;
print "ok 9\n";


