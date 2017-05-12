package LSF::Base;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Exporter;
use DynaLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( BOOLEAN NUMERIC STRING INCR DECR NA RESF_BUILTIN
RESF_DYNAMIC RESF_GLOBAL RESF_SHARED RESF_LIC RESF_EXTERNAL RESF_RELEASE
EXACT OK_ONLY NORMALIZE LOCALITY IGNORE_RES LOCAL_ONLY DFT_FROMTYPE 
ALL_CLUSTERS EFFECTIVE RECV_FROM_CLUSTERS NEED_MY_CLUSTER_NAME
LIM_UNAVAIL LIM_LOCKEDU LIM_LOCKEDW LIM_BUSY LIM_RESDOWN LIM_UNLICENSED
LIM_OK_MASK LIM_SBDDOWN INTEGER_BITS ISUNAVAIL ISBUSY ISBUSYON ISLOCKEDU
ISLOCKEDW ISLOCKED ISRESDOWN ISSBDDOWN ISUNLICENSED ISOK ISOKNRES 
R15S R1M R15M UT PG IO LS IT TMP SWP MEM USR1 USR2 LSF_BASE_LIC
LSF_BATCH_LIC LSF_JS_SCHEDULER_LIC LSF_JS_LIC LSF_CLIENT_LIC LSF_MC_LIC
LSF_ANALYZER_LIC LSF_ANALYZER_SERVER_LIC LSF_MAKE_LIC LSF_PARALLEL_LIC
LSF_NUM_LIC_TYPE LSF_LOCAL_MODE LSF_REMOTE_MODE KEEPUID REXF_USEPTY
REXF_CLNTDIR REXF_TASKPORT REXF_SHMODE REXF_TASKINFO REXF_REQVCL
REXF_SYNCNIOS REXF_TTYASYNC STATUS_TIMEOUT STATUS_IOERR STATUS_EXCESS 
STATUS_REX_NOMEM STATUS_REX_FATAL STATUS_REX_CWD STATUS_REX_PTY 
STATUS_REX_SP STATUS_REX_FORK STATUS_REX_AFS STATUS_REX_UNKNOWN
STATUS_REX_NOVCL STATUS_REX_NOSYM STATUS_REX_VCL_INIT STATUS_REX_VCL_SPAWN
STATUS_REX_EXEC RF_MAXHOSTS RF_CMD_MAXHOSTS RF_CMD_TERMINATE 
RF_CMD_RXFLAGS RES_CMD_REBOOT RES_CMD_SHUTDOWN RES_CMD_LOGON 
RES_CMD_LOGOFF LIM_CMD_REBOOT LIM_CMD_SHUTDOWN
);

@EXPORT_OK = qw(
);

#%EXPORT_TAGS = (
#   Configuration => 
#   [qw(getclustername getmastername gethosttype gethostmodel)],
#   LoadInfoPlacement => 
#   [],
#   TaskList =>
#   [],
#   RexecTaskControl =>
#   [],
#   RemoteFile =>
#   [],
#   Administration =>
#   [],
#   ErrorHandling =>
#   [],
#   Miscellaneous =>
#   []
#);

$VERSION = '0.05';

bootstrap LSF::Base $VERSION;

# Preloaded methods go here.

sub new{
  my $type = shift;
  my $self;

  return eval{
    if( -e "/etc/lsf.conf" or $ENV{LSF_ENVDIR} ){
      bless \$self, $type;
    }
    else{
      die "Can't access lsf.conf file or LSF_ENVDIR not set";
    }
  }
}

sub BOOLEAN{0}
sub NUMERIC{1}
sub STRING{2}

sub INCR{0}
sub DECR{1}
sub NA{2}

sub RESF_BUILTIN{0x01}  # builtin vs configured resource
sub RESF_DYNAMIC{0x02}  # dynamic vs static value
sub RESF_GLOBAL{0x04}   # resource defined in all clusters
sub RESF_SHARED{0x08}   # shared resource for some hosts
sub RESF_LIC{0x10}      # license static value
sub RESF_EXTERNAL{0x20} # external resource defined
sub RESF_RELEASE{0x40}  # Resource can be released when job is suspended

