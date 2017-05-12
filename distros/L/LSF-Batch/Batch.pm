package LSF::Batch;

#use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use Exporter;
use DynaLoader;

@ISA = qw(Exporter Autoloader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	ACT_DONE
	ACT_FAIL
	ACT_NO
	ACT_PREEMPT
	ACT_START
	ALL_CALENDARS
	ALL_EVENTS
	ALL_JOB
	ALL_QUEUE
	ALL_USERS
	CALADD
	CALDEL
	CALMOD
	CALOCCS
	CALUNDEL
	CAL_FORCE
	CHECK_HOST
	CHECK_USER
	CONF_CHECK
	CONF_EXPAND
	CONF_NO_CHECK
	CONF_NO_EXPAND
	CONF_RETURN_HOSTSPEC
	CUR_JOB
	DEFAULT_MSG_DESC
	DEFAULT_NUMPRO
	DELETE_NUMBER
	DEL_NUMPRO
	DFT_QUEUE
	DONE_JOB
	EVEADD
	EVEDEL
	EVEMOD
	EVENT_ACTIVE
	EVENT_CAL_DELETE
	EVENT_CAL_MODIFY
	EVENT_CAL_NEW
	EVENT_CAL_UNDELETE
	EVENT_CHKPNT
	EVENT_HOST_CTRL
	EVENT_INACTIVE
	EVENT_JGRP_ADD
	EVENT_JGRP_CNT
	EVENT_JGRP_MOD
	EVENT_JGRP_STATUS
	EVENT_JOB_ACCEPT
	EVENT_JOB_ATTA_DATA
	EVENT_JOB_ATTR_SET
	EVENT_JOB_CHUNK
	EVENT_JOB_CLEAN
	EVENT_JOB_EXCEPTION
	EVENT_JOB_EXECUTE
	EVENT_JOB_EXT_MSG
	EVENT_JOB_FINISH
	EVENT_JOB_FORCE
	EVENT_JOB_FORWARD
	EVENT_JOB_MODIFY
	EVENT_JOB_MODIFY2
	EVENT_JOB_MOVE
	EVENT_JOB_MSG
	EVENT_JOB_MSG_ACK
	EVENT_JOB_NEW
	EVENT_JOB_OCCUPY_REQ
	EVENT_JOB_REQUEUE
	EVENT_JOB_ROUTE
	EVENT_JOB_SIGACT
	EVENT_JOB_SIGNAL
	EVENT_JOB_START
	EVENT_JOB_START_ACCEPT
	EVENT_JOB_STATUS
	EVENT_JOB_SWITCH
	EVENT_JOB_VACATED
	EVENT_LOAD_INDEX
	EVENT_LOG_SWITCH
	EVENT_MBD_DIE
	EVENT_MBD_START
	EVENT_MBD_UNFULFILL
	EVENT_MIG
	EVENT_PRE_EXEC_START
	EVENT_QUEUE_CTRL
	EVENT_REJECT
	EVENT_SBD_JOB_STATUS
	EVENT_SBD_UNREPORTED_STATUS
	EVENT_STATUS_ACK
	EVENT_TYPE_EXCLUSIVE
	EVENT_TYPE_LATCHED
	EVENT_TYPE_PULSE
	EVENT_TYPE_PULSEALL
	EVENT_TYPE_UNKNOWN
	EVE_HIST
	EV_EXCEPT
	EV_FILE
	EV_UNDEF
	EV_USER
	EXIT_INIT_ENVIRON
	EXIT_KILL_ZOMBIE
	EXIT_NORMAL
	EXIT_NO_MAPPING
	EXIT_PRE_EXEC
	EXIT_REMOTE_PERMISSION
	EXIT_REMOVE
	EXIT_REQUEUE
	EXIT_RERUN
	EXIT_RESTART
	EXIT_ZOMBIE
	EXIT_ZOMBIE_JOB
	EXT_ATTA_POST
	EXT_ATTA_READ
	EXT_DATA_AVAIL
	EXT_DATA_NOEXIST
	EXT_DATA_UNAVAIL
	EXT_DATA_UNKNOWN
	EXT_MSG_POST
	EXT_MSG_READ
	EXT_MSG_REPLAY
	FINISH_PEND
	GROUP_JLP
	GROUP_MAX
	GRP_ALL
	GRP_RECURSIVE
	GRP_SHARES
	HOST_BUSY_IO
	HOST_BUSY_IT
	HOST_BUSY_LS
	HOST_BUSY_MEM
	HOST_BUSY_NOT
	HOST_BUSY_PG
	HOST_BUSY_R15M
	HOST_BUSY_R15S
	HOST_BUSY_R1M
	HOST_BUSY_SWP
	HOST_BUSY_TMP
	HOST_BUSY_UT
	HOST_CLOSE
	HOST_GRP
	HOST_JLU
	HOST_NAME
	HOST_OPEN
	HOST_REBOOT
	HOST_SHUTDOWN
	HOST_STAT_BUSY
	HOST_STAT_DISABLED
	HOST_STAT_EXCLUSIVE
	HOST_STAT_FULL
	HOST_STAT_LOCKED
	HOST_STAT_NO_LIM
	HOST_STAT_OK
	HOST_STAT_UNAVAIL
	HOST_STAT_UNLICENSED
	HOST_STAT_UNREACH
	HOST_STAT_WIND
	HPART_HGRP
	H_ATTR_CHKPNTABLE
	H_ATTR_CHKPNT_COPY
	JGRP_ACTIVE
	JGRP_ARRAY_INFO
	JGRP_COUNT_NDONE
	JGRP_COUNT_NEXIT
	JGRP_COUNT_NJOBS
	JGRP_COUNT_NPSUSP
	JGRP_COUNT_NRUN
	JGRP_COUNT_NSSUSP
	JGRP_COUNT_NUSUSP
	JGRP_COUNT_PEND
	JGRP_DEL
	JGRP_HOLD
	JGRP_INACTIVE
	JGRP_INFO
	JGRP_NODE_ARRAY
	JGRP_NODE_GROUP
	JGRP_NODE_JOB
	JGRP_RECURSIVE
	JGRP_RELEASE
	JGRP_RELEASE_PARENTONLY
	JGRP_UNDEFINED
	JOBID_ONLY
	JOBID_ONLY_ALL
	JOB_STAT_DONE
	JOB_STAT_EXIT
	JOB_STAT_NULL
	JOB_STAT_PDONE
	JOB_STAT_PEND
	JOB_STAT_PERR
	JOB_STAT_PSUSP
	JOB_STAT_RUN
	JOB_STAT_SSUSP
	JOB_STAT_UNKWN
	JOB_STAT_USUSP
	JOB_STAT_WAIT
	LAST_JOB
	LOST_AND_FOUND
	LSBATCH_H
	LSBE_AFS_TOKENS
	LSBE_ARRAY_NULL
	LSBE_BAD_ARG
	LSBE_BAD_ATTA_DIR
	LSBE_BAD_CALENDAR
	LSBE_BAD_CHKLOG
	LSBE_BAD_CLUSTER
	LSBE_BAD_CMD
	LSBE_BAD_EVENT
	LSBE_BAD_EXT_MSGID
	LSBE_BAD_FRAME
	LSBE_BAD_GROUP
	LSBE_BAD_HOST
	LSBE_BAD_HOST_SPEC
	LSBE_BAD_HPART
	LSBE_BAD_IDX
	LSBE_BAD_JOB
	LSBE_BAD_JOBID
	LSBE_BAD_LIMIT
	LSBE_BAD_PROJECT_GROUP
	LSBE_BAD_QUEUE
	LSBE_BAD_RESOURCE
	LSBE_BAD_RESREQ
	LSBE_BAD_SIGNAL
	LSBE_BAD_SUBMISSION_HOST
	LSBE_BAD_TIME
	LSBE_BAD_TIMEEVENT
	LSBE_BAD_UGROUP
	LSBE_BAD_USER
	LSBE_BAD_USER_PRIORITY
	LSBE_BIG_IDX
	LSBE_CAL_CYC
	LSBE_CAL_DISABLED
	LSBE_CAL_EXIST
	LSBE_CAL_MODIFY
	LSBE_CAL_USED
	LSBE_CAL_VOID
	LSBE_CHKPNT_CALL
	LSBE_CHUNK_JOB
	LSBE_CONF_FATAL
	LSBE_CONF_WARNING
	LSBE_CONN_EXIST
	LSBE_CONN_NONEXIST
	LSBE_CONN_REFUSED
	LSBE_CONN_TIMEOUT
	LSBE_COPY_DATA
	LSBE_DEPEND_SYNTAX
	LSBE_DLOGD_ISCONN
	LSBE_EOF
	LSBE_ESUB_ABORT
	LSBE_EVENT_FORMAT
	LSBE_EXCEPT_ACTION
	LSBE_EXCEPT_COND
	LSBE_EXCEPT_SYNTAX
	LSBE_EXCLUSIVE
	LSBE_FRAME_BAD_IDX
	LSBE_FRAME_BIG_IDX
	LSBE_HJOB_LIMIT
	LSBE_HP_FAIRSHARE_DEF
	LSBE_INDEX_FORMAT
	LSBE_INTERACTIVE_CAL
	LSBE_INTERACTIVE_RERUN
	LSBE_JGRP_BAD
	LSBE_JGRP_CTRL_UNKWN
	LSBE_JGRP_EXIST
	LSBE_JGRP_HASJOB
	LSBE_JGRP_HOLD
	LSBE_JGRP_NULL
	LSBE_JOB_ARRAY
	LSBE_JOB_ATTA_LIMIT
	LSBE_JOB_CAL_MODIFY
	LSBE_JOB_DEP
	LSBE_JOB_ELEMENT
	LSBE_JOB_EXIST
	LSBE_JOB_FINISH
	LSBE_JOB_FORW
	LSBE_JOB_MODIFY
	LSBE_JOB_MODIFY_ONCE
	LSBE_JOB_MODIFY_USED
	LSBE_JOB_REQUEUED
	LSBE_JOB_REQUEUE_REMOTE
	LSBE_JOB_STARTED
	LSBE_JOB_SUSP
	LSBE_JS_DISABLED
	LSBE_J_UNCHKPNTABLE
	LSBE_J_UNREPETITIVE
	LSBE_LOCK_JOB
	LSBE_LSBLIB
	LSBE_LSLIB
	LSBE_MBATCHD
	LSBE_MC_CHKPNT
	LSBE_MC_EXCEPTION
	LSBE_MC_HOST
	LSBE_MC_REPETITIVE
	LSBE_MC_TIMEEVENT
	LSBE_MIGRATION
	LSBE_MOD_JOB_NAME
	LSBE_MSG_DELIVERED
	LSBE_MSG_RETRY
	LSBE_NOLSF_HOST
	LSBE_NOMATCH_CALENDAR
	LSBE_NOMATCH_EVENT
	LSBE_NOT_STARTED
	LSBE_NO_CALENDAR
	LSBE_NO_ENOUGH_HOST
	LSBE_NO_ENV
	LSBE_NO_ERROR
	LSBE_NO_EVENT
	LSBE_NO_FORK
	LSBE_NO_GROUP
	LSBE_NO_HOST
	LSBE_NO_HOST_GROUP
	LSBE_NO_HPART
	LSBE_NO_IFREG
	LSBE_NO_INTERACTIVE
	LSBE_NO_JOB
	LSBE_NO_JOBID
	LSBE_NO_JOBMSG
	LSBE_NO_JOB_PRIORITY
	LSBE_NO_LICENSE
	LSBE_NO_MEM
	LSBE_NO_OUTPUT
	LSBE_NO_RESOURCE
	LSBE_NO_USER
	LSBE_NO_USER_GROUP
	LSBE_NQS_BAD_PAR
	LSBE_NQS_NO_ARRJOB
	LSBE_NUM_ERR
	LSBE_ONLY_INTERACTIVE
	LSBE_OP_RETRY
	LSBE_OVER_LIMIT
	LSBE_OVER_RUSAGE
	LSBE_PEND_CAL_JOB
	LSBE_PERMISSION
	LSBE_PERMISSION_MC
	LSBE_PJOB_LIMIT
	LSBE_PORT
	LSBE_PREMATURE
	LSBE_PROC_NUM
	LSBE_PROTOCOL
	LSBE_PTY_INFILE
	LSBE_QJOB_LIMIT
	LSBE_QUEUE_CLOSED
	LSBE_QUEUE_HOST
	LSBE_QUEUE_NAME
	LSBE_QUEUE_USE
	LSBE_QUEUE_WINDOW
	LSBE_ROOT
	LSBE_RUN_CAL_JOB
	LSBE_SBATCHD
	LSBE_SBD_UNREACH
	LSBE_SERVICE
	LSBE_SP_CHILD_DIES
	LSBE_SP_CHILD_FAILED
	LSBE_SP_COPY_FAILED
	LSBE_SP_DELETE_FAILED
	LSBE_SP_FAILED_HOSTS_LIM
	LSBE_SP_FIND_HOST_FAILED
	LSBE_SP_FORK_FAILED
	LSBE_SP_SPOOLDIR_FAILED
	LSBE_SP_SRC_NOT_SEEN
	LSBE_START_TIME
	LSBE_STOP_JOB
	LSBE_SYNTAX_CALENDAR
	LSBE_SYSCAL_EXIST
	LSBE_SYS_CALL
	LSBE_TIME_OUT
	LSBE_UGROUP_MEMBER
	LSBE_UJOB_LIMIT
	LSBE_UNKNOWN_EVENT
	LSBE_UNSUPPORTED_MC
	LSBE_USER_JLIMIT
	LSBE_XDR
	LSB_CHKPERIOD_NOCHNG
	LSB_CHKPNT_COPY
	LSB_CHKPNT_FORCE
	LSB_CHKPNT_KILL
	LSB_CHKPNT_MIG
	LSB_CHKPNT_STOP
	LSB_EVENT_VERSION3_0
	LSB_EVENT_VERSION3_1
	LSB_EVENT_VERSION3_2
	LSB_EVENT_VERSION4_0
	LSB_KILL_REQUEUE
	LSB_MAX_ARRAY_IDX
	LSB_MAX_ARRAY_JOBID
	LSB_MAX_SD_LENGTH
	LSB_MODE_BATCH
	LSB_MODE_JS
	LSB_SIG_NUM
	LSF_JOBIDINDEX_FILENAME
	LSF_JOBIDINDEX_FILETAG
	MASTER_CONF
	MASTER_FATAL
	MASTER_MEM
	MASTER_NULL
	MASTER_RECONFIG
	MASTER_RESIGN
	MAXDESCLEN
	MAXPATHLEN
	MAX_CALENDARS
	MAX_CHARLEN
	MAX_CMD_DESC_LEN
	MAX_GROUPS
	MAX_HPART_USERS
	MAX_LSB_NAME_LEN
	MAX_USER_EQUIVALENT
	MAX_USER_MAPPING
	MAX_VERSION_LEN
	MBD_CKCONFIG
	MBD_RECONFIG
	MBD_RESTART
	MSGSIZE
	NO_PEND_REASONS
	NQSQ_GRP
	NQS_ROUTE
	NQS_SERVER
	NQS_SIG
	NUM_JGRP_COUNTERS
	PEND_ADMIN_STOP
	PEND_CHKPNT_DIR
	PEND_CHUNK_FAIL
	PEND_HAS_RUN
	PEND_HOST_ACCPT_ONE
	PEND_HOST_DISABLED
	PEND_HOST_EXCLUSIVE
	PEND_HOST_JOB_LIMIT
	PEND_HOST_JOB_RUSAGE
	PEND_HOST_JOB_SSUSP
	PEND_HOST_JS_DISABLED
	PEND_HOST_LESS_SLOTS
	PEND_HOST_LOAD
	PEND_HOST_LOCKED
	PEND_HOST_MISS_DEADLINE
	PEND_HOST_NONEXCLUSIVE
	PEND_HOST_NO_LIM
	PEND_HOST_NO_USER
	PEND_HOST_PART_PRIO
	PEND_HOST_PART_USER
	PEND_HOST_QUE_MEMB
	PEND_HOST_QUE_RESREQ
	PEND_HOST_QUE_RUSAGE
	PEND_HOST_RES_REQ
	PEND_HOST_SCHED_TYPE
	PEND_HOST_UNLICENSED
	PEND_HOST_USR_JLIMIT
	PEND_HOST_USR_SPEC
	PEND_HOST_WINDOW
	PEND_HOST_WIN_WILL_CLOSE
	PEND_JGRP_HOLD
	PEND_JGRP_INACT
	PEND_JGRP_RELEASE
	PEND_JGRP_WAIT
	PEND_JOB
	PEND_JOB_ARRAY_JLIMIT
	PEND_JOB_DELAY_SCHED
	PEND_JOB_DEPEND
	PEND_JOB_DEP_INVALID
	PEND_JOB_DEP_REJECT
	PEND_JOB_ENFUGRP
	PEND_JOB_ENV
	PEND_JOB_EXEC_INIT
	PEND_JOB_FORWARDED
	PEND_JOB_JS_DISABLED
	PEND_JOB_LOGON_FAIL
	PEND_JOB_MIG
	PEND_JOB_MODIFY
	PEND_JOB_NEW
	PEND_JOB_NO_FILE
	PEND_JOB_NO_PASSWD
	PEND_JOB_NO_SPAN
	PEND_JOB_OPEN_FILES
	PEND_JOB_PATHS
	PEND_JOB_PRE_EXEC
	PEND_JOB_QUE_REJECT
	PEND_JOB_RCLUS_UNREACH
	PEND_JOB_REASON
	PEND_JOB_REQUEUED
	PEND_JOB_RESTART_FILE
	PEND_JOB_RMT_ZOMBIE
	PEND_JOB_RSCHED_ALLOC
	PEND_JOB_RSCHED_START
	PEND_JOB_SPREAD_TASK
	PEND_JOB_START_FAIL
	PEND_JOB_START_TIME
	PEND_JOB_START_UNKNWN
	PEND_JOB_SWITCH
	PEND_JOB_TIME_INVALID
	PEND_LOAD_UNAVAIL
	PEND_NO_MAPPING
	PEND_NQS_FUN_OFF
	PEND_NQS_REASONS
	PEND_NQS_RETRY
	PEND_QUE_HOST_JLIMIT
	PEND_QUE_INACT
	PEND_QUE_JOB_LIMIT
	PEND_QUE_NO_SPAN
	PEND_QUE_PJOB_LIMIT
	PEND_QUE_PRE_FAIL
	PEND_QUE_PROC_JLIMIT
	PEND_QUE_SPREAD_TASK
	PEND_QUE_USR_JLIMIT
	PEND_QUE_USR_PJLIMIT
	PEND_QUE_WINDOW
	PEND_QUE_WINDOW_WILL_CLOSE
	PEND_RMT_PERMISSION
	PEND_SBD_GETPID
	PEND_SBD_JOB_ACCEPT
	PEND_SBD_JOB_QUOTA
	PEND_SBD_JOB_REQUEUE
	PEND_SBD_LOCK
	PEND_SBD_NO_MEM
	PEND_SBD_NO_PROCESS
	PEND_SBD_ROOT
	PEND_SBD_SOCKETPAIR
	PEND_SBD_UNREACH
	PEND_SBD_ZOMBIE
	PEND_SYS_NOT_READY
	PEND_SYS_UNABLE
	PEND_TIME_EXPIRED
	PEND_UGRP_JOB_LIMIT
	PEND_UGRP_PJOB_LIMIT
	PEND_UGRP_PROC_JLIMIT
	PEND_USER_JOB_LIMIT
	PEND_USER_PJOB_LIMIT
	PEND_USER_PROC_JLIMIT
	PEND_USER_RESUME
	PEND_USER_STOP
	PEND_WAIT_NEXT
	PREPARE_FOR_OP
	PRINT_LONG_NAMELIST
	PRINT_MCPU_HOSTS
	PRINT_SHORT_NAMELIST
	QUEUE_ACTIVATE
	QUEUE_CLOSED
	QUEUE_INACTIVATE
	QUEUE_OPEN
	QUEUE_STAT_ACTIVE
	QUEUE_STAT_DISC
	QUEUE_STAT_NOPERM
	QUEUE_STAT_OPEN
	QUEUE_STAT_RUN
	QUEUE_STAT_RUNWIN_CLOSE
	Q_ATTRIB_BACKFILL
	Q_ATTRIB_CHKPNT
	Q_ATTRIB_DEFAULT
	Q_ATTRIB_ENQUE_INTERACTIVE_AHEAD
	Q_ATTRIB_EXCLUSIVE
	Q_ATTRIB_EXCL_RMTJOB
	Q_ATTRIB_FAIRSHARE
	Q_ATTRIB_HOST_PREFER
	Q_ATTRIB_IGNORE_DEADLINE
	Q_ATTRIB_MC_FAST_SCHEDULE
	Q_ATTRIB_NONPREEMPTABLE
	Q_ATTRIB_NONPREEMPTIVE
	Q_ATTRIB_NO_HOST_TYPE
	Q_ATTRIB_NO_INTERACTIVE
	Q_ATTRIB_NQS
	Q_ATTRIB_ONLY_INTERACTIVE
	Q_ATTRIB_PREEMPTABLE
	Q_ATTRIB_PREEMPTIVE
	Q_ATTRIB_RECEIVE
	Q_ATTRIB_RERUNNABLE
	READY_FOR_OP
	RLIMIT_CORE
	RLIMIT_CPU
	RLIMIT_DATA
	RLIMIT_FSIZE
	RLIMIT_RSS
	RLIMIT_STACK
	RLIM_INFINITY
	RUNJOB_OPT_NORMAL
	RUNJOB_OPT_NOSTOP
	RUN_JOB
	SORT_HOST
	SUB2_BSUB_BLOCK
	SUB2_HOLD
	SUB2_HOST_NT
	SUB2_HOST_UX
	SUB2_IN_FILE_SPOOL
	SUB2_JOB_CMD_SPOOL
	SUB2_JOB_PRIORITY
	SUB2_MODIFY_CMD
	SUB2_QUEUE_CHKPNT
	SUB2_QUEUE_RERUNNABLE
	SUB_CHKPNTABLE
	SUB_CHKPNT_DIR
	SUB_CHKPNT_PERIOD
	SUB_DEPEND_COND
	SUB_ERR_FILE
	SUB_EXCEPT
	SUB_EXCLUSIVE
	SUB_HOST
	SUB_HOST_SPEC
	SUB_INTERACTIVE
	SUB_IN_FILE
	SUB_JOB_NAME
	SUB_LOGIN_SHELL
	SUB_MAIL_USER
	SUB_MODIFY
	SUB_MODIFY_ONCE
	SUB_NOTIFY_BEGIN
	SUB_NOTIFY_END
	SUB_OTHER_FILES
	SUB_OUT_FILE
	SUB_PRE_EXEC
	SUB_PROJECT_NAME
	SUB_PTY
	SUB_PTY_SHELL
	SUB_QUEUE
	SUB_REASON_CPULIMIT
	SUB_REASON_DEADLINE
	SUB_REASON_PROCESSLIMIT
	SUB_REASON_RUNLIMIT
	SUB_RERUNNABLE
	SUB_RESTART
	SUB_RESTART_FORCE
	SUB_RES_REQ
	SUB_TIME_EVENT
	SUB_USER_GROUP
	SUB_WINDOW_SIG
	SUSP_ADMIN_STOP
	SUSP_HOST_LOCK
	SUSP_JOB
	SUSP_LOAD_REASON
	SUSP_LOAD_UNAVAIL
	SUSP_MBD_LOCK
	SUSP_MBD_PREEMPT
	SUSP_PG_IT
	SUSP_QUEUE_REASON
	SUSP_QUEUE_WINDOW
	SUSP_QUE_RESUME_COND
	SUSP_QUE_STOP_COND
	SUSP_REASON_RESET
	SUSP_RESCHED_PREEMPT
	SUSP_RES_LIMIT
	SUSP_RES_RESERVE
	SUSP_SBD_PREEMPT
	SUSP_SBD_STARTUP
	SUSP_USER_REASON
	SUSP_USER_RESUME
	SUSP_USER_STOP
	THIS_VERSION
	TO_BOTTOM
	TO_TOP
	USER_GRP
	USER_JLP
	XF_OP_EXEC2SUB
	XF_OP_EXEC2SUB_APPEND
	XF_OP_SUB2EXEC
	XF_OP_SUB2EXEC_APPEND
	ZOMBIE_JOB
	_PATH_NULL
	LSB_HOST_OK
	LSB_HOST_BUSY
        LSB_HOST_CLOSED
        LSB_HOST_FULL
        LSB_HOST_UNLICENSED
        LSB_HOST_UNREACH
        LSB_HOST_UNAVAIL
        LSB_ISBUSYON
        IS_PEND
        IS_START
        IS_FINISH
        IS_SUSP
        IS_POST_DONE
        IS_POST_ERR
        IS_POST_FINISH
);
$VERSION = '0.04';

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.  If a constant is not found then control is passed
  # to the AUTOLOAD in AutoLoader.
  
  my $constname; 
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname, @_ ? $_[0] : 0); 
  if ($! != 0) { 
    if ($! =~ /Invalid/) { 
      $AutoLoader::AUTOLOAD = $AUTOLOAD; 
      goto &AutoLoader::AUTOLOAD; 
    } 
    else { 
      croak "Your vendor has not defined LSF::Batch macro $constname"; 
    } 
  } 
  eval "sub $AUTOLOAD { $val }";
  &$AUTOLOAD; 
}

