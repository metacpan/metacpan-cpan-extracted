# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfSession (com.documentum.fc.client.IDfSession)
# ------------------------------------------------------------------ #

package IDfSession;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfSession';
use JPL::Class 'com.documentum.fc.client.IDfFolder';
use JPL::Class 'com.documentum.fc.client.IDfVersionTreeLabels';
use JPL::Class 'com.documentum.fc.client.IDfWorkflowBuilder';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfGroup';
use JPL::Class 'com.documentum.fc.client.IDfUser';
use JPL::Class 'com.documentum.fc.client.IDfTypedObject';
use JPL::Class 'com.documentum.fc.client.IDfACL';
use JPL::Class 'com.documentum.fc.client.IDfPersistentObject';
use JPL::Class 'com.documentum.fc.client.IDfClient';
use JPL::Class 'com.documentum.fc.common.IDfLoginInfo';
use JPL::Class 'com.documentum.fc.client.IDfFormat';
use JPL::Class 'com.documentum.fc.client.IDfType';
use JPL::Class 'com.documentum.fc.client.IDfRelationType';
use JPL::Class 'com.documentum.fc.client.IDfCollection';

use constant DF_TASKS => 1;
use constant DF_NOTIFICATIONS => 2;
use constant DF_TASKS_AND_NOTIFICATIONS => 3;
use constant DM_GET => 0;
use constant DM_SET => 1;
use constant DM_EXEC => 2;
use constant DM_OTHER => 3;