#flags for placement decision
sub EXACT{0x01}
sub OK_ONLY{0x02}
sub NORMALIZE{0x04}
sub LOCALITY{0x08}
sub IGNORE_RES{0x10}
sub LOCAL_ONLY{0x20}
sub DFT_FROMTYPE{0x40}
sub ALL_CLUSTERS{0x80}
sub EFFECTIVE{0x100}
sub RECV_FROM_CLUSTERS{0x200}
sub NEED_MY_CLUSTER_NAME{0x400}

# Host status from the LIM
sub LIM_UNAVAIL{0x00010000}
sub LIM_LOCKEDU{0x00020000}
sub LIM_LOCKEDW{0x00040000}
sub LIM_BUSY{0x00080000}
sub LIM_RESDOWN{0x00100000}
sub LIM_UNLICENSED{0x00200000}
sub LIM_OK_MASK{0x003f0000}
sub LIM_SBDDOWN{0x00400000}
sub INTEGER_BITS{32}

sub ISUNAVAIL{ my ($st) = @_; ($$st[0] & LIM_UNAVAIL) != 0;}
sub ISBUSY{my ($st) = @_; ($$st[0] & LIM_BUSY) != 0;}
sub ISBUSYON{ my ($st,$in) = @_; 
	      ($$st[1 + $in/INTEGER_BITS] & (1 << $in % INTEGER_BITS)) != 0;}
sub ISLOCKEDU{ my ($st) = @_; ($$st[0] & LIM_LOCKEDU) != 0;}
sub ISLOCKEDW{ my ($st) = @_; ($$st[0] & LIM_LOCKEDW) != 0;}
sub ISLOCKED{ my ($st) = @_; ($$st[0] & (LIM_LOCKEDU|LIM_LOCKEDW)) != 0;}
sub ISRESDOWN{ my ($st) = @_; ($$st[0] & LIM_RESDOWN) != 0;}
sub ISSBDDOWN{ my ($st) = @_; ($$st[0] & LIM_SBDDOWN) != 0;}
sub ISUNLICENSED{ my ($st) = @_; ($$st[0] & LIM_UNLICENSED) != 0;}
sub ISOK{ my ($st) = @_; ($$st[0] & LIM_OK_MASK) == 0;}
sub ISOKNRES{ my ($st) = @_; ($$st[0] & ~(LIM_RESDOWN | LIM_SBDDOWN)) == 0;}

# Index into load vector and resource table
sub R15S{0}
sub R1M{1}
sub R15M{2}
sub UT{3}
sub PG{4}
sub IO{5}
sub LS{6}
sub IT{7}
sub TMP{8}
sub SWP{9}
sub MEM{10}
sub USR1{11}
sub USR2{12}

sub LSF_BASE_LIC{0}
sub LSF_BATCH_LIC{1}
sub LSF_JS_SCHEDULER_LIC{2} 
sub LSF_JS_LIC{3}
sub LSF_CLIENT_LIC{4}
sub LSF_MC_LIC{5}
sub LSF_ANALYZER_LIC{6}
sub LSF_ANALYZER_SERVER_LIC{7}
sub LSF_MAKE_LIC{8}
sub LSF_PARALLEL_LIC{9}
sub LSF_NUM_LIC_TYPE{10}

sub LSF_LOCAL_MODE{1}
sub LSF_REMOTE_MODE{2}

sub KEEPUID{1}

sub REXF_USEPTY{0x00000001}
sub REXF_CLNTDIR{0x00000002}
sub REXF_TASKPORT{0x00000004}
sub REXF_SHMODE{0x00000008} 
sub REXF_TASKINFO{0x00000010}
sub REXF_REQVCL{0x00000020}
sub REXF_SYNCNIOS{0x00000040}
sub REXF_TTYASYNC{0x00000080}

sub STATUS_TIMEOUT{125}
sub STATUS_IOERR{124}
sub STATUS_EXCESS{123}   
sub STATUS_REX_NOMEM{122}
sub STATUS_REX_FATAL{121}
sub STATUS_REX_CWD{120}
sub STATUS_REX_PTY{119}
sub STATUS_REX_SP{118}
sub STATUS_REX_FORK{117}
sub STATUS_REX_AFS{116}
sub STATUS_REX_UNKNOWN{115}
sub STATUS_REX_NOVCL{114}
sub STATUS_REX_NOSYM{113}
sub STATUS_REX_VCL_INIT{112}
sub STATUS_REX_VCL_SPAWN{111}
sub STATUS_REX_EXEC{110}

