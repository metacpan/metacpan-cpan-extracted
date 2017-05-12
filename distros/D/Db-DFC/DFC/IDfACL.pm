# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfACL (com.documentum.fc.client.IDfACL)
# ------------------------------------------------------------------ #

package IDfACL;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfACL';

use constant DF_PERMIT_NONE => 1;
use constant DF_PERMIT_BROWSE => 2;
use constant DF_PERMIT_READ => 3;
use constant DF_PERMIT_NOTE => 4;
use constant DF_PERMIT_RELATE => 4;
use constant DF_PERMIT_VERSION => 5;
use constant DF_PERMIT_WRITE => 6;
use constant DF_PERMIT_DELETE => 7;

sub getDomain {
	## METHOD: java.lang.String getDomain()
    my $self = shift;
    my $getDomain = JPL::AutoLoader::getmeth('getDomain',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDomain(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDomain {
	## METHOD: void setDomain(java.lang.String)
    my ($self,$p0) = @_;
    my $setDomain = JPL::AutoLoader::getmeth('setDomain',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDomain($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermitList {
	## METHOD: java.lang.String getXPermitList()
    my $self = shift;
    my $getXPermitList = JPL::AutoLoader::getmeth('getXPermitList',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getXPermitList(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorCount {
	## METHOD: int getAccessorCount()
    my $self = shift;
    my $getAccessorCount = JPL::AutoLoader::getmeth('getAccessorCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub revoke {
	## METHOD: void revoke(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $revoke = JPL::AutoLoader::getmeth('revoke',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$revoke($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorName {
	## METHOD: java.lang.String getAccessorName(int)
    my ($self,$p0) = @_;
    my $getAccessorName = JPL::AutoLoader::getmeth('getAccessorName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasPermission {
	## METHOD: boolean hasPermission(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $hasPermission = JPL::AutoLoader::getmeth('hasPermission',['java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasPermission($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPermit {
	## METHOD: int getPermit(java.lang.String)
    my ($self,$p0) = @_;
    my $getPermit = JPL::AutoLoader::getmeth('getPermit',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorPermit {
	## METHOD: int getAccessorPermit(int)
    my ($self,$p0) = @_;
    my $getAccessorPermit = JPL::AutoLoader::getmeth('getAccessorPermit',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermit {
	## METHOD: int getXPermit(java.lang.String)
    my ($self,$p0) = @_;
    my $getXPermit = JPL::AutoLoader::getmeth('getXPermit',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getXPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorXPermit {
	## METHOD: int getAccessorXPermit(int)
    my ($self,$p0) = @_;
    my $getAccessorXPermit = JPL::AutoLoader::getmeth('getAccessorXPermit',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorXPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectName {
	## METHOD: java.lang.String getObjectName()
    my $self = shift;
    my $getObjectName = JPL::AutoLoader::getmeth('getObjectName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setObjectName {
	## METHOD: void setObjectName(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectName = JPL::AutoLoader::getmeth('setObjectName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setObjectName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub grant {
	## METHOD: void grant(java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $grant = JPL::AutoLoader::getmeth('grant',['java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$grant($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorXPermitNames {
	## METHOD: java.lang.String getAccessorXPermitNames(int)
    my ($self,$p0) = @_;
    my $getAccessorXPermitNames = JPL::AutoLoader::getmeth('getAccessorXPermitNames',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorXPermitNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermitNames {
	## METHOD: java.lang.String getXPermitNames(java.lang.String)
    my ($self,$p0) = @_;
    my $getXPermitNames = JPL::AutoLoader::getmeth('getXPermitNames',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getXPermitNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDescription {
	## METHOD: java.lang.String getDescription()
    my $self = shift;
    my $getDescription = JPL::AutoLoader::getmeth('getDescription',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDescription(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDescription {
	## METHOD: void setDescription(java.lang.String)
    my ($self,$p0) = @_;
    my $setDescription = JPL::AutoLoader::getmeth('setDescription',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isGroup {
	## METHOD: boolean isGroup(int)
    my ($self,$p0) = @_;
    my $isGroup = JPL::AutoLoader::getmeth('isGroup',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isGroup($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isGloballyManaged {
	## METHOD: boolean isGloballyManaged()
    my $self = shift;
    my $isGloballyManaged = JPL::AutoLoader::getmeth('isGloballyManaged',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isGloballyManaged(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isInternal {
	## METHOD: boolean isInternal()
    my $self = shift;
    my $isInternal = JPL::AutoLoader::getmeth('isInternal',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isInternal(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getACLClass {
	## METHOD: int getACLClass()
    my $self = shift;
    my $getACLClass = JPL::AutoLoader::getmeth('getACLClass',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getACLClass(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setACLClass {
	## METHOD: void setACLClass(int)
    my ($self,$p0) = @_;
    my $setACLClass = JPL::AutoLoader::getmeth('setACLClass',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setACLClass($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub destroyACL {
	## METHOD: void destroyACL(boolean)
    my ($self,$p0) = @_;
    my $destroyACL = JPL::AutoLoader::getmeth('destroyACL',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$destroyACL($p0); };
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
