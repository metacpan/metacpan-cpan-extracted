# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfWorkflow (com.documentum.fc.client.IDfWorkflow)
# ------------------------------------------------------------------ #

package IDfWorkflow;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfWorkflow';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


sub queue {
	## METHOD: com.documentum.fc.common.IDfId queue(java.lang.String,int,int,boolean,com.documentum.fc.common.IDfTime,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $queue = JPL::AutoLoader::getmeth('queue',['java.lang.String','int','int','boolean','com.documentum.fc.common.IDfTime','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$queue($p0,$p1,$p2,$p3,$$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub resume {
	## METHOD: void resume(int)
    my ($self,$p0) = @_;
    my $resume = JPL::AutoLoader::getmeth('resume',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$resume($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub halt {
	## METHOD: void halt(int)
    my ($self,$p0) = @_;
    my $halt = JPL::AutoLoader::getmeth('halt',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$halt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub execute {
	## METHOD: void execute()
    my $self = shift;
    my $execute = JPL::AutoLoader::getmeth('execute',[],[]);
    my $rv = "";
    eval { $rv = $$self->$execute(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasSetId {
	## METHOD: com.documentum.fc.common.IDfId getAliasSetId()
    my $self = shift;
    my $getAliasSetId = JPL::AutoLoader::getmeth('getAliasSetId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAliasSetId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getCreatorName {
	## METHOD: java.lang.String getCreatorName()
    my $self = shift;
    my $getCreatorName = JPL::AutoLoader::getmeth('getCreatorName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCreatorName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectName {
	## METHOD: java.lang.String getObjectName()
    my $self = shift;
    my $getObjectName = JPL::AutoLoader::getmeth('getObjectName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setObjectName {
	## METHOD: void setObjectName(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectName = JPL::AutoLoader::getmeth('setObjectName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setObjectName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub abort {
	## METHOD: void abort()
    my $self = shift;
    my $abort = JPL::AutoLoader::getmeth('abort',[],[]);
    my $rv = "";
    eval { $rv = $$self->$abort(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActivityCount {
	## METHOD: int getActivityCount()
    my $self = shift;
    my $getActivityCount = JPL::AutoLoader::getmeth('getActivityCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActivityCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setProcessId {
	## METHOD: void setProcessId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setProcessId = JPL::AutoLoader::getmeth('setProcessId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setProcessId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addPackage {
	## METHOD: com.documentum.fc.common.IDfId addPackage(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,boolean,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6) = @_;
    my $addPackage = JPL::AutoLoader::getmeth('addPackage',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','boolean','com.documentum.fc.common.IDfList'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$addPackage($p0,$p1,$p2,$p3,$p4,$p5,$$p6); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getPreTimer {
	## METHOD: com.documentum.fc.common.IDfTime getPreTimer(int)
    my ($self,$p0) = @_;
    my $getPreTimer = JPL::AutoLoader::getmeth('getPreTimer',['int'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getPreTimer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getPostTimer {
	## METHOD: com.documentum.fc.common.IDfTime getPostTimer(int)
    my ($self,$p0) = @_;
    my $getPostTimer = JPL::AutoLoader::getmeth('getPostTimer',['int'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getPostTimer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getPerformerFlag {
	## METHOD: int getPerformerFlag(int)
    my ($self,$p0) = @_;
    my $getPerformerFlag = JPL::AutoLoader::getmeth('getPerformerFlag',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPerformerFlag($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActSeqno {
	## METHOD: int getActSeqno(int)
    my ($self,$p0) = @_;
    my $getActSeqno = JPL::AutoLoader::getmeth('getActSeqno',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActSeqno($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActDefId {
	## METHOD: com.documentum.fc.common.IDfId getActDefId(int)
    my ($self,$p0) = @_;
    my $getActDefId = JPL::AutoLoader::getmeth('getActDefId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getActDefId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getSupervisorName {
	## METHOD: java.lang.String getSupervisorName()
    my $self = shift;
    my $getSupervisorName = JPL::AutoLoader::getmeth('getSupervisorName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSupervisorName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removePackage {
	## METHOD: void removePackage(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $removePackage = JPL::AutoLoader::getmeth('removePackage',['java.lang.String','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePackage($p0,$p1,$p2); };
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

sub getLastWitemId {
	## METHOD: com.documentum.fc.common.IDfId getLastWitemId(int)
    my ($self,$p0) = @_;
    my $getLastWitemId = JPL::AutoLoader::getmeth('getLastWitemId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getLastWitemId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getTriggerInput {
	## METHOD: int getTriggerInput(int)
    my ($self,$p0) = @_;
    my $getTriggerInput = JPL::AutoLoader::getmeth('getTriggerInput',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTriggerInput($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNextSeqno {
	## METHOD: int getNextSeqno()
    my $self = shift;
    my $getNextSeqno = JPL::AutoLoader::getmeth('getNextSeqno',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getNextSeqno(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTriggerRevert {
	## METHOD: int getTriggerRevert(int)
    my ($self,$p0) = @_;
    my $getTriggerRevert = JPL::AutoLoader::getmeth('getTriggerRevert',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTriggerRevert($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSupervisorName {
	## METHOD: void setSupervisorName(java.lang.String)
    my ($self,$p0) = @_;
    my $setSupervisorName = JPL::AutoLoader::getmeth('setSupervisorName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSupervisorName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatInvoke {
	## METHOD: boolean getRepeatInvoke(int)
    my ($self,$p0) = @_;
    my $getRepeatInvoke = JPL::AutoLoader::getmeth('getRepeatInvoke',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatInvoke($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub restart {
	## METHOD: void restart(int)
    my ($self,$p0) = @_;
    my $restart = JPL::AutoLoader::getmeth('restart',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$restart($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resumeAll {
	## METHOD: void resumeAll()
    my $self = shift;
    my $resumeAll = JPL::AutoLoader::getmeth('resumeAll',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resumeAll(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLastPerformer {
	## METHOD: java.lang.String getLastPerformer(int)
    my ($self,$p0) = @_;
    my $getLastPerformer = JPL::AutoLoader::getmeth('getLastPerformer',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLastPerformer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTotalWitem {
	## METHOD: int getTotalWitem(int)
    my ($self,$p0) = @_;
    my $getTotalWitem = JPL::AutoLoader::getmeth('getTotalWitem',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTotalWitem($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCompleteWitem {
	## METHOD: int getCompleteWitem(int)
    my ($self,$p0) = @_;
    my $getCompleteWitem = JPL::AutoLoader::getmeth('getCompleteWitem',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCompleteWitem($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getProcessId {
	## METHOD: com.documentum.fc.common.IDfId getProcessId()
    my $self = shift;
    my $getProcessId = JPL::AutoLoader::getmeth('getProcessId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getProcessId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub haltAll {
	## METHOD: void haltAll()
    my $self = shift;
    my $haltAll = JPL::AutoLoader::getmeth('haltAll',[],[]);
    my $rv = "";
    eval { $rv = $$self->$haltAll(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActName {
	## METHOD: java.lang.String getActName(int)
    my ($self,$p0) = @_;
    my $getActName = JPL::AutoLoader::getmeth('getActName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getActName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActErrorno {
	## METHOD: int getActErrorno(int)
    my ($self,$p0) = @_;
    my $getActErrorno = JPL::AutoLoader::getmeth('getActErrorno',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActErrorno($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStartDate {
	## METHOD: com.documentum.fc.common.IDfTime getStartDate()
    my $self = shift;
    my $getStartDate = JPL::AutoLoader::getmeth('getStartDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getStartDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getActState {
	## METHOD: int getActState(int)
    my ($self,$p0) = @_;
    my $getActState = JPL::AutoLoader::getmeth('getActState',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActState($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTriggerThresh {
	## METHOD: int getTriggerThresh(int)
    my ($self,$p0) = @_;
    my $getTriggerThresh = JPL::AutoLoader::getmeth('getTriggerThresh',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTriggerThresh($p0); };
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
