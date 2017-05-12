# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCopyOperation (com.documentum.operations.IDfCopyOperation)
# ------------------------------------------------------------------ #

package IDfCopyOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCopyOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';

use constant COPY_UNSPECIFIED => 0;
use constant COPY_REFERENCE => 1;
use constant COPY_COPY => 2;
use constant COPY_OPTION_PERFORM_MOVE => 1;
use constant COPY_OPTION_DONT_MARK_SYMBOLIC_LABELS => 2;
use constant COPY_OPTIONS_PERFORM_MOVE_AND_DONT_MARK_SYMOLIC_LABELS => 3;

sub getCopyOptionsFlag {
	## METHOD: int getCopyOptionsFlag()
    my $self = shift;
    my $getCopyOptionsFlag = JPL::AutoLoader::getmeth('getCopyOptionsFlag',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCopyOptionsFlag(); };
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

sub getCopyPreference {
	## METHOD: int getCopyPreference()
    my $self = shift;
    my $getCopyPreference = JPL::AutoLoader::getmeth('getCopyPreference',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCopyPreference(); };
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

sub getNewObjects {
	## METHOD: com.documentum.fc.common.IDfList getNewObjects()
    my $self = shift;
    my $getNewObjects = JPL::AutoLoader::getmeth('getNewObjects',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getNewObjects(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getDeepFolders {
	## METHOD: boolean getDeepFolders()
    my $self = shift;
    my $getDeepFolders = JPL::AutoLoader::getmeth('getDeepFolders',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getDeepFolders(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDeepFolders {
	## METHOD: void setDeepFolders(boolean)
    my ($self,$p0) = @_;
    my $setDeepFolders = JPL::AutoLoader::getmeth('setDeepFolders',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDeepFolders($p0); };
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
