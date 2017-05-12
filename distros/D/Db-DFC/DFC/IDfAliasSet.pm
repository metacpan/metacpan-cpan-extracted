# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfAliasSet (com.documentum.fc.client.IDfAliasSet)
# ------------------------------------------------------------------ #

package IDfAliasSet;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfAliasSet';

use constant CATETORY_UNKNOWN => 0;
use constant CATETORY_USER => 1;
use constant CATETORY_GROUP => 2;
use constant CATETORY_USER_OR_GROUP => 3;
use constant CATETORY_CABINET_PATH => 4;
use constant CATETORY_FOLDER_PATH => 5;
use constant CATETORY_ACL_NAME => 6;

sub getOwnerName {
	## METHOD: java.lang.String getOwnerName()
    my $self = shift;
    my $getOwnerName = JPL::AutoLoader::getmeth('getOwnerName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getOwnerName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOwnerName {
	## METHOD: void setOwnerName(java.lang.String)
    my ($self,$p0) = @_;
    my $setOwnerName = JPL::AutoLoader::getmeth('setOwnerName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOwnerName($p0); };
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

sub removeAllAliases {
	## METHOD: void removeAllAliases()
    my $self = shift;
    my $removeAllAliases = JPL::AutoLoader::getmeth('removeAllAliases',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllAliases(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasDescription {
	## METHOD: java.lang.String getAliasDescription(int)
    my ($self,$p0) = @_;
    my $getAliasDescription = JPL::AutoLoader::getmeth('getAliasDescription',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAliasDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasDescription {
	## METHOD: void setAliasDescription(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setAliasDescription = JPL::AutoLoader::getmeth('setAliasDescription',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasDescription($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasValue {
	## METHOD: java.lang.String getAliasValue(int)
    my ($self,$p0) = @_;
    my $getAliasValue = JPL::AutoLoader::getmeth('getAliasValue',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAliasValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasValue {
	## METHOD: void setAliasValue(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setAliasValue = JPL::AutoLoader::getmeth('setAliasValue',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasValue($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasCategory {
	## METHOD: int getAliasCategory(int)
    my ($self,$p0) = @_;
    my $getAliasCategory = JPL::AutoLoader::getmeth('getAliasCategory',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAliasCategory($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasCategory {
	## METHOD: void setAliasCategory(int,int)
    my ($self,$p0,$p1) = @_;
    my $setAliasCategory = JPL::AutoLoader::getmeth('setAliasCategory',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasCategory($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findAliasIndex {
	## METHOD: int findAliasIndex(java.lang.String)
    my ($self,$p0) = @_;
    my $findAliasIndex = JPL::AutoLoader::getmeth('findAliasIndex',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findAliasIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendAlias {
	## METHOD: int appendAlias(java.lang.String,java.lang.String,int,int,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $appendAlias = JPL::AutoLoader::getmeth('appendAlias',['java.lang.String','java.lang.String','int','int','java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendAlias($p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasCount {
	## METHOD: int getAliasCount()
    my $self = shift;
    my $getAliasCount = JPL::AutoLoader::getmeth('getAliasCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAliasCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectDescription {
	## METHOD: java.lang.String getObjectDescription()
    my $self = shift;
    my $getObjectDescription = JPL::AutoLoader::getmeth('getObjectDescription',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectDescription(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setObjectDescription {
	## METHOD: void setObjectDescription(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectDescription = JPL::AutoLoader::getmeth('setObjectDescription',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setObjectDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasName {
	## METHOD: java.lang.String getAliasName(int)
    my ($self,$p0) = @_;
    my $getAliasName = JPL::AutoLoader::getmeth('getAliasName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAliasName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasName {
	## METHOD: void setAliasName(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setAliasName = JPL::AutoLoader::getmeth('setAliasName',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasName($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasUserCategory {
	## METHOD: int getAliasUserCategory(int)
    my ($self,$p0) = @_;
    my $getAliasUserCategory = JPL::AutoLoader::getmeth('getAliasUserCategory',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAliasUserCategory($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasUserCategory {
	## METHOD: void setAliasUserCategory(int,int)
    my ($self,$p0,$p1) = @_;
    my $setAliasUserCategory = JPL::AutoLoader::getmeth('setAliasUserCategory',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasUserCategory($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAlias {
	## METHOD: void removeAlias(java.lang.String)
    my ($self,$p0) = @_;
    my $removeAlias = JPL::AutoLoader::getmeth('removeAlias',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAlias($p0); };
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
