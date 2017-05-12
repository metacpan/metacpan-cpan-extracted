# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryLocation (com.documentum.fc.client.qb.IDfQueryLocation)
# ------------------------------------------------------------------ #

package IDfQueryLocation;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryLocation';
use JPL::Class 'com.documentum.fc.client.IDfSession';

use constant PATH => "DC_PATH";
use constant FOLDERID => "DC_FOLDERID";
use constant VDOC => "DC_VDOC";
use constant ASSEMBLY => "DC_ASSEMBLY";

sub getPath {
	## METHOD: java.lang.String getPath()
    my $self = shift;
    my $getPath = JPL::AutoLoader::getmeth('getPath',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPath(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

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

sub setPath {
	## METHOD: void setPath(java.lang.String)
    my ($self,$p0) = @_;
    my $setPath = JPL::AutoLoader::getmeth('setPath',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectId {
	## METHOD: java.lang.String getObjectId()
    my $self = shift;
    my $getObjectId = JPL::AutoLoader::getmeth('getObjectId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserName {
	## METHOD: java.lang.String getUserName()
    my $self = shift;
    my $getUserName = JPL::AutoLoader::getmeth('getUserName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setLocationType {
	## METHOD: void setLocationType(java.lang.String)
    my ($self,$p0) = @_;
    my $setLocationType = JPL::AutoLoader::getmeth('setLocationType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setLocationType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setObjectId {
	## METHOD: void setObjectId(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectId = JPL::AutoLoader::getmeth('setObjectId',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setObjectId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDescend {
	## METHOD: void setDescend(boolean)
    my ($self,$p0) = @_;
    my $setDescend = JPL::AutoLoader::getmeth('setDescend',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDescend($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDocbaseName {
	## METHOD: void setDocbaseName(java.lang.String)
    my ($self,$p0) = @_;
    my $setDocbaseName = JPL::AutoLoader::getmeth('setDocbaseName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDocbaseName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isUsedIn {
	## METHOD: boolean isUsedIn()
    my $self = shift;
    my $isUsedIn = JPL::AutoLoader::getmeth('isUsedIn',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isUsedIn(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isVirtual {
	## METHOD: boolean isVirtual()
    my $self = shift;
    my $isVirtual = JPL::AutoLoader::getmeth('isVirtual',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isVirtual(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRootVersion {
	## METHOD: java.lang.String getRootVersion()
    my $self = shift;
    my $getRootVersion = JPL::AutoLoader::getmeth('getRootVersion',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getRootVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isDescend {
	## METHOD: boolean isDescend()
    my $self = shift;
    my $isDescend = JPL::AutoLoader::getmeth('isDescend',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDescend(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFloatVersion {
	## METHOD: java.lang.String getFloatVersion()
    my $self = shift;
    my $getFloatVersion = JPL::AutoLoader::getmeth('getFloatVersion',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFloatVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isAssembly {
	## METHOD: boolean isAssembly()
    my $self = shift;
    my $isAssembly = JPL::AutoLoader::getmeth('isAssembly',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isAssembly(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isPath {
	## METHOD: boolean isPath()
    my $self = shift;
    my $isPath = JPL::AutoLoader::getmeth('isPath',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isPath(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isFolder {
	## METHOD: boolean isFolder()
    my $self = shift;
    my $isFolder = JPL::AutoLoader::getmeth('isFolder',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isFolder(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLocationType {
	## METHOD: java.lang.String getLocationType()
    my $self = shift;
    my $getLocationType = JPL::AutoLoader::getmeth('getLocationType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLocationType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRootVersion {
	## METHOD: void setRootVersion(java.lang.String)
    my ($self,$p0) = @_;
    my $setRootVersion = JPL::AutoLoader::getmeth('setRootVersion',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRootVersion($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFloatVersion {
	## METHOD: void setFloatVersion(java.lang.String)
    my ($self,$p0) = @_;
    my $setFloatVersion = JPL::AutoLoader::getmeth('setFloatVersion',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFloatVersion($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setEditable {
	## METHOD: void setEditable(boolean)
    my ($self,$p0) = @_;
    my $setEditable = JPL::AutoLoader::getmeth('setEditable',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setEditable($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setUserName {
	## METHOD: void setUserName(java.lang.String)
    my ($self,$p0) = @_;
    my $setUserName = JPL::AutoLoader::getmeth('setUserName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setUserName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isEditable {
	## METHOD: boolean isEditable()
    my $self = shift;
    my $isEditable = JPL::AutoLoader::getmeth('isEditable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isEditable(); };
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