sub shutdown {
	## METHOD: void shutdown(boolean,boolean)
    my ($self,$p0,$p1) = @_;
    my $shutdown = JPL::AutoLoader::getmeth('shutdown',['boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$shutdown($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub lock {
	## METHOD: boolean lock(int)
    my ($self,$p0) = @_;
    my $lock = JPL::AutoLoader::getmeth('lock',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$lock($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub flush {
	## METHOD: void flush(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $flush = JPL::AutoLoader::getmeth('flush',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$flush($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMessage {
	## METHOD: java.lang.String getMessage(int)
    my ($self,$p0) = @_;
    my $getMessage = JPL::AutoLoader::getmeth('getMessage',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMessage($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getType {
	## METHOD: com.documentum.fc.client.IDfType getType(java.lang.String)
    my ($self,$p0) = @_;
    my $getType = JPL::AutoLoader::getmeth('getType',['java.lang.String'],['com.documentum.fc.client.IDfType']);
    my $rv = "";
    eval { $rv = $$self->$getType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfType);
        return \$rv;
    }
}

sub getObject {
	## METHOD: com.documentum.fc.client.IDfPersistentObject getObject(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $getObject = JPL::AutoLoader::getmeth('getObject',['com.documentum.fc.common.IDfId'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$getObject($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub getLoginInfo {
	## METHOD: com.documentum.fc.common.IDfLoginInfo getLoginInfo()
    my $self = shift;
    my $getLoginInfo = JPL::AutoLoader::getmeth('getLoginInfo',[],['com.documentum.fc.common.IDfLoginInfo']);
    my $rv = "";
    eval { $rv = $$self->$getLoginInfo(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfLoginInfo);
        return \$rv;
    }
}

sub getDocbaseId {
	## METHOD: java.lang.String getDocbaseId()
    my $self = shift;
    my $getDocbaseId = JPL::AutoLoader::getmeth('getDocbaseId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseName {
	## METHOD: java.lang.String getDocbaseName()
    my $self = shift;
    my $getDocbaseName = JPL::AutoLoader::getmeth('getDocbaseName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUser {
	## METHOD: com.documentum.fc.client.IDfUser getUser(java.lang.String)
    my ($self,$p0) = @_;
    my $getUser = JPL::AutoLoader::getmeth('getUser',['java.lang.String'],['com.documentum.fc.client.IDfUser']);
    my $rv = "";
    eval { $rv = $$self->$getUser($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfUser);
        return \$rv;
    }
}

sub getSessionId {
	## METHOD: java.lang.String getSessionId()
    my $self = shift;
    my $getSessionId = JPL::AutoLoader::getmeth('getSessionId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSessionId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserByOSName {
	## METHOD: com.documentum.fc.client.IDfUser getUserByOSName(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getUserByOSName = JPL::AutoLoader::getmeth('getUserByOSName',['java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfUser']);
    my $rv = "";
    eval { $rv = $$self->$getUserByOSName($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfUser);
        return \$rv;
    }
}

sub archive {
	## METHOD: com.documentum.fc.common.IDfId archive(java.lang.String,java.lang.String,int,boolean,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $archive = JPL::AutoLoader::getmeth('archive',['java.lang.String','java.lang.String','int','boolean','com.documentum.fc.common.IDfTime'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$archive($p0,$p1,$p2,$p3,$$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getEvents {
	## METHOD: com.documentum.fc.client.IDfCollection getEvents()
    my $self = shift;
    my $getEvents = JPL::AutoLoader::getmeth('getEvents',[],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getEvents(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getObjectWithType {
	## METHOD: com.documentum.fc.client.IDfPersistentObject getObjectWithType(com.documentum.fc.common.IDfId,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $getObjectWithType = JPL::AutoLoader::getmeth('getObjectWithType',['com.documentum.fc.common.IDfId','java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$getObjectWithType($$p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub apiSetBytes {
	## METHOD: boolean apiSetBytes(java.lang.String,java.lang.String,java.io.ByteArrayOutputStream)
    my ($self,$p0,$p1,$p2) = @_;
    my $apiSetBytes = JPL::AutoLoader::getmeth('apiSetBytes',['java.lang.String','java.lang.String','java.io.ByteArrayOutputStream'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$apiSetBytes($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub apiSet {
	## METHOD: boolean apiSet(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $apiSet = JPL::AutoLoader::getmeth('apiSet',['java.lang.String','java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$apiSet($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub describe {
	## METHOD: java.lang.String describe(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $describe = JPL::AutoLoader::getmeth('describe',['java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$describe($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub restore {
	## METHOD: com.documentum.fc.common.IDfId restore(java.lang.String,java.lang.String,java.lang.String,int,boolean,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $restore = JPL::AutoLoader::getmeth('restore',['java.lang.String','java.lang.String','java.lang.String','int','boolean','com.documentum.fc.common.IDfTime'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$restore($p0,$p1,$p2,$p3,$p4,$$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getClientConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getClientConfig()
    my $self = shift;
    my $getClientConfig = JPL::AutoLoader::getmeth('getClientConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getClientConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getSessionConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getSessionConfig()
    my $self = shift;
    my $getSessionConfig = JPL::AutoLoader::getmeth('getSessionConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getSessionConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getLoginUserName {
	## METHOD: java.lang.String getLoginUserName()
    my $self = shift;
    my $getLoginUserName = JPL::AutoLoader::getmeth('getLoginUserName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLoginUserName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getDocbaseConfig()
    my $self = shift;
    my $getDocbaseConfig = JPL::AutoLoader::getmeth('getDocbaseConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getServerConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerConfig()
    my $self = shift;
    my $getServerConfig = JPL::AutoLoader::getmeth('getServerConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub disconnect {
	## METHOD: void disconnect()
    my $self = shift;
    my $disconnect = JPL::AutoLoader::getmeth('disconnect',[],[]);
    my $rv = "";
    eval { $rv = $$self->$disconnect(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeDescription {
	## METHOD: com.documentum.fc.client.IDfTypedObject getTypeDescription(java.lang.String,java.lang.String,com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getTypeDescription = JPL::AutoLoader::getmeth('getTypeDescription',['java.lang.String','java.lang.String','com.documentum.fc.common.IDfId','java.lang.String'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getTypeDescription($p0,$p1,$$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub newObject {
	## METHOD: com.documentum.fc.client.IDfPersistentObject newObject(java.lang.String)
    my ($self,$p0) = @_;
    my $newObject = JPL::AutoLoader::getmeth('newObject',['java.lang.String'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$newObject($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub getServerVersion {
	## METHOD: java.lang.String getServerVersion()
    my $self = shift;
    my $getServerVersion = JPL::AutoLoader::getmeth('getServerVersion',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getServerVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getServerMap {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerMap(java.lang.String)
    my ($self,$p0) = @_;
    my $getServerMap = JPL::AutoLoader::getmeth('getServerMap',['java.lang.String'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerMap($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub apiGet {
	## METHOD: java.lang.String apiGet(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $apiGet = JPL::AutoLoader::getmeth('apiGet',['java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$apiGet($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub sendToDistributionList {
	## METHOD: com.documentum.fc.common.IDfId sendToDistributionList(com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,java.lang.String,com.documentum.fc.common.IDfList,int,boolean)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $sendToDistributionList = JPL::AutoLoader::getmeth('sendToDistributionList',['com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','java.lang.String','com.documentum.fc.common.IDfList','int','boolean'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$sendToDistributionList($$p0,$$p1,$p2,$$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub apply {
	## METHOD: com.documentum.fc.client.IDfCollection apply(java.lang.String,java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $apply = JPL::AutoLoader::getmeth('apply',['java.lang.String','java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$apply($p0,$p1,$$p2,$$p3,$$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub purgeLocalFiles {
	## METHOD: void purgeLocalFiles()
    my $self = shift;
    my $purgeLocalFiles = JPL::AutoLoader::getmeth('purgeLocalFiles',[],[]);
    my $rv = "";
    eval { $rv = $$self->$purgeLocalFiles(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroup {
	## METHOD: com.documentum.fc.client.IDfGroup getGroup(java.lang.String)
    my ($self,$p0) = @_;
    my $getGroup = JPL::AutoLoader::getmeth('getGroup',['java.lang.String'],['com.documentum.fc.client.IDfGroup']);
    my $rv = "";
    eval { $rv = $$self->$getGroup($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfGroup);
        return \$rv;
    }
}

sub apiExec {
	## METHOD: boolean apiExec(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $apiExec = JPL::AutoLoader::getmeth('apiExec',['java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$apiExec($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRunnableProcesses {
	## METHOD: com.documentum.fc.client.IDfCollection getRunnableProcesses(java.lang.String)
    my ($self,$p0) = @_;
    my $getRunnableProcesses = JPL::AutoLoader::getmeth('getRunnableProcesses',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getRunnableProcesses($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub resolveAlias {
	## METHOD: java.lang.String resolveAlias(com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $resolveAlias = JPL::AutoLoader::getmeth('resolveAlias',['com.documentum.fc.common.IDfId','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$resolveAlias($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectByPath {
	## METHOD: com.documentum.fc.client.IDfPersistentObject getObjectByPath(java.lang.String)
    my ($self,$p0) = @_;
    my $getObjectByPath = JPL::AutoLoader::getmeth('getObjectByPath',['java.lang.String'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$getObjectByPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub getTasks {
	## METHOD: com.documentum.fc.client.IDfCollection getTasks(java.lang.String,int,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getTasks = JPL::AutoLoader::getmeth('getTasks',['java.lang.String','int','java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getTasks($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getDMCLSessionId {
	## METHOD: java.lang.String getDMCLSessionId()
    my $self = shift;
    my $getDMCLSessionId = JPL::AutoLoader::getmeth('getDMCLSessionId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDMCLSessionId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub apiDesc {
	## METHOD: com.documentum.fc.common.IDfList apiDesc(java.lang.String)
    my ($self,$p0) = @_;
    my $apiDesc = JPL::AutoLoader::getmeth('apiDesc',['java.lang.String'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$apiDesc($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub hasEvents {
	## METHOD: boolean hasEvents()
    my $self = shift;
    my $hasEvents = JPL::AutoLoader::getmeth('hasEvents',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasEvents(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub apiGetBytes {
	## METHOD: java.io.ByteArrayInputStream apiGetBytes(java.lang.String,java.lang.String,java.lang.String,java.lang.String,int)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $apiGetBytes = JPL::AutoLoader::getmeth('apiGetBytes',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','int'],['java.io.ByteArrayInputStream']);
    my $rv = "";
    eval { $rv = $$self->$apiGetBytes($p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getConnectionConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getConnectionConfig()
    my $self = shift;
    my $getConnectionConfig = JPL::AutoLoader::getmeth('getConnectionConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getConnectionConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub newWorkflowBuilder {
	## METHOD: com.documentum.fc.client.IDfWorkflowBuilder newWorkflowBuilder(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $newWorkflowBuilder = JPL::AutoLoader::getmeth('newWorkflowBuilder',['com.documentum.fc.common.IDfId'],['com.documentum.fc.client.IDfWorkflowBuilder']);
    my $rv = "";
    eval { $rv = $$self->$newWorkflowBuilder($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfWorkflowBuilder);
        return \$rv;
    }
}

sub commitTrans {
	## METHOD: void commitTrans()
    my $self = shift;
    my $commitTrans = JPL::AutoLoader::getmeth('commitTrans',[],[]);
    my $rv = "";
    eval { $rv = $$self->$commitTrans(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectByQualification {
	## METHOD: com.documentum.fc.client.IDfPersistentObject getObjectByQualification(java.lang.String)
    my ($self,$p0) = @_;
    my $getObjectByQualification = JPL::AutoLoader::getmeth('getObjectByQualification',['java.lang.String'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$getObjectByQualification($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub reInit {
	## METHOD: void reInit(java.lang.String)
    my ($self,$p0) = @_;
    my $reInit = JPL::AutoLoader::getmeth('reInit',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$reInit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getIdByQualification {
	## METHOD: com.documentum.fc.common.IDfId getIdByQualification(java.lang.String)
    my ($self,$p0) = @_;
    my $getIdByQualification = JPL::AutoLoader::getmeth('getIdByQualification',['java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getIdByQualification($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub isACLDocbase {
	## METHOD: boolean isACLDocbase()
    my $self = shift;
    my $isACLDocbase = JPL::AutoLoader::getmeth('isACLDocbase',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isACLDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceDMCL {
	## METHOD: void traceDMCL(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $traceDMCL = JPL::AutoLoader::getmeth('traceDMCL',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$traceDMCL($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getClient {
	## METHOD: com.documentum.fc.client.IDfClient getClient()
    my $self = shift;
    my $getClient = JPL::AutoLoader::getmeth('getClient',[],['com.documentum.fc.client.IDfClient']);
    my $rv = "";
    eval { $rv = $$self->$getClient(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfClient);
        return \$rv;
    }
}

sub isRemote {
	## METHOD: boolean isRemote()
    my $self = shift;
    my $isRemote = JPL::AutoLoader::getmeth('isRemote',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRemote(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isAdopted {
	## METHOD: boolean isAdopted()
    my $self = shift;
    my $isAdopted = JPL::AutoLoader::getmeth('isAdopted',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isAdopted(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFormat {
	## METHOD: com.documentum.fc.client.IDfFormat getFormat(java.lang.String)
    my ($self,$p0) = @_;
    my $getFormat = JPL::AutoLoader::getmeth('getFormat',['java.lang.String'],['com.documentum.fc.client.IDfFormat']);
    my $rv = "";
    eval { $rv = $$self->$getFormat($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfFormat);
        return \$rv;
    }
}

sub newObjectWithType {
	## METHOD: com.documentum.fc.client.IDfPersistentObject newObjectWithType(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $newObjectWithType = JPL::AutoLoader::getmeth('newObjectWithType',['java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$newObjectWithType($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub flushCache {
	## METHOD: void flushCache(boolean)
    my ($self,$p0) = @_;
    my $flushCache = JPL::AutoLoader::getmeth('flushCache',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$flushCache($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRelationType {
	## METHOD: com.documentum.fc.client.IDfRelationType getRelationType(java.lang.String)
    my ($self,$p0) = @_;
    my $getRelationType = JPL::AutoLoader::getmeth('getRelationType',['java.lang.String'],['com.documentum.fc.client.IDfRelationType']);
    my $rv = "";
    eval { $rv = $$self->$getRelationType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfRelationType);
        return \$rv;
    }
}

sub getFolderByPath {
	## METHOD: com.documentum.fc.client.IDfFolder getFolderByPath(java.lang.String)
    my ($self,$p0) = @_;
    my $getFolderByPath = JPL::AutoLoader::getmeth('getFolderByPath',['java.lang.String'],['com.documentum.fc.client.IDfFolder']);
    my $rv = "";
    eval { $rv = $$self->$getFolderByPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfFolder);
        return \$rv;
    }
}

sub setDocbaseScopeById {
	## METHOD: java.lang.String setDocbaseScopeById(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setDocbaseScopeById = JPL::AutoLoader::getmeth('setDocbaseScopeById',['com.documentum.fc.common.IDfId'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$setDocbaseScopeById($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseOwnerName {
	## METHOD: java.lang.String getDocbaseOwnerName()
    my $self = shift;
    my $getDocbaseOwnerName = JPL::AutoLoader::getmeth('getDocbaseOwnerName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseOwnerName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub abortTrans {
	## METHOD: void abortTrans()
    my $self = shift;
    my $abortTrans = JPL::AutoLoader::getmeth('abortTrans',[],[]);
    my $rv = "";
    eval { $rv = $$self->$abortTrans(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub unlock {
	## METHOD: boolean unlock()
    my $self = shift;
    my $unlock = JPL::AutoLoader::getmeth('unlock',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$unlock(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub beginTrans {
	## METHOD: void beginTrans()
    my $self = shift;
    my $beginTrans = JPL::AutoLoader::getmeth('beginTrans',[],[]);
    my $rv = "";
    eval { $rv = $$self->$beginTrans(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionTreeLabels {
	## METHOD: com.documentum.fc.client.IDfVersionTreeLabels getVersionTreeLabels(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $getVersionTreeLabels = JPL::AutoLoader::getmeth('getVersionTreeLabels',['com.documentum.fc.common.IDfId'],['com.documentum.fc.client.IDfVersionTreeLabels']);
    my $rv = "";
    eval { $rv = $$self->$getVersionTreeLabels($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVersionTreeLabels);
        return \$rv;
    }
}

sub getLastCollection {
	## METHOD: com.documentum.fc.client.IDfCollection getLastCollection()
    my $self = shift;
    my $getLastCollection = JPL::AutoLoader::getmeth('getLastCollection',[],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getLastCollection(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getDocbrokerMap {
	## METHOD: com.documentum.fc.client.IDfTypedObject getDocbrokerMap()
    my $self = shift;
    my $getDocbrokerMap = JPL::AutoLoader::getmeth('getDocbrokerMap',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getDocbrokerMap(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getLoginTicket {
	## METHOD: java.lang.String getLoginTicket()
    my $self = shift;
    my $getLoginTicket = JPL::AutoLoader::getmeth('getLoginTicket',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLoginTicket(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setBatchHint {
	## METHOD: void setBatchHint(int)
    my ($self,$p0) = @_;
    my $setBatchHint = JPL::AutoLoader::getmeth('setBatchHint',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setBatchHint($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isConnected {
	## METHOD: boolean isConnected()
    my $self = shift;
    my $isConnected = JPL::AutoLoader::getmeth('isConnected',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isConnected(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSecurityMode {
	## METHOD: java.lang.String getSecurityMode()
    my $self = shift;
    my $getSecurityMode = JPL::AutoLoader::getmeth('getSecurityMode',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSecurityMode(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseScope {
	## METHOD: java.lang.String getDocbaseScope()
    my $self = shift;
    my $getDocbaseScope = JPL::AutoLoader::getmeth('getDocbaseScope',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseScope(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDocbaseScope {
	## METHOD: java.lang.String setDocbaseScope(java.lang.String)
    my ($self,$p0) = @_;
    my $setDocbaseScope = JPL::AutoLoader::getmeth('setDocbaseScope',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$setDocbaseScope($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub changePassword {
	## METHOD: void changePassword(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $changePassword = JPL::AutoLoader::getmeth('changePassword',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$changePassword($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub dequeue {
	## METHOD: void dequeue(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $dequeue = JPL::AutoLoader::getmeth('dequeue',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$dequeue($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultACL {
	## METHOD: int getDefaultACL()
    my $self = shift;
    my $getDefaultACL = JPL::AutoLoader::getmeth('getDefaultACL',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultACL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getACL {
	## METHOD: com.documentum.fc.client.IDfACL getACL(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getACL = JPL::AutoLoader::getmeth('getACL',['java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfACL']);
    my $rv = "";
    eval { $rv = $$self->$getACL($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfACL);
        return \$rv;
    }
}

sub isShared {
	## METHOD: boolean isShared()
    my $self = shift;
    my $isShared = JPL::AutoLoader::getmeth('isShared',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isShared(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub reStart {
	## METHOD: void reStart(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $reStart = JPL::AutoLoader::getmeth('reStart',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$reStart($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDBMSName {
	## METHOD: java.lang.String getDBMSName()
    my $self = shift;
    my $getDBMSName = JPL::AutoLoader::getmeth('getDBMSName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDBMSName(); };
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
