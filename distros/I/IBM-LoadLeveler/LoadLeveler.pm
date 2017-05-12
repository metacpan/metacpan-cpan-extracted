# -*- Perl -*-
package IBM::LoadLeveler;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

#
# The Current errObj variable gets stuffed into here.  I want to stop returning
# errObj because:
# 1. All you can do is give it to ll_error
# 2. I Can't see why you'd want more than one.
# 3. I'm not sure you can get more than one.
#

our $errObj;

our @ISA = qw(Exporter DynaLoader);

require 'IBM/llapi.ph';

my @function_defs = qw ( ll_version
			 ll_query
			 ll_set_request
			 ll_reset_request
			 ll_get_objs
			 ll_get_data
			 ll_next_obj
			 ll_free_objs
			 ll_deallocate
			 ll_error
			 ll_get_jobs
			 ll_get_nodes
			 ll_make_reservation
			 ll_change_reservation
			 ll_bind
			 ll_remove_reservation
			 ll_remove_reservation_xtnd
			 llsubmit
			 ll_control
			 ll_modify
			 ll_preempt
			 ll_preempt_jobs
			 ll_run_scheduler
			 ll_start_job
			 ll_start_job_ext
			 ll_terminate_job
			 llctl
			 llfavorjob
			 llfavoruser
			 llhold
			 llprio
			 ll_cluster
			 ll_cluster_auth
			 ll_fair_share
             ll_config_changed
             ll_read_config
			 ll_move_job
			 ll_move_spool
		       );

# These definitions are genertaed by enum_sucker.pl

