# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfActivity (com.documentum.fc.client.IDfActivity)
# ------------------------------------------------------------------ #

package IDfActivity;
@ISA = (IDfSysObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfActivity';
use JPL::Class 'com.documentum.fc.common.IDfId';


sub isPrivate {
	## METHOD: boolean isPrivate()
    my $self = shift;
    my $isPrivate = JPL::AutoLoader::getmeth('isPrivate',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isPrivate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validate {
	## METHOD: void validate()
    my $self = shift;
    my $validate = JPL::AutoLoader::getmeth('validate',[],[]);
    my $rv = "";
    eval { $rv = $$self->$validate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub install {
	## METHOD: void install()
    my $self = shift;
    my $install = JPL::AutoLoader::getmeth('install',[],[]);
    my $rv = "";
    eval { $rv = $$self->$install(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub uninstall {
	## METHOD: void uninstall()
    my $self = shift;
    my $uninstall = JPL::AutoLoader::getmeth('uninstall',[],[]);
    my $rv = "";
    eval { $rv = $$self->$uninstall(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub invalidate {
	## METHOD: void invalidate()
    my $self = shift;
    my $invalidate = JPL::AutoLoader::getmeth('invalidate',[],[]);
    my $rv = "";
    eval { $rv = $$self->$invalidate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPortType {
	## METHOD: java.lang.String getPortType(int)
    my ($self,$p0) = @_;
    my $getPortType = JPL::AutoLoader::getmeth('getPortType',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPortType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPreTimer {
	## METHOD: int getPreTimer()
    my $self = shift;
    my $getPreTimer = JPL::AutoLoader::getmeth('getPreTimer',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPreTimer(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPreTimer {
	## METHOD: void setPreTimer(int)
    my ($self,$p0) = @_;
    my $setPreTimer = JPL::AutoLoader::getmeth('setPreTimer',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPreTimer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageOperation {
	## METHOD: java.lang.String getPackageOperation(int)
    my ($self,$p0) = @_;
    my $getPackageOperation = JPL::AutoLoader::getmeth('getPackageOperation',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageOperation($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getConditionName {
	## METHOD: java.lang.String getConditionName(int)
    my ($self,$p0) = @_;
    my $getConditionName = JPL::AutoLoader::getmeth('getConditionName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getConditionName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResolveType {
	## METHOD: int getResolveType()
    my $self = shift;
    my $getResolveType = JPL::AutoLoader::getmeth('getResolveType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getResolveType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setResolveType {
	## METHOD: void setResolveType(int)
    my ($self,$p0) = @_;
    my $setResolveType = JPL::AutoLoader::getmeth('setResolveType',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setResolveType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTriggerEvent {
	## METHOD: java.lang.String getTriggerEvent()
    my $self = shift;
    my $getTriggerEvent = JPL::AutoLoader::getmeth('getTriggerEvent',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTriggerEvent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTriggerEvent {
	## METHOD: void setTriggerEvent(java.lang.String)
    my ($self,$p0) = @_;
    my $setTriggerEvent = JPL::AutoLoader::getmeth('setTriggerEvent',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTriggerEvent($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRepeatableInvoke {
	## METHOD: void setRepeatableInvoke(boolean)
    my ($self,$p0) = @_;
    my $setRepeatableInvoke = JPL::AutoLoader::getmeth('setRepeatableInvoke',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatableInvoke($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecTimeOut {
	## METHOD: int getExecTimeOut()
    my $self = shift;
    my $getExecTimeOut = JPL::AutoLoader::getmeth('getExecTimeOut',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getExecTimeOut(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExecTimeOut {
	## METHOD: void setExecTimeOut(int)
    my ($self,$p0) = @_;
    my $setExecTimeOut = JPL::AutoLoader::getmeth('setExecTimeOut',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExecTimeOut($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removePort {
	## METHOD: void removePort(java.lang.String)
    my ($self,$p0) = @_;
    my $removePort = JPL::AutoLoader::getmeth('removePort',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePort($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSignoffRequired {
	## METHOD: boolean getSignoffRequired()
    my $self = shift;
    my $getSignoffRequired = JPL::AutoLoader::getmeth('getSignoffRequired',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getSignoffRequired(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSignoffRequired {
	## METHOD: void setSignoffRequired(boolean)
    my ($self,$p0) = @_;
    my $setSignoffRequired = JPL::AutoLoader::getmeth('setSignoffRequired',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSignoffRequired($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getConditionPort {
	## METHOD: java.lang.String getConditionPort(int)
    my ($self,$p0) = @_;
    my $getConditionPort = JPL::AutoLoader::getmeth('getConditionPort',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getConditionPort($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTriggerThreshold {
	## METHOD: int getTriggerThreshold()
    my $self = shift;
    my $getTriggerThreshold = JPL::AutoLoader::getmeth('getTriggerThreshold',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTriggerThreshold(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTriggerThreshold {
	## METHOD: void setTriggerThreshold(int)
    my ($self,$p0) = @_;
    my $setTriggerThreshold = JPL::AutoLoader::getmeth('setTriggerThreshold',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTriggerThreshold($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeRouteCase {
	## METHOD: void removeRouteCase(java.lang.String)
    my ($self,$p0) = @_;
    my $removeRouteCase = JPL::AutoLoader::getmeth('removeRouteCase',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeRouteCase($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPerformerType {
	## METHOD: int getPerformerType()
    my $self = shift;
    my $getPerformerType = JPL::AutoLoader::getmeth('getPerformerType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPerformerType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPerformerType {
	## METHOD: void setPerformerType(int)
    my ($self,$p0) = @_;
    my $setPerformerType = JPL::AutoLoader::getmeth('setPerformerType',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPerformerType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageType {
	## METHOD: java.lang.String getPackageType(int)
    my ($self,$p0) = @_;
    my $getPackageType = JPL::AutoLoader::getmeth('getPackageType',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageCount {
	## METHOD: int getPackageCount()
    my $self = shift;
    my $getPackageCount = JPL::AutoLoader::getmeth('getPackageCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPackageCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addPackageInfo {
	## METHOD: void addPackageInfo(java.lang.String,java.lang.String,java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $addPackageInfo = JPL::AutoLoader::getmeth('addPackageInfo',['java.lang.String','java.lang.String','java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$addPackageInfo($p0,$p1,$p2,$$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResolvePackageName {
	## METHOD: java.lang.String getResolvePackageName()
    my $self = shift;
    my $getResolvePackageName = JPL::AutoLoader::getmeth('getResolvePackageName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getResolvePackageName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageId {
	## METHOD: com.documentum.fc.common.IDfId getPackageId(int)
    my ($self,$p0) = @_;
    my $getPackageId = JPL::AutoLoader::getmeth('getPackageId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getPackageId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getPostTimer {
	## METHOD: int getPostTimer()
    my $self = shift;
    my $getPostTimer = JPL::AutoLoader::getmeth('getPostTimer',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPostTimer(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPostTimer {
	## METHOD: void setPostTimer(int)
    my ($self,$p0) = @_;
    my $setPostTimer = JPL::AutoLoader::getmeth('setPostTimer',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPostTimer($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setResolvePackageName {
	## METHOD: void setResolvePackageName(java.lang.String)
    my ($self,$p0) = @_;
    my $setResolvePackageName = JPL::AutoLoader::getmeth('setResolvePackageName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setResolvePackageName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageLabel {
	## METHOD: java.lang.String getPackageLabel(int)
    my ($self,$p0) = @_;
    my $getPackageLabel = JPL::AutoLoader::getmeth('getPackageLabel',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecErrHandling {
	## METHOD: int getExecErrHandling()
    my $self = shift;
    my $getExecErrHandling = JPL::AutoLoader::getmeth('getExecErrHandling',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getExecErrHandling(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExecErrHandling {
	## METHOD: void setExecErrHandling(int)
    my ($self,$p0) = @_;
    my $setExecErrHandling = JPL::AutoLoader::getmeth('setExecErrHandling',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExecErrHandling($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPortCount {
	## METHOD: int getPortCount()
    my $self = shift;
    my $getPortCount = JPL::AutoLoader::getmeth('getPortCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPortCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getConditionCount {
	## METHOD: int getConditionCount()
    my $self = shift;
    my $getConditionCount = JPL::AutoLoader::getmeth('getConditionCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getConditionCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPerformerFlag {
	## METHOD: int getPerformerFlag()
    my $self = shift;
    my $getPerformerFlag = JPL::AutoLoader::getmeth('getPerformerFlag',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPerformerFlag(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefinitionState {
	## METHOD: java.lang.String getDefinitionState()
    my $self = shift;
    my $getDefinitionState = JPL::AutoLoader::getmeth('getDefinitionState',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefinitionState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPerformerFlag {
	## METHOD: void setPerformerFlag(int)
    my ($self,$p0) = @_;
    my $setPerformerFlag = JPL::AutoLoader::getmeth('setPerformerFlag',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPerformerFlag($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addPort {
	## METHOD: void addPort(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $addPort = JPL::AutoLoader::getmeth('addPort',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$addPort($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecType {
	## METHOD: int getExecType()
    my $self = shift;
    my $getExecType = JPL::AutoLoader::getmeth('getExecType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getExecType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExecType {
	## METHOD: void setExecType(int)
    my ($self,$p0) = @_;
    my $setExecType = JPL::AutoLoader::getmeth('setExecType',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExecType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTransitionType {
	## METHOD: int getTransitionType()
    my $self = shift;
    my $getTransitionType = JPL::AutoLoader::getmeth('getTransitionType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTransitionType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExecSaveResults {
	## METHOD: void setExecSaveResults(boolean)
    my ($self,$p0) = @_;
    my $setExecSaveResults = JPL::AutoLoader::getmeth('setExecSaveResults',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExecSaveResults($p0); };
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

sub setPerformerName {
	## METHOD: void setPerformerName(java.lang.String)
    my ($self,$p0) = @_;
    my $setPerformerName = JPL::AutoLoader::getmeth('setPerformerName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPerformerName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTransitionType {
	## METHOD: void setTransitionType(int)
    my ($self,$p0) = @_;
    my $setTransitionType = JPL::AutoLoader::getmeth('setTransitionType',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTransitionType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getConditionId {
	## METHOD: com.documentum.fc.common.IDfId getConditionId()
    my $self = shift;
    my $getConditionId = JPL::AutoLoader::getmeth('getConditionId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getConditionId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getPackageName {
	## METHOD: java.lang.String getPackageName(int)
    my ($self,$p0) = @_;
    my $getPackageName = JPL::AutoLoader::getmeth('getPackageName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addRouteCase {
	## METHOD: void addRouteCase(java.lang.String,java.lang.String,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2) = @_;
    my $addRouteCase = JPL::AutoLoader::getmeth('addRouteCase',['java.lang.String','java.lang.String','com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$addRouteCase($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removePackageInfo {
	## METHOD: void removePackageInfo(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $removePackageInfo = JPL::AutoLoader::getmeth('removePackageInfo',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePackageInfo($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecMethodId {
	## METHOD: com.documentum.fc.common.IDfId getExecMethodId()
    my $self = shift;
    my $getExecMethodId = JPL::AutoLoader::getmeth('getExecMethodId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getExecMethodId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setExecMethodId {
	## METHOD: void setExecMethodId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setExecMethodId = JPL::AutoLoader::getmeth('setExecMethodId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExecMethodId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPortName {
	## METHOD: java.lang.String getPortName(int)
    my ($self,$p0) = @_;
    my $getPortName = JPL::AutoLoader::getmeth('getPortName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPortName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPrivate {
	## METHOD: void setPrivate(boolean)
    my ($self,$p0) = @_;
    my $setPrivate = JPL::AutoLoader::getmeth('setPrivate',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPrivate($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRepeatableInvoke {
	## METHOD: boolean isRepeatableInvoke()
    my $self = shift;
    my $isRepeatableInvoke = JPL::AutoLoader::getmeth('isRepeatableInvoke',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRepeatableInvoke(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isExecSaveResults {
	## METHOD: boolean isExecSaveResults()
    my $self = shift;
    my $isExecSaveResults = JPL::AutoLoader::getmeth('isExecSaveResults',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isExecSaveResults(); };
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
