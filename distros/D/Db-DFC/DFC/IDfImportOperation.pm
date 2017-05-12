# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfImportOperation (com.documentum.operations.IDfImportOperation)
# ------------------------------------------------------------------ #

package IDfImportOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfImportOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfSession';


sub getSession {
	## METHOD: com.documentum.fc.client.IDfSession getSession()
    my $self = shift;
    my $getSession = JPL::AutoLoader::getmeth('getSession',[],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$getSession(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
    }
}

sub setSession {
	## METHOD: void setSession(com.documentum.fc.client.IDfSession)
    my ($self,$p0) = @_;
    my $setSession = JPL::AutoLoader::getmeth('setSession',['com.documentum.fc.client.IDfSession'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSession($$p0); };
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