my @enums_3100 = qw (
		     API_OK
		     PREEMPT_STEP
		     RESUME_STEP
		     LL_STARTD
		     LL_SCHEDD
		     LL_CM
		     LL_MASTER
		     LL_STARTER
		     LL_HISTORY_FILE
		     JOBS
		     MACHINES
		     PERF
		     CLUSTERS
		     WLMSTAT
		     MATRIX
		     QUERY_ALL
		     QUERY_JOBID
		     QUERY_STEPID
		     QUERY_USER
		     QUERY_GROUP
		     QUERY_CLASS
		     QUERY_HOST
		     QUERY_PERF
		     QUERY_STARTDATE
		     QUERY_ENDDATE
		     ALL_DATA
		     STATUS_LINE
		     Q_LINE
		     SET_BATCH
		     SET_INTERACTIVE
		     BATCH_JOB
		     INTERACTIVE_JOB
		     SHARED
		     NOT_SHARED
		     SLICE_NOT_SHARED
		     LOW
		     AVERAGE
		     HIGH
		     ERROR_EVENT
		     STATUS_EVENT
		     TIMER_EVENT
		     NO_HOLD
		     HOLDTYPE_USER
		     HOLDTYPE_SYSTEM
		     HOLDTYPE_USERSYS
		     STATE_IDLE
		     STATE_PENDING
		     STATE_STARTING
		     STATE_RUNNING
		     STATE_COMPLETE_PENDING
		     STATE_REJECT_PENDING
		     STATE_REMOVE_PENDING
		     STATE_VACATE_PENDING
		     STATE_COMPLETED
		     STATE_REJECTED
		     STATE_REMOVED
		     STATE_VACATED
		     STATE_CANCELED
		     STATE_NOTRUN
		     STATE_TERMINATED
		     STATE_UNEXPANDED
		     STATE_SUBMISSION_ERR
		     STATE_HOLD
		     STATE_DEFERRED
		     STATE_NOTQUEUED
		     STATE_PREEMPTED
		     STATE_PREEMPT_PENDING
		     STATE_RESUME_PENDING
		     BATCH_SESSION
		     INTERACTIVE_SESSION
		     INTERACTIVE_HOSTLIST_SESSION
		     MARK_ALL_TASKS_RUNNING
		     LL_JobManagementInteractiveClass
		     LL_JobManagementListenSocket
		     LL_JobManagementAccountNo
		     LL_JobManagementSessionType
		     LL_JobManagementPrinterFILE
		     LL_JobManagementRestorePrinter
		     LL_JobGetFirstStep
		     LL_JobGetNextStep
		     LL_JobCredential
		     LL_JobName
		     LL_JobStepCount
		     LL_JobStepType
		     LL_JobSubmitHost
		     LL_JobSubmitTime
		     LL_JobVersionNum
		     LL_StepNodeCount
		     LL_StepGetFirstNode
		     LL_StepGetNextNode
		     LL_StepMachineCount
		     LL_StepGetFirstMachine
		     LL_StepGetNextMachine
		     LL_StepGetFirstSwitchTable
		     LL_StepGetNextSwitchTable
		     LL_StepGetMasterTask
		     LL_StepTaskInstanceCount
		     LL_StepAccountNumber
		     LL_StepAdapterUsage
		     LL_StepComment
		     LL_StepCompletionCode
		     LL_StepCompletionDate
		     LL_StepEnvironment
		     LL_StepErrorFile
		     LL_StepExecSize
		     LL_StepHostName
		     LL_StepID
		     LL_StepInputFile
		     LL_StepImageSize
		     LL_StepImmediate
		     LL_StepIwd
		     LL_StepJobClass
		     LL_StepMessages
		     LL_StepName
		     LL_StepNodeUsage
		     LL_StepOutputFile
		     LL_StepParallelMode
		     LL_StepPriority
		     LL_StepShell
		     LL_StepStartDate
		     LL_StepDispatchTime
		     LL_StepState
		     LL_StepStartCount
		     LL_StepCpuLimitHard
		     LL_StepCpuLimitSoft
		     LL_StepCpuStepLimitHard
		     LL_StepCpuStepLimitSoft
		     LL_StepCoreLimitHard
		     LL_StepCoreLimitSoft
		     LL_StepDataLimitHard
		     LL_StepDataLimitSoft
		     LL_StepFileLimitHard
		     LL_StepFileLimitSoft
		     LL_StepRssLimitHard
		     LL_StepRssLimitSoft
		     LL_StepStackLimitHard
		     LL_StepStackLimitSoft
		     LL_StepWallClockLimitHard
		     LL_StepWallClockLimitSoft
		     LL_StepHostList
		     LL_StepHoldType
		     LL_StepLoadLevelerGroup
		     LL_StepGetFirstAdapterReq
		     LL_StepGetNextAdapterReq
		     LL_StepRestart
		     LL_StepBlocking
		     LL_StepTaskGeometry
		     LL_StepTotalTasksRequested
		     LL_StepTasksPerNodeRequested
		     LL_StepTotalNodesRequested
		     LL_StepSystemPriority
		     LL_StepClassSystemPriority
		     LL_StepGroupSystemPriority
		     LL_StepUserSystemPriority
		     LL_StepQueueSystemPriority
		     LL_StepExecutionFactor
		     LL_StepImageSize64
		     LL_StepCpuLimitHard64
		     LL_StepCpuLimitSoft64
		     LL_StepCpuStepLimitHard64
		     LL_StepCpuStepLimitSoft64
		     LL_StepCoreLimitHard64
		     LL_StepCoreLimitSoft64
		     LL_StepDataLimitHard64
		     LL_StepDataLimitSoft64
		     LL_StepFileLimitHard64
		     LL_StepFileLimitSoft64
		     LL_StepRssLimitHard64
		     LL_StepRssLimitSoft64
		     LL_StepStackLimitHard64
		     LL_StepStackLimitSoft64
		     LL_StepWallClockLimitHard64
		     LL_StepWallClockLimitSoft64
		     LL_StepStepUserTime64
		     LL_StepStepSystemTime64
		     LL_StepStepMaxrss64
		     LL_StepStepIxrss64
		     LL_StepStepIdrss64
		     LL_StepStepIsrss64
		     LL_StepStepMinflt64
		     LL_StepStepMajflt64
		     LL_StepStepNswap64
		     LL_StepStepInblock64
		     LL_StepStepOublock64
		     LL_StepStepMsgsnd64
		     LL_StepStepMsgrcv64
		     LL_StepStepNsignals64
		     LL_StepStepNvcsw64
		     LL_StepStepNivcsw64
		     LL_StepStarterUserTime64
		     LL_StepStarterSystemTime64
		     LL_StepStarterMaxrss64
		     LL_StepStarterIxrss64
		     LL_StepStarterIdrss64
		     LL_StepStarterIsrss64
		     LL_StepStarterMinflt64
		     LL_StepStarterMajflt64
		     LL_StepStarterNswap64
		     LL_StepStarterInblock64
		     LL_StepStarterOublock64
		     LL_StepStarterMsgsnd64
		     LL_StepStarterMsgrcv64
		     LL_StepStarterNsignals64
		     LL_StepStarterNvcsw64
		     LL_StepStarterNivcsw64
		     LL_StepMachUsageCount
		     LL_StepGetFirstMachUsage
		     LL_StepGetNextMachUsage
		     LL_StepCheckpointable
		     LL_StepCheckpointing
		     LL_StepCkptAccumTime
		     LL_StepCkptFailStartTime
		     LL_StepCkptFile
		     LL_StepCkptGoodElapseTime
		     LL_StepCkptGoodStartTime
		     LL_StepCkptTimeHardLimit
		     LL_StepCkptTimeHardLimit64
		     LL_StepCkptTimeSoftLimit
		     LL_StepCkptTimeSoftLimit64
		     LL_StepCkptRestart
		     LL_StepCkptRestartSameNodes
		     LL_MachineAdapterList
		     LL_MachineArchitecture
		     LL_MachineAvailableClassList
		     LL_MachineCPUs
		     LL_MachineDisk
		     LL_MachineFeatureList
		     LL_MachineConfiguredClassList
		     LL_MachineKbddIdle
		     LL_MachineLoadAverage
		     LL_MachineMachineMode
		     LL_MachineMaxTasks
		     LL_MachineName
		     LL_MachineOperatingSystem
		     LL_MachinePoolList
		     LL_MachineRealMemory
		     LL_MachineScheddRunningJobs
		     LL_MachineScheddState
		     LL_MachineScheddTotalJobs
		     LL_MachineSpeed
		     LL_MachineStartdState
		     LL_MachineStartdRunningJobs
		     LL_MachineStepList
		     LL_MachineTimeStamp
		     LL_MachineVirtualMemory
		     LL_MachinePoolListSize
		     LL_MachineFreeRealMemory
		     LL_MachinePagesScanned
		     LL_MachinePagesFreed
		     LL_MachinePagesPagedIn
		     LL_MachinePagesPagedOut
		     LL_MachineGetFirstResource
		     LL_MachineGetNextResource
		     LL_MachineGetFirstAdapter
		     LL_MachineGetNextAdapter
		     LL_MachineDrainingClassList
		     LL_MachineDrainClassList
		     LL_MachineStartExpr
		     LL_MachineSuspendExpr
		     LL_MachineContinueExpr
		     LL_MachineVacateExpr
		     LL_MachineKillExpr
		     LL_MachineDisk64
		     LL_MachineRealMemory64
		     LL_MachineVirtualMemory64
		     LL_MachineFreeRealMemory64
		     LL_MachinePagesScanned64
		     LL_MachinePagesFreed64
		     LL_MachinePagesPagedIn64
		     LL_MachinePagesPagedOut64
		     LL_NodeTaskCount
		     LL_NodeGetFirstTask
		     LL_NodeGetNextTask
		     LL_NodeMaxInstances
		     LL_NodeMinInstances
		     LL_NodeRequirements
		     LL_NodeInitiatorCount
		     LL_SwitchTableJobKey
		     LL_TaskTaskInstanceCount
		     LL_TaskGetFirstTaskInstance
		     LL_TaskGetNextTaskInstance
		     LL_TaskExecutable
		     LL_TaskExecutableArguments
		     LL_TaskIsMaster
		     LL_TaskGetFirstResourceRequirement
		     LL_TaskGetNextResourceRequirement
		     LL_TaskInstanceAdapterCount
		     LL_TaskInstanceGetFirstAdapter
		     LL_TaskInstanceGetNextAdapter
		     LL_TaskInstanceGetFirstAdapterUsage
		     LL_TaskInstanceGetNextAdapterUsage
		     LL_TaskInstanceMachineName
		     LL_TaskInstanceTaskID
		     LL_AdapterInterfaceAddress
		     LL_AdapterMode
		     LL_AdapterName
		     LL_AdapterUsageWindow
		     LL_AdapterUsageProtocol
		     LL_AdapterUsageWindowMemory
		     LL_AdapterCommInterface
		     LL_AdapterUsageMode
		     LL_AdapterMinWindowSize
		     LL_AdapterMaxWindowSize
		     LL_AdapterMemory
		     LL_AdapterTotalWindowCount
		     LL_AdapterAvailWindowCount
		     LL_AdapterUsageAddress
		     LL_CredentialGid
		     LL_CredentialGroupName
		     LL_CredentialUid
		     LL_CredentialUserName
		     LL_StartdPerfJobsRunning
		     LL_StartdPerfJobsPending
		     LL_StartdPerfJobsSuspended
		     LL_StartdPerfCurrentJobs
		     LL_StartdPerfTotalJobsReceived
		     LL_StartdPerfTotalJobsCompleted
		     LL_StartdPerfTotalJobsRemoved
		     LL_StartdPerfTotalJobsVacated
		     LL_StartdPerfTotalJobsRejected
		     LL_StartdPerfTotalJobsSuspended
		     LL_StartdPerfTotalConnections
		     LL_StartdPerfFailedConnections
		     LL_StartdPerfTotalOutTransactions
		     LL_StartdPerfFailedOutTransactions
		     LL_StartdPerfTotalInTransactions
		     LL_StartdPerfFailedInTransactions
		     LL_ScheddPerfJobsIdle
		     LL_ScheddPerfJobsPending
		     LL_ScheddPerfJobsStarting
		     LL_ScheddPerfJobsRunning
		     LL_ScheddPerfCurrentJobs
		     LL_ScheddPerfTotalJobsSubmitted
		     LL_ScheddPerfTotalJobsCompleted
		     LL_ScheddPerfTotalJobsRemoved
		     LL_ScheddPerfTotalJobsVacated
		     LL_ScheddPerfTotalJobsRejected
		     LL_ScheddPerfTotalConnections
		     LL_ScheddPerfFailedConnections
		     LL_ScheddPerfTotalOutTransactions
		     LL_ScheddPerfFailedOutTransactions
		     LL_ScheddPerfTotalInTransactions
		     LL_ScheddPerfFailedInTransactions
		     LL_VersionCheck
		     LL_AdapterReqCommLevel
		     LL_AdapterReqUsage
		     LL_ClusterGetFirstResource
		     LL_ClusterGetNextResource
		     LL_ClusterSchedulingResources
		     LL_ClusterDefinedResources
		     LL_ClusterSchedulingResourceCount
		     LL_ClusterDefinedResourceCount
		     LL_ClusterEnforcedResources
		     LL_ClusterEnforcedResourceCount
		     LL_ClusterEnforceSubmission
		     LL_ClusterSchedulerType
		     LL_ResourceName
		     LL_ResourceInitialValue
		     LL_ResourceAvailableValue
		     LL_ResourceInitialValue64
		     LL_ResourceAvailableValue64
		     LL_ResourceRequirementName
		     LL_ResourceRequirementValue
		     LL_ResourceRequirementValue64
		     LL_WlmStatCpuTotalUsage
		     LL_WlmStatCpuSnapshotUsage
		     LL_WlmStatMemoryHighWater
		     LL_WlmStatMemorySnapshotUsage
		     LL_MatrixTimeSlice
		     LL_MatrixColumnCount
		     LL_MatrixRowCount
		     LL_MatrixGetFirstColumn
		     LL_MatrixGetNextColumn
		     LL_ColumnMachineName
		     LL_ColumnProcessorNumber
		     LL_ColumnRowCount
		     LL_ColumnStepNames
		     LL_MachUsageMachineName
		     LL_MachUsageMachineSpeed
		     LL_MachUsageDispUsageCount
		     LL_MachUsageGetFirstDispUsage
		     LL_MachUsageGetNextDispUsage
		     LL_DispUsageEventUsageCount
		     LL_DispUsageGetFirstEventUsage
		     LL_DispUsageGetNextEventUsage
		     LL_DispUsageStepUserTime64
		     LL_DispUsageStepSystemTime64
		     LL_DispUsageStepMaxrss64
		     LL_DispUsageStepIxrss64
		     LL_DispUsageStepIdrss64
		     LL_DispUsageStepIsrss64
		     LL_DispUsageStepMinflt64
		     LL_DispUsageStepMajflt64
		     LL_DispUsageStepNswap64
		     LL_DispUsageStepInblock64
		     LL_DispUsageStepOublock64
		     LL_DispUsageStepMsgsnd64
		     LL_DispUsageStepMsgrcv64
		     LL_DispUsageStepNsignals64
		     LL_DispUsageStepNvcsw64
		     LL_DispUsageStepNivcsw64
		     LL_DispUsageStarterUserTime64
		     LL_DispUsageStarterSystemTime64
		     LL_DispUsageStarterMaxrss64
		     LL_DispUsageStarterIxrss64
		     LL_DispUsageStarterIdrss64
		     LL_DispUsageStarterIsrss64
		     LL_DispUsageStarterMinflt64
		     LL_DispUsageStarterMajflt64
		     LL_DispUsageStarterNswap64
		     LL_DispUsageStarterInblock64
		     LL_DispUsageStarterOublock64
		     LL_DispUsageStarterMsgsnd64
		     LL_DispUsageStarterMsgrcv64
		     LL_DispUsageStarterNsignals64
		     LL_DispUsageStarterNvcsw64
		     LL_DispUsageStarterNivcsw64
		     LL_EventUsageEventID
		     LL_EventUsageEventName
		     LL_EventUsageEventTimestamp
		     LL_EventUsageStepUserTime64
		     LL_EventUsageStepSystemTime64
		     LL_EventUsageStepMaxrss64
		     LL_EventUsageStepIxrss64
		     LL_EventUsageStepIdrss64
		     LL_EventUsageStepIsrss64
		     LL_EventUsageStepMinflt64
		     LL_EventUsageStepMajflt64
		     LL_EventUsageStepNswap64
		     LL_EventUsageStepInblock64
		     LL_EventUsageStepOublock64
		     LL_EventUsageStepMsgsnd64
		     LL_EventUsageStepMsgrcv64
		     LL_EventUsageStepNsignals64
		     LL_EventUsageStepNvcsw64
		     LL_EventUsageStepNivcsw64
		     LL_EventUsageStarterUserTime64
		     LL_EventUsageStarterSystemTime64
		     LL_EventUsageStarterMaxrss64
		     LL_EventUsageStarterIxrss64
		     LL_EventUsageStarterIdrss64
		     LL_EventUsageStarterIsrss64
		     LL_EventUsageStarterMinflt64
		     LL_EventUsageStarterMajflt64
		     LL_EventUsageStarterNswap64
		     LL_EventUsageStarterInblock64
		     LL_EventUsageStarterOublock64
		     LL_EventUsageStarterMsgsnd64
		     LL_EventUsageStarterMsgrcv64
		     LL_EventUsageStarterNsignals64
		     LL_EventUsageStarterNvcsw64
		     LL_EventUsageStarterNivcsw64
		     NUMERIC
		     RESOURCE
		     AVGTHROUGHPUT
		     MAXTHROUGHPUT
		     MINTHROUGHPUT
		     THROUGHPUT
		     REPORT_ALL
		     REPORT_DEFAULT
		     USER
		     SECTION_GROUP
		     CLASS
		     ACCOUNT
		     UNIXGROUP
		     DAY
		     WEEK
		     MONTH
		     JOBID
		     JOBNAME
		     ALLOCATED
		     SECTION_ALL
		     SECTION_DEFAULT
		     TIME_MASK
		     EXTENDED_FORMAT
		     SUMMARY_FORMAT
		     QUERY_FORMAT
		     GUI_FORMAT
		     LL_CONTROL_RECYCLE
		     LL_CONTROL_RECONFIG
		     LL_CONTROL_START
		     LL_CONTROL_STOP
		     LL_CONTROL_DRAIN
		     LL_CONTROL_DRAIN_STARTD
		     LL_CONTROL_DRAIN_SCHEDD
		     LL_CONTROL_PURGE_SCHEDD
		     LL_CONTROL_FLUSH
		     LL_CONTROL_SUSPEND
		     LL_CONTROL_RESUME
		     LL_CONTROL_RESUME_STARTD
		     LL_CONTROL_RESUME_SCHEDD
		     LL_CONTROL_FAVOR_JOB
		     LL_CONTROL_UNFAVOR_JOB
		     LL_CONTROL_FAVOR_USER
		     LL_CONTROL_UNFAVOR_USER
		     LL_CONTROL_HOLD_USER
		     LL_CONTROL_HOLD_SYSTEM
		     LL_CONTROL_HOLD_RELEASE
		     LL_CONTROL_PRIO_ABS
		     LL_CONTROL_PRIO_ADJ
		     JM_DEDICATED
		     JM_SHARED
		     JM_ETHERNET
		     JM_FDDI
		     JM_HPS_US
		     JM_HPS_IP
		     JM_FCS
		     JM_TOKENRING
		     JM_SUCCESS
		     JM_NOTATTEMPTED
		     JM_INVALIDPOOL
		     JM_INVALIDSUBPOOL
		     JM_INVALIDNODENAME
		     JM_EXCEEDEDCAPACITY
		     JM_DOWNONENET
		     JM_DOWNONSWITCH
		     JM_INVALIDUSER
		     JM_INVALIDADAPTER
		     JM_PARTITIONCREATIONFAILURE
		     JM_SWITCHFAULT
		     JM_SYSTEMERROR
		     JM_DEFAULTS
		     JM_EXPLICITMAP
		     JM_ALLOCATEASMANY
		     CKPT_YES
		     CKPT_NO
		     CKPT_FAIL
		     EXECUTION_FACTOR
		     CONSUMABLE_CPUS
		     CONSUMABLE_MEMORY
		    );
