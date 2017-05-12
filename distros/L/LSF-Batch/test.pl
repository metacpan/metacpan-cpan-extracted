# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { 
  $| = 1; print "1..1\n";
  $nolsfbase = 1 unless eval "require LSF::Base";
}

END {print "not ok 1\n" unless $loaded;}
use LSF::Batch;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$ok2 = 1;
$ok2 = 0 unless $b = new LSF::Batch "myTestApplication";
$conf = "/etc";
$conf = $ENV{LSF_ENVDIR} if $ENV{LSF_ENVDIR};


open CONF, "<$conf/lsf.conf" or $ok2 = 0;

#Read in LSF environment variables;
if($ok2){
  while(<CONF>){
    next if /^\#|^\s*$/;
    $ENV{$1} = $2 if /(.+)=(.+)/;
  }
  
  close CONF;
}
print "not " unless $ok2;
print "ok 2\n";

$ok3 = 1;

@info = $b->userinfo(undef) or $ok3 = 0;

foreach $user (@info){
  $ok3 = 0 if $user->maxJobs == 0;
}

@info = $b->queueinfo(undef,undef,undef,undef) or $ok3 = 0;

$nq = @info;

foreach $queue (@info){
  if( $queue->queue eq "" ){
    $ok3 = 0;
  }
}

$ok3 = 0 unless $nq;

@info = $b->sharedresourceinfo(undef,undef);

unless( @info ){
  $ok3 = 0 unless $@ eq "No resource defined";
}

@info = $b->hostpartinfo(undef);
$ok3 = 0 unless @info;

print "not " unless $ok3;
print "ok 3\n";

$ok4 = 1;

$command = <<EOF;
#!/bin/ksh
for i in 1 2 3 4 5 6
do
  date
 sleep 10
done
EOF

$jobname = "testjob1.$$";

$ENV{BSUB_QUIET} = 1;

$job = $b->submit(  -jobName => $jobname, 
		    -command => $command,
		    -output => "/dev/null"
		 );

$ok4 = 0 unless $job;

$myjobid = $job->jobId;
$index = $job->arrayIdx;

if( $myjobid != -1){
  sleep 10;
  $job->signal(SIGSTOP) or $ok4 = 0;
  $rec = 0;
  $rec = $b->openjobinfo($job,undef,undef,undef,undef,0) or $ok4 = 0;
  $j = $b->readjobinfo or $ok4 = 0;
  $cmd = $j->submit->command;
  $myqueue = $j->submit->queue;
  $cmd =~ s/;/\n/g;
  $cmd .= "\n";
  if( $rec != 1 or
      $j->submit->jobName ne $jobname or
      $j->submit->outFile ne "/dev/null" or
      $cmd ne $command or
      $j->jobId != $myjobid or
      $index != 0 
    ){
    $ok4 = 0;
  }
  $b->closejobinfo;
  $job->signal(SIGCONT) or $b->perror("signal");
}
else{
  $ok4 = 0;
}

print "not " unless $ok4;
print "ok 4\n";

if( $nolsfbase ){
  use ExtUtils::MakeMaker;
  $clustername = prompt("please enter your LSF cluster name");
}
else{
  $base = new LSF::Base;
  $clustername = $base->getclustername;
}

$events = $ENV{LSB_SHAREDIR}."/$clustername/logdir/lsb.events";

unless( -r $events ){
  $events = prompt("Events file is unreadable.\nPlease enter path to a readable events file.",$events);
}

open LOG, $events;

$ok5 = 1;
$line = 1;
while($er = $b->geteventrec( LOG, $line)){
  $el = $er->eventLog;
  $lt = localtime $er->eventTime;
  if( $er->type == EVENT_JOB_NEW ){
    $job = $el->jobId;
    $user = $el->userName;
    $res = $el->resReq;
    $q = $el->queue;
    #print "New job $job submitted to queue $q by $user\n";
    $ok5 = 0 if $job == $myjobid and $q != $myqueue;
  }
  elsif( $er->type == EVENT_JOB_START ){
    $job = $el->jobId;
    $idx = $el->idx; 
    #print "Started job ${job}[${idx}]\n";
  }
  elsif( $er->type == EVENT_JOB_START_ACCEPT ){
    $job = $el->jobId;
    $idx = $el->idx; 
    $pid = $el->jobPid;
    #print "SBD accepted job ${job}[${idx}]: pid $pid\n";
  }
  elsif( $er->type == EVENT_JOB_EXECUTE ){
    $job = $el->jobId;
    $idx = $el->idx; 
    $pid = $el->jobPid;
    $home = $el->execHome;
    $cwd = $el->execCwd;
    $user = $el->execUsername;
    #print "job ${job}[${idx}] started execution with home=$home and cwd=$cwd as $user\n";
  }
  elsif( $er->type == EVENT_JOB_STATUS ){
    $job = $el->jobId;
    $idx = $el->idx;
    $status = $el->jStatus;
    #print "Job ${job}[${idx}] status changed to $status\n";
  }
  elsif( $er->type == EVENT_JOB_FINISH ){
    $job = $el->jobId;
    $idx = $el->idx;
    @hosts = $el->execHosts;
    $cpu = $el->cpuTime;
    #print "job ${job}[${idx}] finished on @hosts using $cpu\n";
  }
  elsif( $er->type == EVENT_JOB_CLEAN ){
    $job = $el->jobId;
    $idx = $el->idx;
    #print "job ${job}[${idx}] cleaned up\n";
  }
  elsif( $er->type == EVENT_LOG_SWITCH ){
    $lastid = $el->lastJobId;
    #print "Log switched at job $lastid\n";
  }
  elsif( $er->type == EVENT_MBD_START ){
    $master = $el->master;
    $cluster = $el->cluster;
    $numhosts = $el->numHosts;
    $numqueues = $el->numQueues;
    #print "Master batch daemon started on $master for cluster $cluster.\n";
    #print "Hosts = $numhosts, queues = $numqueues\n";
    $ok5 = 0 if $cluster != $clustername or $numqueues != $nq;
  }
  else{
    #print "Got event type ",$er->type,"\n";
  }
}

print "not " unless $ok5;
print "ok 5\n";

#$job->run(\@hosts, RUNJOB_OPT_NORMAL) or $b->perror("running job");


exit;








# Job calls
#modify
#chkpnt
#mig
#move
#peek
#signal
#switch
#run

#queuecontrol
#sysmsg
#perror

#hostinfo_ex
#hostgrpinfo
#usergrpinfo


exit;