bootstrap LSF::Batch $VERSION;

# Preloaded methods go here.

sub LSB_HOST_OK{my ($st) = @_; st == &HOST_STAT_OK; }
sub LSB_HOST_BUSY{my ($st) = @_; ($st & &HOST_STAT_BUSY) != 0;}
sub LSB_HOST_CLOSED{my ($st) = @_; ($st & (&HOST_STAT_WIND |
					&HOST_STAT_DISABLED | 
					&HOST_STAT_LOCKED | 
					&HOST_STAT_FULL | 
					&HOST_STAT_NO_LIM)) != 0;}
sub LSB_HOST_FULL{my ($st) = @_;($st & &HOST_STAT_FULL) != 0;}
sub LSB_HOST_UNLICENSED{ my ($st) = @_; ($st & &HOST_STAT_UNLICENSED) != 0;}
sub LSB_HOST_UNREACH{ my ($st) = @_; ($st & &HOST_STAT_UNREACH) != 0;}
sub LSB_HOST_UNAVAIL{ my ($st) = @_; ($st & &HOST_STAT_UNAVAIL) != 0;}
sub LSB_ISBUSYON{ my ($st, $in) = @_; (($st[$in/&INTEGER_BITS]) & 
				       (1 << $in % &INTEGER_BITS)) != 0;}