my @enums_3104 = qw (
		     LL_StepWallClockUsed
		    );
my @enums_3105 = qw (
		     LL_StepLargePage
		     LL_MachineLargePageSize64
		     LL_MachineLargePageCount64
		     LL_MachineLargePageFree64
		    );
my @enums_31011 = qw (
		      QUERY_PROCID
		     );
my @enums_31013 = qw (
		      SYSTEM_PREEMPT_STEP
		     );
my @enums_31016 = qw (
		      LL_CONTROL_START_DRAINED
		     );
my @enums_31026 = qw (
		      LL_StepReserved01
		      LL_StepReserved02
		      LL_StepReserved03
		      LL_StepStartTime
		     );
my @enums_31031 = qw (
		      LL_StepReserved04
		      LL_StepReserved05
		      LL_StepReserved06
		      LL_StepReserved07
		      LL_StepReserved08
		      LL_StepReserved09
		      LL_StepReserved10
		      LL_StepReserved11
		      LL_StepDependency
		      LL_MachineReserved01
		      LL_MachineReserved02
		      LL_MachineReserved03
		      LL_MachineReserved04
		      LL_MachineReserved05
		      LL_MachineReserved06
		      LL_MachineReserved07
		      LL_MachineConfigTimeStamp
		     );
my @enums_3200 = qw (
		     CLASSES
		     LL_StepMaxProtocolInstances
		     LL_TaskInstanceMachineAddress
		     LL_AdapterUsageCommunicationInterface
		     LL_AdapterUsageDevice
		     LL_AdapterUsageInstanceNumber
		     LL_AdapterWindowList
		     LL_AdapterUsageWindowMemory64
		     LL_AdapterMinWindowSize64
		     LL_AdapterMaxWindowSize64
		     LL_AdapterMemory64
		     LL_ClassName
		     LL_ClassPriority
		     LL_ClassExcludeUsers
		     LL_ClassIncludeUsers
		     LL_ClassExcludeGroups
		     LL_ClassIncludeGroups
		     LL_ClassAdmin
		     LL_ClassNqsClass
		     LL_ClassNqsSubmit
		     LL_ClassNqsQuery
		     LL_ClassMaxProcessors
		     LL_ClassMaxJobs
		     LL_ClassGetFirstResourceRequirement
		     LL_ClassGetNextResourceRequirement
		     LL_ClassComment
		     LL_ClassCkptDir
		     LL_ClassCkptTimeHardLimit
		     LL_ClassCkptTimeSoftLimit
		     LL_ClassWallClockLimitHard
		     LL_ClassWallClockLimitSoft
		     LL_ClassCpuStepLimitHard
		     LL_ClassCpuStepLimitSoft
		     LL_ClassCpuLimitHard
		     LL_ClassCpuLimitSoft
		     LL_ClassDataLimitHard
		     LL_ClassDataLimitSoft
		     LL_ClassCoreLimitHard
		     LL_ClassCoreLimitSoft
		     LL_ClassFileLimitHard
		     LL_ClassFileLimitSoft
		     LL_ClassStackLimitHard
		     LL_ClassStackLimitSoft
		     LL_ClassRssLimitHard
		     LL_ClassRssLimitSoft
		     LL_ClassNice
		     LL_ClassFreeSlots
		     LL_ClassMaximumSlots
		     LL_ClassConstraints
		     LL_ClassExecutionFactor
		     LL_ClassMaxTotalTasks
		     LL_ClassPreemptClass
		     LL_ClassStartClass
		     LL_ClassMaxProtocolInstances
		     WCLIMIT_ADD_MIN
		     JOB_CLASS
		     ACCOUNT_NO
		    );