sub RF_MAXHOSTS{5}
# ls_rfcontrol() commands
sub RF_CMD_MAXHOSTS{0}
sub RF_CMD_TERMINATE{1}
sub RF_CMD_RXFLAGS{2}

sub RES_CMD_REBOOT{1}
sub RES_CMD_SHUTDOWN{2}
sub RES_CMD_LOGON{3}
sub RES_CMD_LOGOFF{4}

sub LIM_CMD_REBOOT{1}
sub LIM_CMD_SHUTDOWN{2}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

LSF::Base - Object oriented Perl extension for use with the Platform
Computing Corporation's Load Sharing Facility (LSF) Base product.

=head1 SYNOPSIS

  use LSF::Base;
  
  $base = new LSF::Base;
  
  #Cluster configuration

  $info = $base->info or die $@;

  @resources = $info->resTable;
  $res = $resources[0];

  $name  = $res->name;
  $desc  = $res->des;
  $vt    = $res->valueType; # 0,1,2 (BOOLEAN, NUMERIC, STRING)
  $ot    = $res->orderType; # 0,1,2 (INCR, DECR, NA)
  $flags = $res->flags; # RESF_BUILTIN | RESF_*
  $int   = $res->interval; #seconds

  @types   = $info->hostTypes
  @models  = $info->hostModels;
  @archs   = $info->hostArchs;
  @narch   = $info->modelRefs;
  @factors = $info->cpuFactor;
  $n_index = $info->numIndx;
  $n_usr   = $info->numUsrIndx;

  $myhost = $base->getmyhostname;

  $cluster = $base->getclustername;

  $master  = $base->getmastername($cluster);

  $type    = $base->gethosttype($host);

  $model   = $base->gethostmodel($host);

  $factor  = $base->gethostfactor($host);

  $factor  = $base->getmodelfactor($model);

  @hosts = qw(skynet alpha60 wopr ghostwheel);

  # passing in @hosts restricts the results to the listed
  # hosts. 
  @hostinfo = $base->gethostinfo($resreq, \@hosts, $options);

  #return information on all hosts.
  @hostinfo = $base->gethostinfo($resreq, NULL, $options);

  $hi = $hostinfo[0];

  $name      = $hi->hostName;
  $type      = $hi->hostType;
  $model     = $hi->hostModel;
  $factor    = $hi->cpuFactor;
  $max_cpus  = $hi->maxCpus;
  $max_mem   = $hi->maxMem;
  $max_swap  = $hi->maxSwap;
  $max_tmp   = $hi->maxTmp;
  $ndisks    = $hi->nDisks;
  @resources = $hi->resources;
  $windows   = $hi->windows;
  @threshold = $hi->busyThreshold;
  $is_server = $hi->isServer;
  $licensed  = $hi->licensed;
  $rex_pri   = $hi->rexPriority;
  $lic_feat  = $hi->licFeaturesNeeded;

  @params = qw( LSF_SERVERDIR LSF_CONFDIR LSF_SERVER_HOSTS ); # ...
  %env = $base->readconfenv(\@params, $ENV{LSF_ENVDIR});

  #load information and placement functions

  @hostload = $base->load($resreq, $numhosts, $options, $fromhost );
 
  @hostload = $base->loadofhosts( $resreq, $numhosts, $options, $fromhost, \@hosts);

  $hl = $hostload[0];

  $name = $hl->hostName;
  @status = $hl->status

  $bool = ISUNAVAIL(\@status);
  $bool = ISBUSY(\@status);
  $bool = ISBUSYON(\@status,$index);
  $bool = ISLOCKEDU(\@status);
  $bool = ISLOCKEDW(\@status);
  $bool = ISLOCKED(\@status);
  $bool = ISRESDOWN(\@status);
  $bool = ISSBDDOWN(\@status);
  $bool = ISUNLICENSED(\@status);
  $bool = ISOK(\@status);
  $bool = ISOKNRES(\@status);
 
  @where = $base->placereq( $resreq, $number, $options, $fromhost);
  @where = $base->placeofhosts( $resreq, $number, $options, $fromhost, \@hosts);
  
  $place{alpha60} = 3;
  $place{skynet} = 2;

  $base->loadadj($resreq, \%place) or die $@;

  #Task list manipulation

  $resreq = $base->resreq($task);

  ($bool, $resreq) = $base->eligible($task, $mode);

  $base->insertrtask($task);

  $base->insertltask($task);

  $base->deletertask($task);

  $base->deleteltask($task);

  @remote = $base->listrtask($sortflag);

  @local = $base->listltask($sortflag);

  # Remote Execution and task control functions

  $ports = $base->initrex($numports, $options); # or KEEPUID

  $base->ls_connect($hostname) or die $@;

  $bool = base->isconnected($hostname);

  @connections = $base->findmyconnections;

  $base->rexecv($host, \@argv, $options) or die $@;

  $base->rexecve($host, \@argv, $options, \@env) or die $@;
  
  $tid = $base->rtask($host, \@argv, $options);

  $tid = $base->rtaske($host, \@argv, $options, \@env);

  ($tid, $ru) = $base->rwait($options);
  $status = $?;

  $ru = $base->rwaittid($tid, $options);
  $status = $?;
 
  $u_sec = $ru->utime_sec;
  $u_usec = $ru->utime_usec;
  $s_sec = $ru->stime_sec;
  $s_usec = $ru->stime_usec;
  $maxrss = $ru->maxrss;
  $ixrss = $ru->ixrss;
  $idrss = $ru->idrss;
  $minflt = $ru->minflt;
  $majflt = $ru->majflt;
  $nswap = $ru->nswap;
  $inblock = $ru->inblock;
  $outblock = $ru->outblock;
  $msgsnd = $ru->msgsnd;
  $msgrcv = $ru->msgrcv;
  $nsignals = $ru->nsignals;
  $nvcsw = $ru->nvcsw;
  $nivcsw = $ru->nivcsw;

  $base->rkill($tid, $signal) or die $@;

  $base->rsetenv($host, \@env) or die $@;

  $base->chdir($host, $path) or die $@;

  $base->stdinmode($remote) or die $@;

  @tids = $base->getstdin($on, $max);

  $base->setstdin($on, \@tids) or die $@;

  $base->stoprex or die $@;

  $base->donerex or die $@;

  $socket = ls_conntaskport($tid);

  # Remote file operations

  $rfd = $base->ropen($host, $filename, $flags, $mode) or die $@;

  $base->rclose($rfd) or die $@;

  $bytes = $base->rwrite($rfd, $buf, $len);
  
  $bytes = $base->rread($rfd, $buf, $len );

  $offset = $base->rlseek($rfd, $offset, $whence );

  @stat = $base->rfstat(rfd);

  @stat = $base->rstat($host, $path);

  $host = $base->getmnthost($file);

  $host = $base->rgetmnthost($host, $file);

  $base->rfcontrol(RF_CMD_MAXHOSTS, $max);
  $base->rfcontrol(RF_CMD_TERMINATE, $hostname) or die $@;

  $base->lockhost($duration) or die $@;

  $base->unlockhost() or die $@;

  $base->limcontrol($hostname, $opcode) or die $@;

  $base->rescontrol($hostname, $opcode, $data) or die $@;

  $base->perror($message);

  $base->sysmsg;

  $base->errno;
  
  $base->errlog(FILE, $msg);

  $base->fdbusy($fd);

=head1 DESCRIPTION

LSF Base provides basic load sharing functionality consisting of the
following services: Cluster configuration information, Load
information and placement advice, Task list manipulation, Remote
execution and task control, Remote file operations, Administration,
and Error handling.

This library is designed to be used with LSF version 3.2 or LSF
4.0. Please see the "LSF Programmer's guide" and the LSF man pages for
detailed documentation of this API.

The data structures used in the API have been wrapped in Perl objects
for ease of use. The functions set $@ and $? where appropriate, or you
can use the lserrno, sysmsg, and perror functions if you want. 

The perl version of this API has been modified to some extent to act
more "perlish" than the straightforward C API. For instance, return
values have been changed to more closely match what a Perl programmer
expects from a function. Other deviations from the original are noted
in the documentation.

=head1 AUTHOR

Paul Franceus, Capita Technologies, Inc., paul@capita.com

=head1 SEE ALSO

perl(1).
LSF::Batch
LSF Programmer's guide
lslib(3)
LSF man pages for each function.

=cut