#removed for LSF 4.0. 64 bit job ID is broken down within the XS side 
#because of 32bit perl.
#sub LSB_JOBID{ my ($id, $ix) = @_; ($ix << 20) | $id;}
#sub LSB_ARRAY_IDX{ my ($id) = @_;($id == -1)?(0):($id >> 20);}
#sub LSB_ARRAY_JOBID{ my ($id) = @_;
#		     ($id == -1)?(-1):($id & LSB_MAX_ARRAY_JOBID);}

sub IS_PEND{my ($s) = @_;($s & &JOB_STAT_PEND) || ($s & &JOB_STAT_PSUSP);}
sub IS_START{my ($s) = @_;($s & &JOB_STAT_RUN) || ($s & &JOB_STAT_SSUSP)
	       || ($s & &JOB_STAT_USUSP);}
sub IS_FINISH{my ($s) = @_; ($s & &JOB_STAT_DONE) || ($s & &JOB_STAT_EXIT);}
sub IS_SUSP{my ($s) = @_; return ($s & &JOB_STAT_PSUSP) || ($s & &JOB_STAT_SSUSP)
	      || ($s & &JOB_STAT_USUSP);}

sub IS_POST_DONE{my ($s) = @_; ($s & &JOB_STAT_PDONE) == &JOB_STAT_PDONE;}
sub IS_POST_ERR{my ($s) = @_; ($s & &JOB_STAT_PERR) == &JOB_STAT_PERR;}
sub IS_POST_FINISH{my ($s) = @_; &IS_POST_DONE($s) || &IS_POST_ERR($s);}