my @enums_3205 = qw (
		     LL_AdapterUsageNetworkId
		    );
my @enums_3206 = qw (
		     LL_StepBulkXfer
		     LL_StepTotalRcxtBlocks
		     LL_AdapterUsageTag
		    );
my @enums_3209 = qw (
		     LL_StepUserRcxtBlocks
		    );
my @enums_32017 = qw (
		      LL_AdapterReqInstances
		      LL_AdapterReqReserved01
		      LL_AdapterReqProtocol
		      LL_AdapterReqMode
		      LL_AdapterReqTypeName
		     );
my @enums_3300 = qw (
		     RESERVATIONS
		     MCLUSTERS
		     QUERY_RESERVATION_ID
		     RESERVATION_OK
		     QUERY_LOCAL
		     LL_JobSchedd
		     LL_JobJobQueueKey
		     LL_JobIsRemote
		     LL_JobSchedulingCluster
		     LL_JobSubmittingCluster
		     LL_JobSubmittingUser
		     LL_JobSendingCluster
		     LL_JobRequestedCluster
		     LL_JobLocalOutboundSchedds
		     LL_JobScheddHistory
		     LL_JobGetFirstClusterInputFile
		     LL_JobGetNextClusterInputFile
		     LL_JobGetFirstClusterOutputFile
		     LL_JobGetNextClusterOutputFile
		     LL_StepRequestedReservationID
		     LL_StepReservationID
		     LL_StepPreemptable
		     LL_StepPreemptWaitList
		     LL_StepRsetName
		     LL_StepCkptExecuteDirectory
		     LL_StepAcctKey
		     LL_MachineReservationPermitted
		     LL_MachineReservationList
		     LL_MachinePrestartedStarters
		     LL_MachineCPUList
		     LL_MachineGetFirstMCM
		     LL_MachineGetNextMCM
		     LL_MachineCpuList
		     LL_TaskInstanceMachine
		     LL_TaskInstanceCpuList
		     LL_AdapterMCMId
		     LL_ClusterSchedulerType
		     LL_ClusterPreemptionEnabled
		     LL_ClusterSysPrioThreshold
		     LL_ClusterMusterEnvironment
		     LL_ClusterClusterMetric
		     LL_ClusterClusterUserMapper
		     LL_ClusterClusterRemoteJobFilter
		     LL_ReservationID
		     LL_ReservationStartTime
		     LL_ReservationDuration
		     LL_ReservationMachines
		     LL_ReservationJobs
		     LL_ReservationModeShared
		     LL_ReservationModeRemoveOnIdle
		     LL_ReservationStatus
		     LL_ReservationOwner
		     LL_ReservationGroup
		     LL_ReservationCreateTime
		     LL_ReservationModifiedBy
		     LL_ReservationModifyTime
		     LL_ReservationUsers
		     LL_ReservationGroups
		     LL_MClusterName
		     LL_MClusterInboundScheddPort
		     LL_MClusterLocal
		     LL_MClusterInboundHosts
		     LL_MClusterOutboundHosts
		     LL_MClusterIncludeUsers
		     LL_MClusterExcludeUsers
		     LL_MClusterIncludeGroups
		     LL_MClusterExcludeGroups
		     LL_MClusterIncludeClasses
		     LL_MClusterExcludeClasses
		     LL_MClusterSecureScheddPort
		     LL_MClusterMulticlusterSecurity
		     LL_MClusterSslCipherList
		     LL_ClusterFileLocalPath
		     LL_ClusterFileRemotePath
		     LL_MCMID
		     LL_MCMCPUList
		     LL_LastGetDataSpecification
		     STEP_PREEMPTABLE
		     SYSPRIO
		     JOBMGMT_IO_COMPLETE
		     JOBMGMT_IO_PENDING
		     JOBMGMT_BAD_JOBMGMT_OBJECT
		     JOBMGMT_FAILED_CONNECT
		     JOBMGMT_SYSTEM
		     JOBMGMT_NULL_EXECUTABLE
		     JOBMGMT_TASKMGR_RUNNING
		     JOBMGMT_INCOMPATABLE_NODES
		     JOBMGMT_BAD_MACHINE_OBJECT
		     JOBMGMT_BAD_STEP_OBJECT
		     JOBMGMT_BAD_SEQUENCE
		     JOBMGMT_BAD_FD
		     RESERVATION_START_TIME
		     RESERVATION_ADD_START_TIME
		     RESERVATION_DURATION
		     RESERVATION_ADD_DURATION
		     RESERVATION_BY_NODE
		     RESERVATION_ADD_NUM_NODE
		     RESERVATION_BY_HOSTLIST
		     RESERVATION_ADD_HOSTS
		     RESERVATION_DEL_HOSTS
		     RESERVATION_BY_JOBSTEP
		     RESERVATION_BY_JCF
		     RESERVATION_USERLIST
		     RESERVATION_ADD_USERS
		     RESERVATION_DEL_USERS
		     RESERVATION_GROUPLIST
		     RESERVATION_ADD_GROUPS
		     RESERVATION_DEL_GROUPS
		     RESERVATION_MODE_SHARED
		     RESERVATION_MODE_REMOVE_ON_IDLE
		     RESERVATION_OWNER
		     RESERVATION_GROUP
		 	 RESERVATION_WAITING	
			 RESERVATION_SETUP
			 RESERVATION_ACTIVE
			 RESERVATION_ACTIVE_SHARED
			 RESERVATION_CANCEL
			 RESERVATION_COMPLETE
			 RESERVATION_DEFAULT_MODE
			 RESERVATION_SHARED
			 RESERVATION_REMOVE_ON_IDLE
			 RESERVATION_BIND_FIRM
			 RESERVATION_BIND_SOFT
		    );
