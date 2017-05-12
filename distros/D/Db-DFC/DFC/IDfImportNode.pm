# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfImportNode (com.documentum.operations.IDfImportNode)
# ------------------------------------------------------------------ #

package IDfImportNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfImportNode';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfSysObject';


sub getObject {
	## METHOD: com.documentum.fc.client.IDfSysObject getObject()
    my $self = shift;
    my $getObject = JPL::AutoLoader::getmeth('getObject',[],['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $$self->$getObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSysObject);
        return \$rv;
    }
}

sub getFormat {
	## METHOD: java.lang.String getFormat()
    my $self = shift;
    my $getFormat = JPL::AutoLoader::getmeth('getFormat',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFormat(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabels {
	## METHOD: java.lang.String getVersionLabels()
    my $self = shift;
    my $getVersionLabels = JPL::AutoLoader::getmeth('getVersionLabels',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabels(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectId {
	## METHOD: com.documentum.fc.common.IDfId getObjectId()
    my $self = shift;
    my $getObjectId = JPL::AutoLoader::getmeth('getObjectId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getObjectId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setFormat {
	## METHOD: void setFormat(java.lang.String)
    my ($self,$p0) = @_;
    my $setFormat = JPL::AutoLoader::getmeth('setFormat',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFormat($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFilePath {
	## METHOD: void setFilePath(java.lang.String)
    my ($self,$p0) = @_;
    my $setFilePath = JPL::AutoLoader::getmeth('setFilePath',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFilePath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getKeepLocalFile {
	## METHOD: boolean getKeepLocalFile()
    my $self = shift;
    my $getKeepLocalFile = JPL::AutoLoader::getmeth('getKeepLocalFile',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getKeepLocalFile(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setKeepLocalFile {
	## METHOD: void setKeepLocalFile(boolean)
    my ($self,$p0) = @_;
    my $setKeepLocalFile = JPL::AutoLoader::getmeth('setKeepLocalFile',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setKeepLocalFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDestinationFolderId {
	## METHOD: com.documentum.fc.common.IDfId getDestinationFolderId()
    my $self = shift;
    my $getDestinationFolderId = JPL::AutoLoader::getmeth('getDestinationFolderId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getDestinationFolderId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setDestinationFolderId {
	## METHOD: void setDestinationFolderId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setDestinationFolderId = JPL::AutoLoader::getmeth('setDestinationFolderId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDestinationFolderId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNewObjectId {
	## METHOD: com.documentum.fc.common.IDfId getNewObjectId()
    my $self = shift;
    my $getNewObjectId = JPL::AutoLoader::getmeth('getNewObjectId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getNewObjectId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getDocbaseObjectType {
	## METHOD: java.lang.String getDocbaseObjectType()
    my $self = shift;
    my $getDocbaseObjectType = JPL::AutoLoader::getmeth('getDocbaseObjectType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseObjectType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDocbaseObjectType {
	## METHOD: void setDocbaseObjectType(java.lang.String)
    my ($self,$p0) = @_;
    my $setDocbaseObjectType = JPL::AutoLoader::getmeth('setDocbaseObjectType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDocbaseObjectType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNewObjectName {
	## METHOD: java.lang.String getNewObjectName()
    my $self = shift;
    my $getNewObjectName = JPL::AutoLoader::getmeth('getNewObjectName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNewObjectName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setNewObjectName {
	## METHOD: void setNewObjectName(java.lang.String)
    my ($self,$p0) = @_;
    my $setNewObjectName = JPL::AutoLoader::getmeth('setNewObjectName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setNewObjectName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFilePath {
	## METHOD: java.lang.String getFilePath()
    my $self = shift;
    my $getFilePath = JPL::AutoLoader::getmeth('getFilePath',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFilePath(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultFormat {
	## METHOD: java.lang.String getDefaultFormat()
    my $self = shift;
    my $getDefaultFormat = JPL::AutoLoader::getmeth('getDefaultFormat',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultFormat(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNewObject {
	## METHOD: com.documentum.fc.client.IDfSysObject getNewObject()
    my $self = shift;
    my $getNewObject = JPL::AutoLoader::getmeth('getNewObject',[],['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $$self->$getNewObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSysObject);
        return \$rv;
    }
}

sub setVersionLabels {
	## METHOD: void setVersionLabels(java.lang.String)
    my ($self,$p0) = @_;
    my $setVersionLabels = JPL::AutoLoader::getmeth('setVersionLabels',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVersionLabels($p0); };
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