#constants that aren't exported using the constant() function since they
#are strings
sub ALL_USERS{"all";}
sub DEFAULT_MSG_DESC{"no description";}
sub LOST_AND_FOUND{"lost_and_found";}
sub LSF_JOBIDINDEX_FILENAME{"lsb.events.index";}
sub LSF_JOBIDINDEX_FILETAG{"#LSF_JOBID_INDEX_FILE";}
sub THIS_VERSION{"4.0";}
sub _PATH_NULL{"/dev/null";}

sub new{
  my $type = shift;
  my $appname = shift;
  my $self = {};

  return eval{
    if( -e "/etc/lsf.conf" or $ENV{LSF_ENVDIR} ){
      bless $self, $type;
      $self->init($appname) or die $@;
      return $self;
    }
    else{
      die "Can't access lsf.conf file or LSF_ENVDIR not set";
    }
  }
}
  

sub submit{
  my $self = shift;
  my %subreq;
  my ($key,$value,$job);

  #parse the arguments and build a hash to pass to the XS do_submit call.
  return eval{
  PARSE:
    while(@_){
      $_ = shift;
      #print "got flag $_\n";
      die "invalid argument $_ \n" unless /^-/;
      if( @_ and @_[0] !~ /^-/ ){
	$subreq{$_} = shift;
      }
      else{
	$subreq{$_} = 1;
      }
    }
    $job = do_submit(\%subreq);
    return $job;
  }
}

1;

package LSF::Batch::jobPtr;

sub modify{
  my $self = shift;
  my %subreq;
  my ($key,$value);

  #parse the arguments and build a hash to pass to the XS do_modify call.
  return eval{
  PARSE:
    while(@_){
      $_ = shift;
      die "invalid argument $_ \n" unless /^-/;
      if( @_ and @_[0] !~ /^-/ ){
	$subreq{$_} = shift;
      }
      else{
	$subreq{$_} = 1;
      }
    }
    $self->do_modify(\%subreq) or die $@;
    1;
  }
}