my @enums_3301 = qw (
		     LL_ClusterEnforceMemory
		    );
my @enums_3310 = qw (
		     BLUE_GENE
		     QUERY_BG_JOB
		     QUERY_BG_BASE_PARTITION
		     QUERY_BG_PARTITION
		     COMMLVL_UNSPECIFIED
		     LL_JobUsersJCF
		     LL_StepFavoredJob
		     LL_StepBgJobId
		     LL_StepBgState
		     LL_StepBgSizeRequested
		     LL_StepBgSizeAllocated
		     LL_StepBgShapeRequested
		     LL_StepBgShapeAllocated
		     LL_StepBgConnectionRequested
		     LL_StepBgConnectionAllocated
		     LL_StepBgPartitionRequested
		     LL_StepBgPartitionAllocated
		     LL_StepBgPartitionState
		     LL_StepBgErrorText
		     LL_MachineUsedCPUs
		     LL_MachineUsedCPUList
		     LL_AdapterUsageRcxtBlocks
		     LL_AdapterRcxtBlocks
		     LL_AdapterReqRcxtBlks
		     LL_MCMCPUs
		     LL_BgMachineBPSize
		     LL_BgMachineSize
		     LL_BgMachineSwitchCount
		     LL_BgMachineWireCount
		     LL_BgMachinePartitionCount
		     LL_BgMachineGetFirstBP
		     LL_BgMachineGetNextBP
		     LL_BgMachineGetFirstSwitch
		     LL_BgMachineGetNextSwitch
		     LL_BgMachineGetFirstWire
		     LL_BgMachineGetNextWire
		     LL_BgMachineGetFirstPartition
		     LL_BgMachineGetNextPartition
		     LL_BgBPId
		     LL_BgBPState
		     LL_BgBPLocation
		     LL_BgBPSubDividedBusy
		     LL_BgBPCurrentPartition
		     LL_BgBPCurrentPartitionState
		     LL_BgBPNodeCardCount
		     LL_BgBPGetFirstNodeCard
		     LL_BgBPGetNextNodeCard
		     LL_BgSwitchId
		     LL_BgSwitchBasePartitionId
		     LL_BgSwitchState
		     LL_BgSwitchDimension
		     LL_BgSwitchConnCount
		     LL_BgSwitchGetFirstConn
		     LL_BgSwitchGetNextConn
		     LL_BgPortConnToSwitchPort
		     LL_BgPortConnFromSwitchPort
		     LL_BgPortConnCurrentPartition
		     LL_BgPortConnCurrentPartitionState
		     LL_BgWireId
		     LL_BgWireState
		     LL_BgWireFromPortCompId
		     LL_BgWireFromPortId
		     LL_BgWireToPortCompId
		     LL_BgWireToPortId
		     LL_BgWireCurrentPartition
		     LL_BgWireCurrentPartitionState
		     LL_BgPartitionId
		     LL_BgPartitionState
		     LL_BgPartitionBPCount
		     LL_BgPartitionSwitchCount
		     LL_BgPartitionBPList
		     LL_BgPartitionGetFirstSwitch
		     LL_BgPartitionGetNextSwitch
		     LL_BgPartitionNodeCardList
		     LL_BgPartitionConnection
		     LL_BgPartitionOwner
		     LL_BgPartitionMode
		     LL_BgPartitionSmall
		     LL_BgPartitionMLoaderImage
		     LL_BgPartitionBLRTSImage
		     LL_BgPartitionLinuxImage
		     LL_BgPartitionRamDiskImage
		     LL_BgPartitionDescription
		     LL_BgNodeCardId
		     LL_BgNodeCardState
		     LL_BgNodeCardQuarter
		     LL_BgNodeCardCurrentPartition
		     LL_BgNodeCardCurrentPartitionState
		     BG_SIZE
		     BG_SHAPE
		     BG_CONNECTION
		     BG_PARTITION
		     BG_ROTATE
		     MAX_MODIFY_OP
		     BG_BP_UP
		     BG_BP_DOWN
		     BG_BP_MISSING
		     BG_BP_ERROR
		     BG_BP_NAV
		     BG_PARTITION_FREE
		     BG_PARTITION_CONFIGURING
		     BG_PARTITION_READY
		     BG_PARTITION_BUSY
		     BG_PARTITION_DEALLOCATING
		     BG_PARTITION_ERROR
		     BG_PARTITION_NAV
		     MESH
		     TORUS
		     BG_NAV
		     PREFER_TORUS
		     COPROCESSOR
		     VIRTUAL_NODE
		     BG_PORT_PLUS_X
		     BG_PORT_MINUS_X
		     BG_PORT_PLUS_Y
		     BG_PORT_MINUS_Y
		     BG_PORT_PLUS_Z
		     BG_PORT_MINUS_Z
		     BG_PORT_S0
		     BG_PORT_S1
		     BG_PORT_S2
		     BG_PORT_S3
		     BG_PORT_S4
		     BG_PORT_S5
		     BG_PORT_NAV
		     BG_SWITCH_UP
		     BG_SWITCH_DOWN
		     BG_SWITCH_MISSING
		     BG_SWITCH_ERROR
		     BG_SWITCH_NAV
		     BG_DIM_X
		     BG_DIM_Y
		     BG_DIM_Z
		     BG_DIM_NAV
		     BG_WIRE_UP
		     BG_WIRE_DOWN
		     BG_WIRE_MISSING
		     BG_WIRE_ERROR
		     BG_WIRE_NAV
		     BG_NODE_CARD_UP
		     BG_NODE_CARD_DOWN
		     BG_NODE_CARD_MISSING
		     BG_NODE_CARD_ERROR
		     BG_NODE_CARD_NAV
		     BG_QUARTER_Q1
		     BG_QUARTER_Q2
		     BG_QUARTER_Q3
		     BG_QUARTER_Q4
		     BG_QUARTER_Q_NAV
		     BG_JOB_IDLE
		     BG_JOB_STARTING
		     BG_JOB_RUNNING
		     BG_JOB_TERMINATED
		     BG_JOB_KILLED
		     BG_JOB_ERROR
		     BG_JOB_DYING
		     BG_JOB_DEBUG
		     BG_JOB_LOAD
		     BG_JOB_LOADED
		     BG_JOB_BEGIN
		     BG_JOB_ATTACH
		     BG_JOB_NAV
		    );
