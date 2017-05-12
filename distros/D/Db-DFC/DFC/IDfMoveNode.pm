# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfMoveNode (com.documentum.operations.IDfMoveNode)
# ------------------------------------------------------------------ #

package IDfMoveNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfMoveNode';
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

sub getSourceFolderId {
	## METHOD: com.documentum.fc.common.IDfId getSourceFolderId()
    my $self = shift;
    my $getSourceFolderId = JPL::AutoLoader::getmeth('getSourceFolderId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getSourceFolderId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setSourceFolderId {
	## METHOD: void setSourceFolderId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setSourceFolderId = JPL::AutoLoader::getmeth('setSourceFolderId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSourceFolderId($$p0); };
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
