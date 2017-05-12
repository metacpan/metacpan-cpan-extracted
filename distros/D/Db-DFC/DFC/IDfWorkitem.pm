# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfWorkitem (com.documentum.fc.client.IDfWorkitem)
# ------------------------------------------------------------------ #

package IDfWorkitem;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfWorkitem';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfPackage';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.client.IDfActivity';
use JPL::Class 'com.documentum.fc.client.IDfCollection';


sub getPackage {
	## METHOD: com.documentum.fc.client.IDfPackage getPackage(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $getPackage = JPL::AutoLoader::getmeth('getPackage',['com.documentum.fc.common.IDfId'],['com.documentum.fc.client.IDfPackage']);
    my $rv = "";
    eval { $rv = $$self->$getPackage($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPackage);
        return \$rv;
    }
}

sub getPackages {
	## METHOD: com.documentum.fc.client.IDfCollection getPackages(java.lang.String)
    my ($self,$p0) = @_;
    my $getPackages = JPL::AutoLoader::getmeth('getPackages',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getPackages($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getPriority {
	## METHOD: int getPriority()
    my $self = shift;
    my $getPriority = JPL::AutoLoader::getmeth('getPriority',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPriority(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resume {
	## METHOD: void resume()
    my $self = shift;
    my $resume = JPL::AutoLoader::getmeth('resume',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resume(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCreationDate {
	## METHOD: com.documentum.fc.common.IDfTime getCreationDate()
    my $self = shift;
    my $getCreationDate = JPL::AutoLoader::getmeth('getCreationDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getCreationDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub addPackage {
	## METHOD: com.documentum.fc.common.IDfId addPackage(java.lang.String,java.lang.String,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2) = @_;
    my $addPackage = JPL::AutoLoader::getmeth('addPackage',['java.lang.String','java.lang.String','com.documentum.fc.common.IDfList'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$addPackage($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub acquire {
	## METHOD: void acquire()
    my $self = shift;
    my $acquire = JPL::AutoLoader::getmeth('acquire',[],[]);
    my $rv = "";
    eval { $rv = $$self->$acquire(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub repeat {
	## METHOD: void repeat(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $repeat = JPL::AutoLoader::getmeth('repeat',['com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$repeat($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub complete {
	## METHOD: void complete()
    my $self = shift;
    my $complete = JPL::AutoLoader::getmeth('complete',[],[]);
    my $rv = "";
    eval { $rv = $$self->$complete(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPerformerName {
	## METHOD: java.lang.String getPerformerName()
    my $self = shift;
    my $getPerformerName = JPL::AutoLoader::getmeth('getPerformerName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPerformerName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActSeqno {
	## METHOD: int getActSeqno()
    my $self = shift;
    my $getActSeqno = JPL::AutoLoader::getmeth('getActSeqno',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActSeqno(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorkflowId {
	## METHOD: com.documentum.fc.common.IDfId getWorkflowId()
    my $self = shift;
    my $getWorkflowId = JPL::AutoLoader::getmeth('getWorkflowId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getWorkflowId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getActDefId {
	## METHOD: com.documentum.fc.common.IDfId getActDefId()
    my $self = shift;
    my $getActDefId = JPL::AutoLoader::getmeth('getActDefId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getActDefId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getDueDate {
	## METHOD: com.documentum.fc.common.IDfTime getDueDate()
    my $self = shift;
    my $getDueDate = JPL::AutoLoader::getmeth('getDueDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getDueDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isSignOffRequired {
	## METHOD: boolean isSignOffRequired()
    my $self = shift;
    my $isSignOffRequired = JPL::AutoLoader::getmeth('isSignOffRequired',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSignOffRequired(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub completeEx {
	## METHOD: void completeEx(int,java.lang.String,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1,$p2) = @_;
    my $completeEx = JPL::AutoLoader::getmeth('completeEx',['int','java.lang.String','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$completeEx($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOutput {
	## METHOD: void setOutput(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $setOutput = JPL::AutoLoader::getmeth('setOutput',['com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOutput($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExtendedPerformer {
	## METHOD: java.lang.String getExtendedPerformer(int)
    my ($self,$p0) = @_;
    my $getExtendedPerformer = JPL::AutoLoader::getmeth('getExtendedPerformer',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getExtendedPerformer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removePackage {
	## METHOD: void removePackage(java.lang.String)
    my ($self,$p0) = @_;
    my $removePackage = JPL::AutoLoader::getmeth('removePackage',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePackage($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isManualExecution {
	## METHOD: boolean isManualExecution()
    my $self = shift;
    my $isManualExecution = JPL::AutoLoader::getmeth('isManualExecution',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isManualExecution(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getReturnValue {
	## METHOD: int getReturnValue()
    my $self = shift;
    my $getReturnValue = JPL::AutoLoader::getmeth('getReturnValue',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getReturnValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub pause {
	## METHOD: void pause()
    my $self = shift;
    my $pause = JPL::AutoLoader::getmeth('pause',[],[]);
    my $rv = "";
    eval { $rv = $$self->$pause(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOutputByActivities {
	## METHOD: void setOutputByActivities(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $setOutputByActivities = JPL::AutoLoader::getmeth('setOutputByActivities',['com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOutputByActivities($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getOutputPort {
	## METHOD: java.lang.String getOutputPort(int)
    my ($self,$p0) = @_;
    my $getOutputPort = JPL::AutoLoader::getmeth('getOutputPort',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getOutputPort($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAutoMethodId {
	## METHOD: com.documentum.fc.common.IDfId getAutoMethodId()
    my $self = shift;
    my $getAutoMethodId = JPL::AutoLoader::getmeth('getAutoMethodId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAutoMethodId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getMissingOutputPackages {
	## METHOD: com.documentum.fc.client.IDfCollection getMissingOutputPackages()
    my $self = shift;
    my $getMissingOutputPackages = JPL::AutoLoader::getmeth('getMissingOutputPackages',[],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getMissingOutputPackages(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getOutputPortCount {
	## METHOD: int getOutputPortCount()
    my $self = shift;
    my $getOutputPortCount = JPL::AutoLoader::getmeth('getOutputPortCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getOutputPortCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExtendedPerformerCount {
	## METHOD: int getExtendedPerformerCount()
    my $self = shift;
    my $getExtendedPerformerCount = JPL::AutoLoader::getmeth('getExtendedPerformerCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getExtendedPerformerCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub delegateTask {
	## METHOD: void delegateTask(java.lang.String)
    my ($self,$p0) = @_;
    my $delegateTask = JPL::AutoLoader::getmeth('delegateTask',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$delegateTask($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRuntimeState {
	## METHOD: int getRuntimeState()
    my $self = shift;
    my $getRuntimeState = JPL::AutoLoader::getmeth('getRuntimeState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getRuntimeState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecOsError {
	## METHOD: java.lang.String getExecOsError()
    my $self = shift;
    my $getExecOsError = JPL::AutoLoader::getmeth('getExecOsError',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getExecOsError(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isDelegatable {
	## METHOD: boolean isDelegatable()
    my $self = shift;
    my $isDelegatable = JPL::AutoLoader::getmeth('isDelegatable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDelegatable(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getForwardActivities {
	## METHOD: com.documentum.fc.common.IDfList getForwardActivities()
    my $self = shift;
    my $getForwardActivities = JPL::AutoLoader::getmeth('getForwardActivities',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getForwardActivities(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getActivity {
	## METHOD: com.documentum.fc.client.IDfActivity getActivity()
    my $self = shift;
    my $getActivity = JPL::AutoLoader::getmeth('getActivity',[],['com.documentum.fc.client.IDfActivity']);
    my $rv = "";
    eval { $rv = $$self->$getActivity(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfActivity);
        return \$rv;
    }
}

sub isExecTimeOut {
	## METHOD: boolean isExecTimeOut()
    my $self = shift;
    my $isExecTimeOut = JPL::AutoLoader::getmeth('isExecTimeOut',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isExecTimeOut(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecResultId {
	## METHOD: com.documentum.fc.common.IDfId getExecResultId()
    my $self = shift;
    my $getExecResultId = JPL::AutoLoader::getmeth('getExecResultId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getExecResultId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getQueueItemId {
	## METHOD: com.documentum.fc.common.IDfId getQueueItemId()
    my $self = shift;
    my $getQueueItemId = JPL::AutoLoader::getmeth('getQueueItemId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getQueueItemId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getNextActivityNames {
	## METHOD: com.documentum.fc.common.IDfList getNextActivityNames()
    my $self = shift;
    my $getNextActivityNames = JPL::AutoLoader::getmeth('getNextActivityNames',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getNextActivityNames(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getPreviousActivityNames {
	## METHOD: com.documentum.fc.common.IDfList getPreviousActivityNames()
    my $self = shift;
    my $getPreviousActivityNames = JPL::AutoLoader::getmeth('getPreviousActivityNames',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getPreviousActivityNames(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getRejectActivities {
	## METHOD: com.documentum.fc.common.IDfList getRejectActivities()
    my $self = shift;
    my $getRejectActivities = JPL::AutoLoader::getmeth('getRejectActivities',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getRejectActivities(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub isExecLaunch {
	## METHOD: boolean isExecLaunch()
    my $self = shift;
    my $isExecLaunch = JPL::AutoLoader::getmeth('isExecLaunch',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isExecLaunch(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRepeatable {
	## METHOD: boolean isRepeatable()
    my $self = shift;
    my $isRepeatable = JPL::AutoLoader::getmeth('isRepeatable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRepeatable(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isManualTransition {
	## METHOD: boolean isManualTransition()
    my $self = shift;
    my $isManualTransition = JPL::AutoLoader::getmeth('isManualTransition',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isManualTransition(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