my @enums_3311 = qw (
		     LL_StepBgJobState
		     LL_StepMcmAffinityOptions
		     LL_AdapterUsageExclusive
);

my @enums_3401 = qw (
                     UNUSED_MATRIX
                     FAIRSHARE
                     SERIAL_TYPE
                     PARALLEL_TYPE
                     BLUE_GENE_TYPE
                     MPICH_TYPE
                     LL_StepCoschedule
                     LL_StepSMTRequired
                     LL_StepMetaClusterJobID
		     LL_StepMetaClusterJob
		     LL_StepMasterVirtualIP
		     LL_StepMasterRealIP
		     LL_StepMasterNetmask
		     LL_StepVipNetmask
		     LL_StepMetaClusterPoeHostname
		     LL_StepMetaClusterPoePmdPhysnet
		     LL_StepCkptSubDir
		     LL_TaskInstanceMachineVirtualIP
		     LL_AdapterUsagePortNumber
		     LL_AdapterUsageLmc
		     LL_AdapterPortNumber
		     LL_AdapterLmc
		     LL_AdapterUsageNetworkId64
		     LL_AdapterUsageDeviceDriver
		     LL_AdapterUsageDeviceType
		     LL_AdapterInterfaceNetmask
		     LL_AdapterUsageVirtualIP
		     LL_AdapterUsageNetmask
		     LL_ClassGetFirstUser
		     LL_ClassGetNextUser
		     LL_ClassDefWallClockLimitHard
		     LL_ClassDefWallClockLimitSoft
		     LL_ReservationBgCNodes
		     LL_ReservationBgConnection
		     LL_ReservationBgShape
		     LL_ReservationBgBPs
		     LL_BgBPCnodeMemory
		     LL_BgPartitionSize
		     LL_BgPartitionShape
		     LL_FairShareCurrentTime
		     LL_FairShareTotalShares
		     LL_FairShareInterval
		     LL_FairShareNumberOfEntries
		     LL_FairShareEntryNames
		     LL_FairShareEntryTypes
		     LL_FairShareAllocatedShares
		     LL_FairShareUsedShares
		     LL_FairShareUsedBgShares
		     LL_ClassUserName
		     LL_ClassUserMaxIdle
		     LL_ClassUserMaxQueued
		     LL_ClassUserMaxJobs
		     LL_ClassUserMaxTotalTasks
		     BG_REQUIREMENTS
		     LL_MOVE_SPOOL_JOBS
		     RESERVATION_BY_BG_CNODE
		     BG_BP_COMPUTENODE_MEMORY_256M
		     BG_BP_COMPUTENODE_MEMORY_512M
		     BG_BP_COMPUTENODE_MEMORY_1G
		     BG_BP_COMPUTENODE_MEMORY_2G
		     BG_BP_COMPUTENODE_MEMORY_4G
		     BG_BP_COMPUTENODE_MEMORY_NAV
		     FAIR_SHARE_RESET
		     FAIR_SHARE_SAVE
		    );
