# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfId (com.documentum.fc.common.IDfId)
# ------------------------------------------------------------------ #

package IDfId;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfId';

use constant DM_SESSION => 1;
use constant DM_OBJECT => 2;
use constant DM_TYPE => 3;
use constant DM_CONTAINMENT => 5;
use constant DM_CONTENT => 6;
use constant DM_SYSOBJECT => 8;
use constant DM_DOCUMENT => 9;
use constant DM_QUERY => 10;
use constant DM_FOLDER => 11;
use constant DM_CABINET => 12;
use constant DM_ASSEMBLY => 13;
use constant DM_STORE => 14;
use constant DM_METHOD => 16;
use constant DM_USER => 17;
use constant DM_GROUP => 18;
use constant DM_OUTPUTDEVICE => 23;
use constant DM_ROUTER => 24;
use constant DM_REGISTERED => 25;
use constant DM_QUEUE_ITEM => 27;
use constant DM_PARTITION => 28;
use constant DM_EVENT => 29;
use constant DM_INDEX => 31;
use constant DM_SEQUENCE => 32;
use constant DM_REGISTRY => 38;
use constant DM_FORMAT => 39;
use constant DM_FILESTORE => 40;
use constant DM_NETSTORE => 41;
use constant DM_LINKEDSTORE => 42;
use constant DM_LINKRECORD => 43;
use constant DM_DISTRIBUTEDSTORE => 44;
use constant DM_REPLICA_RECORD => 45;
use constant DM_TYPE_INFO => 46;
use constant DM_DUMP_RECORD => 47;
use constant DM_DUMP_OBJECT_RECORD => 48;
use constant DM_LOAD_RECORD => 49;
use constant DM_LOAD_OBJECT_RECORD => 50;
use constant DM_CHANGE_RECORD => 51;
use constant DM_DIST_COMP_RECORD => 54;
use constant DM_RELATION => 55;
use constant DM_RELATIONTYPE => 56;
use constant DM_LOCATION => 58;
use constant DM_FULLTEXT_INDEX => 59;
use constant DM_DOCBASE_CONFIG => 60;
use constant DM_SERVER_CONFIG => 61;
use constant DM_DOCBROKER => 63;
use constant DM_BLOBSTORE => 64;
use constant DM_NOTE => 65;
use constant DM_REMOTESTORE => 66;
use constant DM_DOCBASEID_MAP => 68;
use constant DM_ACL => 69;
use constant DM_POLICY => 70;
use constant DM_PROCESS => 75;
use constant DM_ACTIVITY => 76;
use constant DM_WORKFLOW => 77;
use constant DM_WORKITEM => 74;
use constant DMI_PACKAGE => 73;

sub compareTo {
	## METHOD: int compareTo(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $compareTo = JPL::AutoLoader::getmeth('compareTo',['com.documentum.fc.common.IDfId'],['int']);
    my $rv = "";
    eval { $rv = $$self->$compareTo($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub equals {
	## METHOD: boolean equals(java.lang.Object)
    my ($self,$p0) = @_;
    my $equals = JPL::AutoLoader::getmeth('equals',['java.lang.Object'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$equals($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString()
    my $self = shift;
    my $toString = JPL::AutoLoader::getmeth('toString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getId {
	## METHOD: java.lang.String getId()
    my $self = shift;
    my $getId = JPL::AutoLoader::getmeth('getId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseId {
	## METHOD: java.lang.String getDocbaseId()
    my $self = shift;
    my $getDocbaseId = JPL::AutoLoader::getmeth('getDocbaseId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypePart {
	## METHOD: int getTypePart()
    my $self = shift;
    my $getTypePart = JPL::AutoLoader::getmeth('getTypePart',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypePart(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isNull {
	## METHOD: boolean isNull()
    my $self = shift;
    my $isNull = JPL::AutoLoader::getmeth('isNull',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNull(); };
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