sub jobArray{
  my $self = shift;
  my $start = shift;
  my $end = shift;
  my $step = 1;
  $step = shift if @_;
  my %array;

  for( $i = $start; $i <= $end; $i += $step ){
    $array{$i} = new LSF::Batch::jobPtr ($self->jobId, $i);
  }
  return %array;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

LSF::Batch - Perl extension for use with the Platform Computing
Corporation's Load Sharing Facility (LSF) Batch product.

=head1 SYNOPSIS



  use LSF::Batch;

  #initialization and reconfiguration

  $batch = new LSF::Batch("appname"); (calls lsb_init)

  $batch->reconfig or die $@;

  $batch->hostcontrol($host, HOST_CLOSE|HOST_OPEN|HOST_REBOOT|HOST_SHUTDOWN)
    or die $@;

  $batch->queuecontrol($queue, $opcode) or die $@

  #error messages. Note: calls set $? and $@ and return appropriate 
  #values upon failure.

  $msg = $batch->sysmsg;

  $batch->perror;

  #job submission and modification

  $job = $batch->submit( -J | -jobName        => "foo",
                         -q | -queue          => "normal",
                         -m | -hosts          => [qw(a b c d)],
                         -R | -resreq         => "select[solaris && r1m<1.0]"
                         -c | -cpulimit       => 300,
                         -W | -runlimit       => 3600,
                         -F | -filelimit      => 100000,
                         -M | -memlimit       => 1000,
                         -D | -datalimit      => 122121,
                         -S | -stacklimit     => 122331,
                         -C | -corelimit      => 11111,
                         -spec | -hostSpec    => "foo",
                         -w | -dependCond     => "ended(foo2)",
                         -b | -beginTime      => time + 100,
                         -t | -termTime       => time + 1000,
                         -sig | -sigValue            => SIGINT,etc.
                         -i | -inFile         => "input",
                         -o | -outFile        => "output",
                         -e | -errFile        => "error",
                         -command             => "sleep 30",
                         -k | -checkpointable => "/checkpoint",
                         -period | -chkpntPeriod => 20,
                         -f | -transfer       => "file1 > file2",
                         -f | -transfer       => "file3 < file2",
                         -E | -preExec        => "run_me_first",
                         -u | -mailUser       => "user@mail",
                         -P | -projectName    => "work",
                         -n | -numProcessors  => 1,
                         -maxNumProcessors    => 4,
                         -L | -loginShell     => "/bin/ksh",
                         -G | -userGroup      => "workers",
                         -X | -exception      => 
                                "overrun(10)::kill;abend(1)::setexcept(fail)",
                         -checkpointCopy,
                         -checkpointForce,
                         -x | -exclusive,
                         -B | -notifyBegin,
                         -N | -notifyEnd,
                         -restartForce,
                         -r | -rerunnable,
                         -I | -interactive,
                         -Ip | -pty,
                         -Is | -ptyShell,
                         -H | -hold,
                         -K | -block,
     
  $job->modify( ... ) or die; #similar to submit interface
                         
  #the jobArray function returns a hash of job objects, each corresponding
  #to an element of the job array. It is not the most elegant solution, but
  #it will work until someone comes up with a better way.

  %array = $job->jobArray($start, $end, $step);

  $job1 = $array{$start};

  #under LSF 4.0, the jobid is a 64 bit number. Instead of requiring
  #a 64 bit perl, I split the jobid and array index from within the library.
  #Therefore, many calls take a job object rather than the jobID. You
  #can create a new job object by using new:
  
  $newjob = new LSF::Batch::jobPtr ($id,$index);

  $id = $job->jobId;
  $index = $job->arrayIdx;

  $queue = $job->queue;

  $job->chkpnt($period, $options)

  $job->mig(\@hosts, $options);

  $position = $job->move($position, $opcode);

  $filename = $job->peek;

  $job->signal($signal);
  
  $job->switch($queue);

  $job->run(\@hosts, options);

  #submitted job information

  $records = $batch->openjobinfo($jobid, $jobname, $user, $queue, 
                                  $host, $options);

  $jobinfo = $batch->readjobinfo;  

  $job        = $jobinfo->job;
  $id         = $jobinfo->jobId;
  $user       = $jobinfo->user;
  $status     = $jobinfo->status;
  $reasons    = $jobinfo->reasons;
  $subreasons = $jobinfo->subreasons;
  $fromhost   = $jobinfo->fromHost;
  $subtime    = $jobinfo->submitTime;
  $starttime  = $jobinfo->startTime;
  $endtime    = $jobinfo->endTime;
  $cputime    = $jobinfo->cpuTime;
  $umask      = $jobinfo->umask;
  $cwd        = $jobinfo->cwd;
  $homedir    = $jobinfo->subHomeDir;
  $numexhosts = $jobinfo->numExHosts;
  @exhosts    = $jobinfo->exHosts;
  $factor     = $jobinfo->cpiFactor
  $nidx       = $jobinfo->nIdx;
  $loadsched  = $jobinfo->loadSched;
  $loadstop   = $jobinfo->loadStop;
  $job        = $jobinfo->submit;
  $rusage     = $jobinfo->jRusage;
  $pendreason = $jobinfo->pendreason;
  $suspreason = $jobinfo->suspreason;
  $submit     = $jobinfo->submit;

  #the submit object contains all the fields of the submit structure.
  $submit->jobName;
  $submit->queue;
  $submit->resReq;
  $submit->command;
  #etc.

  $batch->closejobinfo();

  #Batch system information

  $params = $batch->paramterinfo;

  $params->defaultQueues;
  $params->defaultHostSpec;
  $params->mbatchdInterval;
  $params->sbatchdInterval;
  $params->jobAcceptInterval;
  $params->maxDispRetries;
  $params->maxSbdRetries;
  $params->preemptPeriod;
  $params->cleanPeriod;
  $params->maxNumJobs;
  $params->historyHours;
  $params->pgSuspendIt;

  @info = $batch->hostinfo(\@hosts);

  @info = $batch->hostinfo_ex(\@hosts, $resreq, $options);

  $hi = $info[0];
  $host = $hi->host;
  $status = $hi->hStatus;
  $sched = $hi->busySched;
  $stop = $hi->busyStop;

  @load = $hi->load;
  @loadsched = $hi->loadSched;
  @loadstop = $hi->loadStop;
  $windows = $hi->windows;
  $ujl = $hi->userJobLimit;
  $maxj = $hi->maxJobs;
  $numj = $hi->numJobs;
  $nrun = $hi->numRUN;
  $nssusp = $hi->numSSUSP;
  $nususp = $hi->numUSUSP;
  $nresv = $hi->numRESERVE;
  $mig = $hi->mig;
  $attr = $hi->attr;
  @realload = $hi->realLoad;
  $sig = $hi->chkSig;

  @info = $batch->userinfo(\@users);

  $ui = $info[0];

  $ui->user;
  $ui->procJobLimit;
  $ui->maxJobs;
  $ui->numStartJobs;
  $ui->numJobs;
  $ui->numPEND;
  $ui->numRUN;
  $ui->numSSUSP;
  $ui->numUSUSP;
  $ui->numRESERVE;

  %info = $batch->hostgrpinfo(\@groups, $options)

  @groups = keys %info;
  @members = values %info;

  %info = $batch->usergrpinfo(\@groups, $options)

  @groups = keys %info;
  @members = values %info;

  @queueinfo = $batch->queueinfo( \@queues, \@hosts, \@users, options) 
  $qi = $queueinfo[0];

  $queue           = $qi->queue;
  $desc            = $qi->description;
  $pri             = $qi->priority;
  $nice            = $qi->nice;
  @users           = $qi->userList;
  @hosts           = $qi->hostList;
  @loadSched       = $qi->loadSched;
  @loadStop        = $qi->loadStop;
  $ujoblim         = $qi->userJobLimit;
  $pjoblim         = $qi->procJobLimit;
  $windows         = $qi->windows;
  @limits          = $qi->rLimits;
  $hostspec        = $qi->hostSpec;
  $qattrib         = $qi->qAttrib;
  $qstat           = $qi->qStatus;
  $maxjobs         = $qi->maxJobs;
  $numjobs         = $qi->numJobs;
  $numpend         = $qi->numPEND;
  $numrun          = $qi->numRUN;
  $nssusp          = $qi->numSSUSP;
  $nususp          = $qi->numUSUSP;
  $mig             = $qi->mig;
  $dispatch        = $qi->windowsD;
  $nqsqueues       = $qi->nqsQueues;
  $usershared      = $qi->userShares;
  $defaulthostspec = $qi->defaultHostSpec;
  $proclimit       = $qi->procLimit;
  $admins          = $qi->admins;
  $precmd          = $qi->preCmd;
  $postcmd         = $qi->postCmd;
  $requeuevalues   = $qi->requeueEValues;
  $hostjoblimit    = $qi->hostJobLimit;
  $resreq          = $qi->resReq;
  $numreserve      = $qi->numRESERVE;
  $holdtime        = $qi->slotHoldTime;
  $sendto          = $qi->sndJobsTo;
  $recvfrom        = $qi->rcvJobsFrom;
  $resumecond      = $qi->resumeCond;
  $stopcond        = $qi->stopCond;
  $jobstarter      = $qi->jobStarter;
  $suspendaction   = $qi->suspendActCmd;
  $resumeaction    = $qi->resumeActCmd;
  $termaction      = $qi->terminateActCmd;
  @sigmap          = $qi->sigMap;
  $preemption      = $qi->preemption;
  @shareaccts      = $qi->shareAccts;

  $sa = pop @shareaccts;

  $path     = $sa->shareAcctPath
  $shares   = $sa->shares;
  $priority = $sa->priority;
  $njobs    = $sa->numStartJobs;
  $histtime = $sa->histCpuTime;
  $reserve  = $sa->numReserveJobs;
  $runtime  = $sa->runTime;
   
  @info = $batch->sharedresourceinfo(\@resources, $hostname);

  $sri = @info[0];

  $name = $sri->resourceName;
  @instances = $sri->instances;
  
  $inst = @instances[0];

  $total = $inst->totalValue;
  $reserve = $inst->reserveValue;
  @hosts = $inst->hostList;

  
  @info = $batch->hostpartinfo(\@partitions);

  $part = $info[0];

  $name = $part->hostPart;
  $hosts = $part->hostList;
  @users = $part->users;

  $user = $users[0];

  $name = $user->user;
  $shares = $user->shares;
  $priority = $user->priority;
  $numstart = $user->numStartJobs;
  $numreserve = $user->numReserveJobs;
  $cpu = $user->histCpuTime;

  open LOG, "/usr/local/lsf/work/clustername/logdir/lsb.events";

  $line = 1;
  while( $er = $b->geteventrec( LOG, $line)){
    $el = $er->eventLog;
    $lt = localtime $er->eventTime;
    print "event $line at $lt:";
    if( $er->type == EVENT_JOB_NEW ){
       $id = $el->jobId;
       $user = $el->userName;
       $res = $el->resReq;
       $q = $el->queue;
       print "New job $job submitted to queue $q by $user\n";
    }
    ...
    else{
       print "Received event of type ", $er->type, "\n";
    }

  #NOT YET IMPLEMENTED:

  $batch->pendreason(...);
  $batch->suspreason(...);


=head1 DESCRIPTION

LSF Batch provides access to batch queueing services across
a cluster of machines. 

This library is designed to be used with LSF version 4.x. Please see
the "LSF Programmer's guide" and the LSF man pages for detailed
documentation of this API.

The data structures used in the API have been wrapped in Perl objects
for ease of use. The functions set $@ and $? where appropriate, or you
can use the lserrno, sysmsg, and perror functions if you want. 

The perl version of this API has been modified to some extent to act
more "perlish" than the straightforward C API. For instance, return
values have been changed to more closely match what a Perl programmer
expects from a function. Other deviations from the original are noted
in the documentation.

=head1 Exported constants

  ACT_DONE
  ACT_FAIL
  ACT_NO
  ACT_PREEMPT
  ACT_START
  ALL_CALENDARS
  ALL_EVENTS
  ALL_JOB
  ALL_QUEUE
  ALL_USERS
  CALADD
  CALDEL
  CALMOD
  CALOCCS
  CALUNDEL
  CAL_FORCE
  CHECK_HOST
  CHECK_USER
  CONF_CHECK
  CONF_EXPAND
  CONF_NO_CHECK
  CONF_NO_EXPAND
  CONF_RETURN_HOSTSPEC
  CUR_JOB
  DEFAULT_MSG_DESC
  DEFAULT_NUMPRO
  DELETE_NUMBER
  DEL_NUMPRO
  DFT_QUEUE
  DONE_JOB
  EVEADD
  EVEDEL
  EVEMOD
  EVENT_ACTIVE
  EVENT_CAL_DELETE
  EVENT_CAL_MODIFY
  EVENT_CAL_NEW
  EVENT_CAL_UNDELETE
  EVENT_CHKPNT
  EVENT_HOST_CTRL
  EVENT_INACTIVE
  EVENT_JGRP_ADD
  EVENT_JGRP_CNT
  EVENT_JGRP_MOD
  EVENT_JGRP_STATUS
  EVENT_JOB_ACCEPT
  EVENT_JOB_ATTA_DATA
  EVENT_JOB_ATTR_SET
  EVENT_JOB_CHUNK
  EVENT_JOB_CLEAN
  EVENT_JOB_EXCEPTION
  EVENT_JOB_EXECUTE
  EVENT_JOB_EXT_MSG
  EVENT_JOB_FINISH
  EVENT_JOB_FORCE
  EVENT_JOB_FORWARD
  EVENT_JOB_MODIFY
  EVENT_JOB_MODIFY2
  EVENT_JOB_MOVE
  EVENT_JOB_MSG
  EVENT_JOB_MSG_ACK
  EVENT_JOB_NEW
  EVENT_JOB_OCCUPY_REQ
  EVENT_JOB_REQUEUE
  EVENT_JOB_ROUTE
  EVENT_JOB_SIGACT
  EVENT_JOB_SIGNAL
  EVENT_JOB_START
  EVENT_JOB_START_ACCEPT
  EVENT_JOB_STATUS
  EVENT_JOB_SWITCH
  EVENT_JOB_VACATED
  EVENT_LOAD_INDEX
  EVENT_LOG_SWITCH
  EVENT_MBD_DIE
  EVENT_MBD_START
  EVENT_MBD_UNFULFILL
  EVENT_MIG
  EVENT_PRE_EXEC_START
  EVENT_QUEUE_CTRL
  EVENT_REJECT
  EVENT_SBD_JOB_STATUS
  EVENT_SBD_UNREPORTED_STATUS
  EVENT_STATUS_ACK
  EVENT_TYPE_EXCLUSIVE
  EVENT_TYPE_LATCHED
  EVENT_TYPE_PULSE
  EVENT_TYPE_PULSEALL
  EVENT_TYPE_UNKNOWN
  EVE_HIST
  EV_EXCEPT
  EV_FILE
  EV_UNDEF
  EV_USER
  EXIT_INIT_ENVIRON
  EXIT_KILL_ZOMBIE
  EXIT_NORMAL
  EXIT_NO_MAPPING
  EXIT_PRE_EXEC
  EXIT_REMOTE_PERMISSION
  EXIT_REMOVE
  EXIT_REQUEUE
  EXIT_RERUN
  EXIT_RESTART
  EXIT_ZOMBIE
  EXIT_ZOMBIE_JOB
  EXT_ATTA_POST
  EXT_ATTA_READ
  EXT_DATA_AVAIL
  EXT_DATA_NOEXIST
  EXT_DATA_UNAVAIL
  EXT_DATA_UNKNOWN
  EXT_MSG_POST
  EXT_MSG_READ
  EXT_MSG_REPLAY
  FINISH_PEND
  GROUP_JLP
  GROUP_MAX
  GRP_ALL
  GRP_RECURSIVE
  GRP_SHARES
  HOST_BUSY_IO
  HOST_BUSY_IT
  HOST_BUSY_LS
  HOST_BUSY_MEM
  HOST_BUSY_NOT
  HOST_BUSY_PG
  HOST_BUSY_R15M
  HOST_BUSY_R15S
  HOST_BUSY_R1M
  HOST_BUSY_SWP
  HOST_BUSY_TMP
  HOST_BUSY_UT
  HOST_CLOSE
  HOST_GRP
  HOST_JLU
  HOST_NAME
  HOST_OPEN
  HOST_REBOOT
  HOST_SHUTDOWN
  HOST_STAT_BUSY
  HOST_STAT_DISABLED
  HOST_STAT_EXCLUSIVE
  HOST_STAT_FULL
  HOST_STAT_LOCKED
  HOST_STAT_NO_LIM
  HOST_STAT_OK
  HOST_STAT_UNAVAIL
  HOST_STAT_UNLICENSED
  HOST_STAT_UNREACH
  HOST_STAT_WIND
  HPART_HGRP
  H_ATTR_CHKPNTABLE
  H_ATTR_CHKPNT_COPY
  JGRP_ACTIVE
  JGRP_ARRAY_INFO
  JGRP_COUNT_NDONE
  JGRP_COUNT_NEXIT
  JGRP_COUNT_NJOBS
  JGRP_COUNT_NPSUSP
  JGRP_COUNT_NRUN
  JGRP_COUNT_NSSUSP
  JGRP_COUNT_NUSUSP
  JGRP_COUNT_PEND
  JGRP_DEL
  JGRP_HOLD
  JGRP_INACTIVE
  JGRP_INFO
  JGRP_NODE_ARRAY
  JGRP_NODE_GROUP
  JGRP_NODE_JOB
  JGRP_RECURSIVE
  JGRP_RELEASE
  JGRP_RELEASE_PARENTONLY
  JGRP_UNDEFINED
  JOBID_ONLY
  JOBID_ONLY_ALL
  JOB_STAT_DONE
  JOB_STAT_EXIT
  JOB_STAT_NULL
  JOB_STAT_PDONE
  JOB_STAT_PEND
  JOB_STAT_PERR
  JOB_STAT_PSUSP
  JOB_STAT_RUN
  JOB_STAT_SSUSP
  JOB_STAT_UNKWN
  JOB_STAT_USUSP
  JOB_STAT_WAIT
  LAST_JOB
  LOST_AND_FOUND
  LSBATCH_H
  LSBE_AFS_TOKENS
  LSBE_ARRAY_NULL
  LSBE_BAD_ARG
  LSBE_BAD_ATTA_DIR
  LSBE_BAD_CALENDAR
  LSBE_BAD_CHKLOG
  LSBE_BAD_CLUSTER
  LSBE_BAD_CMD
  LSBE_BAD_EVENT
  LSBE_BAD_EXT_MSGID
  LSBE_BAD_FRAME
  LSBE_BAD_GROUP
  LSBE_BAD_HOST
  LSBE_BAD_HOST_SPEC
  LSBE_BAD_HPART
  LSBE_BAD_IDX
  LSBE_BAD_JOB
  LSBE_BAD_JOBID
  LSBE_BAD_LIMIT
  LSBE_BAD_PROJECT_GROUP
  LSBE_BAD_QUEUE
  LSBE_BAD_RESOURCE
  LSBE_BAD_RESREQ
  LSBE_BAD_SIGNAL
  LSBE_BAD_SUBMISSION_HOST
  LSBE_BAD_TIME
  LSBE_BAD_TIMEEVENT
  LSBE_BAD_UGROUP
  LSBE_BAD_USER
  LSBE_BAD_USER_PRIORITY
  LSBE_BIG_IDX
  LSBE_CAL_CYC
  LSBE_CAL_DISABLED
  LSBE_CAL_EXIST
  LSBE_CAL_MODIFY
  LSBE_CAL_USED
  LSBE_CAL_VOID
  LSBE_CHKPNT_CALL
  LSBE_CHUNK_JOB
  LSBE_CONF_FATAL
  LSBE_CONF_WARNING
  LSBE_CONN_EXIST
  LSBE_CONN_NONEXIST
  LSBE_CONN_REFUSED
  LSBE_CONN_TIMEOUT
  LSBE_COPY_DATA
  LSBE_DEPEND_SYNTAX
  LSBE_DLOGD_ISCONN
  LSBE_EOF
  LSBE_ESUB_ABORT
  LSBE_EVENT_FORMAT
  LSBE_EXCEPT_ACTION
  LSBE_EXCEPT_COND
  LSBE_EXCEPT_SYNTAX
  LSBE_EXCLUSIVE
  LSBE_FRAME_BAD_IDX
  LSBE_FRAME_BIG_IDX
  LSBE_HJOB_LIMIT
  LSBE_HP_FAIRSHARE_DEF
  LSBE_INDEX_FORMAT
  LSBE_INTERACTIVE_CAL
  LSBE_INTERACTIVE_RERUN
  LSBE_JGRP_BAD
  LSBE_JGRP_CTRL_UNKWN
  LSBE_JGRP_EXIST
  LSBE_JGRP_HASJOB
  LSBE_JGRP_HOLD
  LSBE_JGRP_NULL
  LSBE_JOB_ARRAY
  LSBE_JOB_ATTA_LIMIT
  LSBE_JOB_CAL_MODIFY
  LSBE_JOB_DEP
  LSBE_JOB_ELEMENT
  LSBE_JOB_EXIST
  LSBE_JOB_FINISH
  LSBE_JOB_FORW
  LSBE_JOB_MODIFY
  LSBE_JOB_MODIFY_ONCE
  LSBE_JOB_MODIFY_USED
  LSBE_JOB_REQUEUED
  LSBE_JOB_REQUEUE_REMOTE
  LSBE_JOB_STARTED
  LSBE_JOB_SUSP
  LSBE_JS_DISABLED
  LSBE_J_UNCHKPNTABLE
  LSBE_J_UNREPETITIVE
  LSBE_LOCK_JOB
  LSBE_LSBLIB
  LSBE_LSLIB
  LSBE_MBATCHD
  LSBE_MC_CHKPNT
  LSBE_MC_EXCEPTION
  LSBE_MC_HOST
  LSBE_MC_REPETITIVE
  LSBE_MC_TIMEEVENT
  LSBE_MIGRATION
  LSBE_MOD_JOB_NAME
  LSBE_MSG_DELIVERED
  LSBE_MSG_RETRY
  LSBE_NOLSF_HOST
  LSBE_NOMATCH_CALENDAR
  LSBE_NOMATCH_EVENT
  LSBE_NOT_STARTED
  LSBE_NO_CALENDAR
  LSBE_NO_ENOUGH_HOST
  LSBE_NO_ENV
  LSBE_NO_ERROR
  LSBE_NO_EVENT
  LSBE_NO_FORK
  LSBE_NO_GROUP
  LSBE_NO_HOST
  LSBE_NO_HOST_GROUP
  LSBE_NO_HPART
  LSBE_NO_IFREG
  LSBE_NO_INTERACTIVE
  LSBE_NO_JOB
  LSBE_NO_JOBID
  LSBE_NO_JOBMSG
  LSBE_NO_JOB_PRIORITY
  LSBE_NO_LICENSE
  LSBE_NO_MEM
  LSBE_NO_OUTPUT
  LSBE_NO_RESOURCE
  LSBE_NO_USER
  LSBE_NO_USER_GROUP
  LSBE_NQS_BAD_PAR
  LSBE_NQS_NO_ARRJOB
  LSBE_NUM_ERR
  LSBE_ONLY_INTERACTIVE
  LSBE_OP_RETRY
  LSBE_OVER_LIMIT
  LSBE_OVER_RUSAGE
  LSBE_PEND_CAL_JOB
  LSBE_PERMISSION
  LSBE_PERMISSION_MC
  LSBE_PJOB_LIMIT
  LSBE_PORT
  LSBE_PREMATURE
  LSBE_PROC_NUM
  LSBE_PROTOCOL
  LSBE_PTY_INFILE
  LSBE_QJOB_LIMIT
  LSBE_QUEUE_CLOSED
  LSBE_QUEUE_HOST
  LSBE_QUEUE_NAME
  LSBE_QUEUE_USE
  LSBE_QUEUE_WINDOW
  LSBE_ROOT
  LSBE_RUN_CAL_JOB
  LSBE_SBATCHD
  LSBE_SBD_UNREACH
  LSBE_SERVICE
  LSBE_SP_CHILD_DIES
  LSBE_SP_CHILD_FAILED
  LSBE_SP_COPY_FAILED
  LSBE_SP_DELETE_FAILED
  LSBE_SP_FAILED_HOSTS_LIM
  LSBE_SP_FIND_HOST_FAILED
  LSBE_SP_FORK_FAILED
  LSBE_SP_SPOOLDIR_FAILED
  LSBE_SP_SRC_NOT_SEEN
  LSBE_START_TIME
  LSBE_STOP_JOB
  LSBE_SYNTAX_CALENDAR
  LSBE_SYSCAL_EXIST
  LSBE_SYS_CALL
  LSBE_TIME_OUT
  LSBE_UGROUP_MEMBER
  LSBE_UJOB_LIMIT
  LSBE_UNKNOWN_EVENT
  LSBE_UNSUPPORTED_MC
  LSBE_USER_JLIMIT
  LSBE_XDR
  LSB_CHKPERIOD_NOCHNG
  LSB_CHKPNT_COPY
  LSB_CHKPNT_FORCE
  LSB_CHKPNT_KILL
  LSB_CHKPNT_MIG
  LSB_CHKPNT_STOP
  LSB_EVENT_VERSION3_0
  LSB_EVENT_VERSION3_1
  LSB_EVENT_VERSION3_2
  LSB_EVENT_VERSION4_0
  LSB_KILL_REQUEUE
  LSB_MAX_ARRAY_IDX
  LSB_MAX_ARRAY_JOBID
  LSB_MAX_SD_LENGTH
  LSB_MODE_BATCH
  LSB_MODE_JS
  LSB_SIG_NUM
  LSF_JOBIDINDEX_FILENAME
  LSF_JOBIDINDEX_FILETAG
  MASTER_CONF
  MASTER_FATAL
  MASTER_MEM
  MASTER_NULL
  MASTER_RECONFIG
  MASTER_RESIGN
  MAXDESCLEN
  MAXPATHLEN
  MAX_CALENDARS
  MAX_CHARLEN
  MAX_CMD_DESC_LEN
  MAX_GROUPS
  MAX_HPART_USERS
  MAX_LSB_NAME_LEN
  MAX_USER_EQUIVALENT
  MAX_USER_MAPPING
  MAX_VERSION_LEN
  MBD_CKCONFIG
  MBD_RECONFIG
  MBD_RESTART
  MSGSIZE
  NO_PEND_REASONS
  NQSQ_GRP
  NQS_ROUTE
  NQS_SERVER
  NQS_SIG
  NUM_JGRP_COUNTERS
  PEND_ADMIN_STOP
  PEND_CHKPNT_DIR
  PEND_CHUNK_FAIL
  PEND_HAS_RUN
  PEND_HOST_ACCPT_ONE
  PEND_HOST_DISABLED
  PEND_HOST_EXCLUSIVE
  PEND_HOST_JOB_LIMIT
  PEND_HOST_JOB_RUSAGE
  PEND_HOST_JOB_SSUSP
  PEND_HOST_JS_DISABLED
  PEND_HOST_LESS_SLOTS
  PEND_HOST_LOAD
  PEND_HOST_LOCKED
  PEND_HOST_MISS_DEADLINE
  PEND_HOST_NONEXCLUSIVE
  PEND_HOST_NO_LIM
  PEND_HOST_NO_USER
  PEND_HOST_PART_PRIO
  PEND_HOST_PART_USER
  PEND_HOST_QUE_MEMB
  PEND_HOST_QUE_RESREQ
  PEND_HOST_QUE_RUSAGE
  PEND_HOST_RES_REQ
  PEND_HOST_SCHED_TYPE
  PEND_HOST_UNLICENSED
  PEND_HOST_USR_JLIMIT
  PEND_HOST_USR_SPEC
  PEND_HOST_WINDOW
  PEND_HOST_WIN_WILL_CLOSE
  PEND_JGRP_HOLD
  PEND_JGRP_INACT
  PEND_JGRP_RELEASE
  PEND_JGRP_WAIT
  PEND_JOB
  PEND_JOB_ARRAY_JLIMIT
  PEND_JOB_DELAY_SCHED
  PEND_JOB_DEPEND
  PEND_JOB_DEP_INVALID
  PEND_JOB_DEP_REJECT
  PEND_JOB_ENFUGRP
  PEND_JOB_ENV
  PEND_JOB_EXEC_INIT
  PEND_JOB_FORWARDED
  PEND_JOB_JS_DISABLED
  PEND_JOB_LOGON_FAIL
  PEND_JOB_MIG
  PEND_JOB_MODIFY
  PEND_JOB_NEW
  PEND_JOB_NO_FILE
  PEND_JOB_NO_PASSWD
  PEND_JOB_NO_SPAN
  PEND_JOB_OPEN_FILES
  PEND_JOB_PATHS
  PEND_JOB_PRE_EXEC
  PEND_JOB_QUE_REJECT
  PEND_JOB_RCLUS_UNREACH
  PEND_JOB_REASON
  PEND_JOB_REQUEUED
  PEND_JOB_RESTART_FILE
  PEND_JOB_RMT_ZOMBIE
  PEND_JOB_RSCHED_ALLOC
  PEND_JOB_RSCHED_START
  PEND_JOB_SPREAD_TASK
  PEND_JOB_START_FAIL
  PEND_JOB_START_TIME
  PEND_JOB_START_UNKNWN
  PEND_JOB_SWITCH
  PEND_JOB_TIME_INVALID
  PEND_LOAD_UNAVAIL
  PEND_NO_MAPPING
  PEND_NQS_FUN_OFF
  PEND_NQS_REASONS
  PEND_NQS_RETRY
  PEND_QUE_HOST_JLIMIT
  PEND_QUE_INACT
  PEND_QUE_JOB_LIMIT
  PEND_QUE_NO_SPAN
  PEND_QUE_PJOB_LIMIT
  PEND_QUE_PRE_FAIL
  PEND_QUE_PROC_JLIMIT
  PEND_QUE_SPREAD_TASK
  PEND_QUE_USR_JLIMIT
  PEND_QUE_USR_PJLIMIT
  PEND_QUE_WINDOW
  PEND_QUE_WINDOW_WILL_CLOSE
  PEND_RMT_PERMISSION
  PEND_SBD_GETPID
  PEND_SBD_JOB_ACCEPT
  PEND_SBD_JOB_QUOTA
  PEND_SBD_JOB_REQUEUE
  PEND_SBD_LOCK
  PEND_SBD_NO_MEM
  PEND_SBD_NO_PROCESS
  PEND_SBD_ROOT
  PEND_SBD_SOCKETPAIR
  PEND_SBD_UNREACH
  PEND_SBD_ZOMBIE
  PEND_SYS_NOT_READY
  PEND_SYS_UNABLE
  PEND_TIME_EXPIRED
  PEND_UGRP_JOB_LIMIT
  PEND_UGRP_PJOB_LIMIT
  PEND_UGRP_PROC_JLIMIT
  PEND_USER_JOB_LIMIT
  PEND_USER_PJOB_LIMIT
  PEND_USER_PROC_JLIMIT
  PEND_USER_RESUME
  PEND_USER_STOP
  PEND_WAIT_NEXT
  PREPARE_FOR_OP
  PRINT_LONG_NAMELIST
  PRINT_MCPU_HOSTS
  PRINT_SHORT_NAMELIST
  QUEUE_ACTIVATE
  QUEUE_CLOSED
  QUEUE_INACTIVATE
  QUEUE_OPEN
  QUEUE_STAT_ACTIVE
  QUEUE_STAT_DISC
  QUEUE_STAT_NOPERM
  QUEUE_STAT_OPEN
  QUEUE_STAT_RUN
  QUEUE_STAT_RUNWIN_CLOSE
  Q_ATTRIB_BACKFILL
  Q_ATTRIB_CHKPNT
  Q_ATTRIB_DEFAULT
  Q_ATTRIB_ENQUE_INTERACTIVE_AHEAD
  Q_ATTRIB_EXCLUSIVE
  Q_ATTRIB_EXCL_RMTJOB
  Q_ATTRIB_FAIRSHARE
  Q_ATTRIB_HOST_PREFER
  Q_ATTRIB_IGNORE_DEADLINE
  Q_ATTRIB_MC_FAST_SCHEDULE
  Q_ATTRIB_NONPREEMPTABLE
  Q_ATTRIB_NONPREEMPTIVE
  Q_ATTRIB_NO_HOST_TYPE
  Q_ATTRIB_NO_INTERACTIVE
  Q_ATTRIB_NQS
  Q_ATTRIB_ONLY_INTERACTIVE
  Q_ATTRIB_PREEMPTABLE
  Q_ATTRIB_PREEMPTIVE
  Q_ATTRIB_RECEIVE
  Q_ATTRIB_RERUNNABLE
  READY_FOR_OP
  RLIMIT_CORE
  RLIMIT_CPU
  RLIMIT_DATA
  RLIMIT_FSIZE
  RLIMIT_RSS
  RLIMIT_STACK
  RLIM_INFINITY
  RUNJOB_OPT_NORMAL
  RUNJOB_OPT_NOSTOP
  RUN_JOB
  SORT_HOST
  SUB2_BSUB_BLOCK
  SUB2_HOLD
  SUB2_HOST_NT
  SUB2_HOST_UX
  SUB2_IN_FILE_SPOOL
  SUB2_JOB_CMD_SPOOL
  SUB2_JOB_PRIORITY
  SUB2_MODIFY_CMD
  SUB2_QUEUE_CHKPNT
  SUB2_QUEUE_RERUNNABLE
  SUB_CHKPNTABLE
  SUB_CHKPNT_DIR
  SUB_CHKPNT_PERIOD
  SUB_DEPEND_COND
  SUB_ERR_FILE
  SUB_EXCEPT
  SUB_EXCLUSIVE
  SUB_HOST
  SUB_HOST_SPEC
  SUB_INTERACTIVE
  SUB_IN_FILE
  SUB_JOB_NAME
  SUB_LOGIN_SHELL
  SUB_MAIL_USER
  SUB_MODIFY
  SUB_MODIFY_ONCE
  SUB_NOTIFY_BEGIN
  SUB_NOTIFY_END
  SUB_OTHER_FILES
  SUB_OUT_FILE
  SUB_PRE_EXEC
  SUB_PROJECT_NAME
  SUB_PTY
  SUB_PTY_SHELL
  SUB_QUEUE
  SUB_REASON_CPULIMIT
  SUB_REASON_DEADLINE
  SUB_REASON_PROCESSLIMIT
  SUB_REASON_RUNLIMIT
  SUB_RERUNNABLE
  SUB_RESTART
  SUB_RESTART_FORCE
  SUB_RES_REQ
  SUB_TIME_EVENT
  SUB_USER_GROUP
  SUB_WINDOW_SIG
  SUSP_ADMIN_STOP
  SUSP_HOST_LOCK
  SUSP_JOB
  SUSP_LOAD_REASON
  SUSP_LOAD_UNAVAIL
  SUSP_MBD_LOCK
  SUSP_MBD_PREEMPT
  SUSP_PG_IT
  SUSP_QUEUE_REASON
  SUSP_QUEUE_WINDOW
  SUSP_QUE_RESUME_COND
  SUSP_QUE_STOP_COND
  SUSP_REASON_RESET
  SUSP_RESCHED_PREEMPT
  SUSP_RES_LIMIT
  SUSP_RES_RESERVE
  SUSP_SBD_PREEMPT
  SUSP_SBD_STARTUP
  SUSP_USER_REASON
  SUSP_USER_RESUME
  SUSP_USER_STOP
  THIS_VERSION
  TO_BOTTOM
  TO_TOP
  USER_GRP
  USER_JLP
  XF_OP_EXEC2SUB
  XF_OP_EXEC2SUB_APPEND
  XF_OP_SUB2EXEC
  XF_OP_SUB2EXEC_APPEND
  ZOMBIE_JOB
  _PATH_NULL

=head1 AUTHOR

Paul Franceus, Capita Technologies, Inc., paul@capita.com

=head1 SEE ALSO

LSF::Base


=cut