my @enums_3404 = qw (
		     SMT_OFF
		     SMT_ON
		     SMT_AS_IS
		    );
my @enums_3411 = qw (
		     LL_StepAsLimitHard64
		     LL_StepAsLimitSoft64
		     LL_StepNprocLimitHard64
		     LL_StepNprocLimitSoft64
		     LL_StepMemlockLimitHard64
		     LL_StepMemlockLimitSoft64
		     LL_StepLocksLimitHard64
		     LL_StepLocksLimitSoft64
		     LL_StepNofileLimitHard64
		     LL_StepNofileLimitSoft64
		     LL_NodeGetFirstResourceRequirement
		     LL_NodeGetNextResourceRequirement
		     LL_ClassGetFirstNodeResourceRequirement
		     LL_ClassGetNextNodeResourceRequirement
		     LL_ClassAsLimitHard
		     LL_ClassAsLimitSoft
		     LL_ClassNprocLimitHard
		     LL_ClassNprocLimitSoft
		     LL_ClassMemlockLimitHard
		     LL_ClassMemlockLimitSoft
		     LL_ClassLocksLimitHard
		     LL_ClassLocksLimitSoft
		     LL_ClassNofileLimitHard
		     LL_ClassNofileLimitSoft
		     LL_ReservationBgPartition
		     LL_CONTROL_DUMP_LOGS
		     RESOURCES
		     NODE_RESOURCES
		     RESERVATION_BY_HOSTFILE
		    );

my @enums_3421 = qw (
		     QUERY_TOP_DOG
		     QUEUE_SYS_PREEMPTED
		     QUEUE_GLOBAL_WAIT
		     LL_StepTaskAffinity
		     LL_StepCpusPerCore
		     LL_StepIsTopDog
		     LL_StepConsideredAt
		     LL_StepEstimatedStartTime
		     LL_StepUserHoldTime
		     LL_StepQueueId
		     LL_StepQueueIndex
		     LL_ClassExcludeBg
		     LL_ClassIncludeBg
		     LL_BgBPIONodeCount
		     LL_BgPartitionUserList
		     LL_BgPartitionIONodeCount
		     LL_BgPartitionCnLoadImage
		     LL_BgPartitionIoLoadImage
		     LL_BgPartitionIONodeList
		     LL_BgNodeCardSubDividedBusy
		     LL_BgNodeCardIONodeCount
		     LL_BgNodeCardGetFirstIONode
		     LL_BgNodeCardGetNextIONode
		     LL_BgIONodeId
		     LL_BgIONodeIPAddr
		     LL_BgIONodeCurrentPartition
		     LL_BgIONodeCurrentPartitionState
		    );

