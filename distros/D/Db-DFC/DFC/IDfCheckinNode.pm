# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCheckinNode (com.documentum.operations.IDfCheckinNode)
# ------------------------------------------------------------------ #

package IDfCheckinNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCheckinNode';
use JPL::Class 'com.documentum.fc.client.IDfSysObject';
use JPL::Class 'com.documentum.fc.common.IDfId';


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

sub getCheckinVersion {
	## METHOD: int getCheckinVersion()
    my $self = shift;
    my $getCheckinVersion = JPL::AutoLoader::getmeth('getCheckinVersion',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCheckinVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setCheckinVersion {
	## METHOD: void setCheckinVersion(int)
    my ($self,$p0) = @_;
    my $setCheckinVersion = JPL::AutoLoader::getmeth('setCheckinVersion',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setCheckinVersion($p0); };
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

sub getRetainLock {
	## METHOD: boolean getRetainLock()
    my $self = shift;
    my $getRetainLock = JPL::AutoLoader::getmeth('getRetainLock',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getRetainLock(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRetainLock {
	## METHOD: void setRetainLock(boolean)
    my ($self,$p0) = @_;
    my $setRetainLock = JPL::AutoLoader::getmeth('setRetainLock',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRetainLock($p0); };
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

sub getContentPageNumber {
	## METHOD: int getContentPageNumber()
    my $self = shift;
    my $getContentPageNumber = JPL::AutoLoader::getmeth('getContentPageNumber',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getContentPageNumber(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setContentPageNumber {
	## METHOD: void setContentPageNumber(int)
    my ($self,$p0) = @_;
    my $setContentPageNumber = JPL::AutoLoader::getmeth('setContentPageNumber',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setContentPageNumber($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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
