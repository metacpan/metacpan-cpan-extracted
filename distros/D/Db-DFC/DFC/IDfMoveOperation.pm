# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfMoveOperation (com.documentum.operations.IDfMoveOperation)
# ------------------------------------------------------------------ #

package IDfMoveOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfMoveOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';


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

sub getObjects {
	## METHOD: com.documentum.fc.common.IDfList getObjects()
    my $self = shift;
    my $getObjects = JPL::AutoLoader::getmeth('getObjects',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getObjects(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
