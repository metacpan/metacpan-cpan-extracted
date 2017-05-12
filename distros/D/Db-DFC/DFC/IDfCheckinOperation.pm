# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCheckinOperation (com.documentum.operations.IDfCheckinOperation)
# ------------------------------------------------------------------ #

package IDfCheckinOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCheckinOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';

use constant VERSION_NOT_SET => -1;
use constant NEXT_MAJOR => 0;
use constant NEXT_MINOR => 1;
use constant SAME_VERSION => 2;
use constant BRANCH_VERSION => 3;

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
