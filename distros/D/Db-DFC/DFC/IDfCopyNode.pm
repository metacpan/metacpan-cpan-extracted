# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCopyNode (com.documentum.operations.IDfCopyNode)
# ------------------------------------------------------------------ #

package IDfCopyNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCopyNode';
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


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
