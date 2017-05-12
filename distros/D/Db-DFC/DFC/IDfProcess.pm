# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfProcess (com.documentum.fc.client.IDfProcess)
# ------------------------------------------------------------------ #

package IDfProcess;
@ISA = (IDfSysObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfProcess';
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

sub getProcessLinkCount {
	## METHOD: int getProcessLinkCount()
    my $self = shift;
    my $getProcessLinkCount = JPL::AutoLoader::getmeth('getProcessLinkCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getProcessLinkCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkName {
	## METHOD: java.lang.String getLinkName(int)
    my ($self,$p0) = @_;
    my $getLinkName = JPL::AutoLoader::getmeth('getLinkName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLinkName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActivityDefId {
	## METHOD: com.documentum.fc.common.IDfId getActivityDefId(int)
    my ($self,$p0) = @_;
    my $getActivityDefId = JPL::AutoLoader::getmeth('getActivityDefId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getActivityDefId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getActivityName {
	## METHOD: java.lang.String getActivityName(int)
    my ($self,$p0) = @_;
    my $getActivityName = JPL::AutoLoader::getmeth('getActivityName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getActivityName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkSrcPort {
	## METHOD: java.lang.String getLinkSrcPort(int)
    my ($self,$p0) = @_;
    my $getLinkSrcPort = JPL::AutoLoader::getmeth('getLinkSrcPort',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLinkSrcPort($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkDestPort {
	## METHOD: java.lang.String getLinkDestPort(int)
    my ($self,$p0) = @_;
    my $getLinkDestPort = JPL::AutoLoader::getmeth('getLinkDestPort',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLinkDestPort($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeLink {
	## METHOD: void removeLink(java.lang.String)
    my ($self,$p0) = @_;
    my $removeLink = JPL::AutoLoader::getmeth('removeLink',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeLink($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeActivity {
	## METHOD: void removeActivity(java.lang.String)
    my ($self,$p0) = @_;
    my $removeActivity = JPL::AutoLoader::getmeth('removeActivity',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeActivity($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addActivity {
	## METHOD: void addActivity(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,int)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $addActivity = JPL::AutoLoader::getmeth('addActivity',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$addActivity($p0,$$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addLink {
	## METHOD: void addLink(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $addLink = JPL::AutoLoader::getmeth('addLink',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$addLink($p0,$p1,$p2,$p3,$p4); };
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
	## METHOD: void install(boolean,boolean)
    my ($self,$p0,$p1) = @_;
    my $install = JPL::AutoLoader::getmeth('install',['boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$install($p0,$p1); };
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

sub getDefinitionState {
	## METHOD: int getDefinitionState()
    my $self = shift;
    my $getDefinitionState = JPL::AutoLoader::getmeth('getDefinitionState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDefinitionState(); };
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

sub getActivityType {
	## METHOD: int getActivityType(int)
    my ($self,$p0) = @_;
    my $getActivityType = JPL::AutoLoader::getmeth('getActivityType',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActivityType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkDestActivity {
	## METHOD: java.lang.String getLinkDestActivity(int)
    my ($self,$p0) = @_;
    my $getLinkDestActivity = JPL::AutoLoader::getmeth('getLinkDestActivity',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLinkDestActivity($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActivityPriority {
	## METHOD: int getActivityPriority(int)
    my ($self,$p0) = @_;
    my $getActivityPriority = JPL::AutoLoader::getmeth('getActivityPriority',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActivityPriority($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateProcessAndActivities {
	## METHOD: void validateProcessAndActivities()
    my $self = shift;
    my $validateProcessAndActivities = JPL::AutoLoader::getmeth('validateProcessAndActivities',[],[]);
    my $rv = "";
    eval { $rv = $$self->$validateProcessAndActivities(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkSrcActivity {
	## METHOD: java.lang.String getLinkSrcActivity(int)
    my ($self,$p0) = @_;
    my $getLinkSrcActivity = JPL::AutoLoader::getmeth('getLinkSrcActivity',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLinkSrcActivity($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPerformerAliasId {
	## METHOD: com.documentum.fc.common.IDfId getPerformerAliasId()
    my $self = shift;
    my $getPerformerAliasId = JPL::AutoLoader::getmeth('getPerformerAliasId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getPerformerAliasId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setPerformerAliasId {
	## METHOD: void setPerformerAliasId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setPerformerAliasId = JPL::AutoLoader::getmeth('setPerformerAliasId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPerformerAliasId($$p0); };
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
