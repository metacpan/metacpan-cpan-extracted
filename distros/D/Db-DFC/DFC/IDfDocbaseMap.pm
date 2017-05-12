# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfDocbaseMap (com.documentum.fc.client.IDfDocbaseMap)
# ------------------------------------------------------------------ #

package IDfDocbaseMap;
@ISA = (IDfTypedObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfDocbaseMap';
use JPL::Class 'com.documentum.fc.client.IDfTypedObject';


sub getDocbaseId {
	## METHOD: java.lang.String getDocbaseId(int)
    my ($self,$p0) = @_;
    my $getDocbaseId = JPL::AutoLoader::getmeth('getDocbaseId',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseName {
	## METHOD: java.lang.String getDocbaseName(int)
    my ($self,$p0) = @_;
    my $getDocbaseName = JPL::AutoLoader::getmeth('getDocbaseName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getServerVersion {
	## METHOD: java.lang.String getServerVersion(int)
    my ($self,$p0) = @_;
    my $getServerVersion = JPL::AutoLoader::getmeth('getServerVersion',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getServerVersion($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getServerMap {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerMap(int)
    my ($self,$p0) = @_;
    my $getServerMap = JPL::AutoLoader::getmeth('getServerMap',['int'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerMap($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getDocbaseCount {
	## METHOD: int getDocbaseCount()
    my $self = shift;
    my $getDocbaseCount = JPL::AutoLoader::getmeth('getDocbaseCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseDescription {
	## METHOD: java.lang.String getDocbaseDescription(int)
    my ($self,$p0) = @_;
    my $getDocbaseDescription = JPL::AutoLoader::getmeth('getDocbaseDescription',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getServerMapByName {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerMapByName(java.lang.String)
    my ($self,$p0) = @_;
    my $getServerMapByName = JPL::AutoLoader::getmeth('getServerMapByName',['java.lang.String'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerMapByName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getHostName {
	## METHOD: java.lang.String getHostName()
    my $self = shift;
    my $getHostName = JPL::AutoLoader::getmeth('getHostName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getHostName(); };
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