my @enums_3500 = qw (
			LL_StepClusterOption
			LL_StepScaleAcrossClusterCount
			LL_StepGetFirstScaleAcrossCluster
			LL_StepGetNextScaleAcrossCluster
			LL_StepBgPartitionType
			LL_MachineRSetSupport
			LL_MachineSMTState
			LL_ClusterScaleAcrossEnv
			LL_WlmStatVMemoryHighWater
			LL_WlmStatVMemorySnapshotUsage
			LL_WlmStatLargePageMemorySnapshotUsage
			LL_ClassAllowScaleAcrossJobs
			LL_ClassGetFirstMaxResourceRequirement
			LL_ClassGetNextMaxResourceRequirement
			LL_ClassGetFirstMaxNodeResourceRequirement
			LL_ClassGetNextMaxNodeResourceRequirement
			LL_ClassStripingWithMinimumNetworks
			LL_ClassMaxNode
			LL_ReservationExpiration
			LL_ReservationCanceledOccurrences
			LL_ReservationCanceledOccurrencesCount
			LL_ReservationRecurringString
			LL_ReservationRecurrenceStructure
			LL_ReservationBindingMethod
			LL_ReservationGetNextOccurrence
			LL_ReservationOccurrenceID
			LL_StepReservationBindingMethod
			LL_StepReservationFirstOidStepBoundTo
			LL_MClusterAllowScaleAcrossJobs
			LL_MClusterMainScaleAcrossCluster
			LL_BgPartitionType
			CLUSTER_OPTION
			DSTG_RESOURCES
			BG_PARTITION_TYPE
			BG_USER_LIST
			JOBMGMT_JOB_PREEMPTED
			RESERVATION_BIND_FIRM
			RESERVATION_BIND_SOFT
			RESERVATION_BINDING_METHOD
			RESERVATION_EXPIRATION
			RESERVATION_RECURRENCE
			RESERVATION_OCCURRENCE
			BG_BP_SOME_DOWN
			HPC
			HTC_SMP
			HTC_DUAL
			HTC_VN
			HTC_LINUX_SMP
			PTYPE_NAV
			MCM_AFFINITY
			USER_DEFINED_RSET
			NO_AFFINITY
			SMT_DISABLED
			SMT_ENABLED
			SMT_NOT_SUPPORT
			);
			
my @enums_3512 = qw (
			LL_ReservationRecurrenceString
			LL_ReservationJobOids
		    );			

our @EXPORT = (
	       @function_defs,
	       @enums_3100,
	       @enums_3104,
	       @enums_3105,
	       @enums_31011,
	       @enums_31013,
	       @enums_31016,
	       @enums_31026,
	       @enums_31031,
	       @enums_3200,
	       @enums_3205,
	       @enums_3206,
	       @enums_3209,
	       @enums_32017,
	       @enums_3300,
	       @enums_3301,
	       @enums_3310,
	       @enums_3311,
           @enums_3401,
           @enums_3404,
           @enums_3411,
           @enums_3421,
		   @enums_3500,
		   @enums_3512
	      );

our $VERSION = '1.09';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) 
	{	
		if ($! =~ /Invalid/ || $!{EINVAL}) 
		{
	    	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	    	goto &AutoLoader::AUTOLOAD;
		}
		else 
		{
		    croak "Your vendor has not defined LoadLeveler macro $constname";
		}
    }
    {
		no strict 'refs';
		# Fixed between 5.005_53 and 5.005_61
		if ($] >= 5.00561) 
		{
		    *$AUTOLOAD = sub () { $val };
		}
		else 
		{
		    *$AUTOLOAD = sub { $val };
		}
    }
    goto &$AUTOLOAD;
}

bootstrap IBM::LoadLeveler $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.


sub llctl
{
    my $operation      = shift;
	my $class_list_ref = shift;
	my $host_list_ref  = shift;

    if ( $operation != \&LL_CONTROL_START &&
	 	 $operation != \&LL_CONTROL_STOP &&
	 	 $operation != \&LL_CONTROL_RECYCLE &&
	 	 $operation != \&LL_CONTROL_RECONFIG &&
		 $operation != \&LL_CONTROL_DRAIN &&
		 $operation != \&LL_CONTROL_DRAIN_SCHEDD &&
		 $operation != \&LL_CONTROL_DRAIN_STARTD &&
		 $operation != \&LL_CONTROL_FLUSH &&
		 $operation != \&LL_CONTROL_PURGE_SCHEDD &&
		 $operation != \&LL_CONTROL_SUSPEND &&
		 $operation != \&LL_CONTROL_RESUME &&
		 $operation != \&LL_CONTROL_RESUME_STARTD &&
		 $operation != \&LL_CONTROL_RESUME_SCHEDD &&
		 $operation != \&LL_CONTROL_START_DRAINED &&
		 $operation != \&LL_CONTROL_FAVOR_JOB &&
		 $operation != \&LL_CONTROL_UNFAVOR_JOB &&
		 $operation != \&LL_CONTROL_FAVOR_USER &&
		 $operation != \&LL_CONTROL_UNFAVOR_USER &&
		 $operation != \&LL_CONTROL_HOLD_USER &&
		 $operation != \&LL_CONTROL_HOLD_SYSTEM &&
		 $operation != \&LL_CONTROL_HOLD_RELEASE &&
		 $operation != \&LL_CONTROL_PRIO_ABS &&
		 $operation != \&LL_CONTROL_PRIO_ADJ &&
		 $operation != \&LL_CONTROL_START_DRAINED &&
		 $operation != \&LL_CONTROL_DUMP_LOGS
       )
    {
		croak "unrecognized option for llctl";
		return undef;
    }
    else
    {
		return ll_control($operation,$host_list_ref,undef,undef,$class_list_ref,0);
    }
}

sub llfavorjob
{
    my ($operation,$job_list_ref)=@_;

    if ( $operation != \&LL_CONTROL_FAVOR_JOB &&
	     $operation != \&LL_CONTROL_UNFAVOR_JOB)
    {
		croak "unrecognized option for llfavorjob";
		return undef;
    }
    else
    {
		return ll_control($operation,undef,undef,$job_list_ref,undef,0);
    }
}
sub llfavoruser
{
    my ($operation,$user_list_ref)=@_;

    if ( $operation != \&LL_CONTROL_FAVOR_USER &&
	     $operation != \&LL_CONTROL_UNFAVOR_USER)
    {
		croak "unrecognized option for llfavorjob";
		return undef;
    }
    else
    {
		return ll_control($operation,undef,$user_list_ref,undef,undef,0);
    }
}

sub llhold
{
    my ($operation, $host_list_ref, $user_list_ref, $job_list_ref) = @_;

    if ( $operation != \&LL_CONTROL_HOLD_USER &&
	     $operation != \&LL_CONTROL_HOLD_SYSTEM &&
	     $operation != \&LL_CONTROL_HOLD_RELEASE )
    {
		croak "unrecognized option for llhold";
		return undef;
    }
    else
    {
		return ll_control($operation,$host_list_ref,$user_list_ref,$job_list_ref,undef,0);
    }
}

sub llprio
{
    my ($operation,$job_list_ref,$priority)=@_;

    if ( $operation != \&LL_CONTROL_PRIO_ABS &&
	     $operation != \&LL_CONTROL_PRIO_ADJ )
    {
		croak "unrecognized option for llprio";
		return undef;
    }
    else
    {
		return ll_control($operation,undef,undef,$job_list_ref,undef,$priority);
    }
}

1;
__END__
