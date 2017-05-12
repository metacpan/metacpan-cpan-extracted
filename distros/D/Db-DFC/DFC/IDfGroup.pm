# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfGroup (com.documentum.fc.client.IDfGroup)
# ------------------------------------------------------------------ #

package IDfGroup;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfGroup';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


sub isPrivate {
	## METHOD: boolean isPrivate()
    my $self = shift;
    my $isPrivate = JPL::AutoLoader::getmeth('isPrivate',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isPrivate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasSetId {
	## METHOD: com.documentum.fc.common.IDfId getAliasSetId()
    my $self = shift;
    my $getAliasSetId = JPL::AutoLoader::getmeth('getAliasSetId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAliasSetId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

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

sub getModifyDate {
	## METHOD: com.documentum.fc.common.IDfTime getModifyDate()
    my $self = shift;
    my $getModifyDate = JPL::AutoLoader::getmeth('getModifyDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getModifyDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getGroupName {
	## METHOD: java.lang.String getGroupName()
    my $self = shift;
    my $getGroupName = JPL::AutoLoader::getmeth('getGroupName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getGroupName(); };
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

sub getAllUsersNamesCount {
	## METHOD: int getAllUsersNamesCount()
    my $self = shift;
    my $getAllUsersNamesCount = JPL::AutoLoader::getmeth('getAllUsersNamesCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAllUsersNamesCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAllUsersNames {
	## METHOD: java.lang.String getAllUsersNames(int)
    my ($self,$p0) = @_;
    my $getAllUsersNames = JPL::AutoLoader::getmeth('getAllUsersNames',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAllUsersNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupAddress {
	## METHOD: java.lang.String getGroupAddress()
    my $self = shift;
    my $getGroupAddress = JPL::AutoLoader::getmeth('getGroupAddress',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getGroupAddress(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAliasSetId {
	## METHOD: void setAliasSetId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setAliasSetId = JPL::AutoLoader::getmeth('setAliasSetId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAliasSetId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUsersNames {
	## METHOD: java.lang.String getUsersNames(int)
    my ($self,$p0) = @_;
    my $getUsersNames = JPL::AutoLoader::getmeth('getUsersNames',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUsersNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupsNames {
	## METHOD: java.lang.String getGroupsNames(int)
    my ($self,$p0) = @_;
    my $getGroupsNames = JPL::AutoLoader::getmeth('getGroupsNames',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getGroupsNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUsersNamesCount {
	## METHOD: int getUsersNamesCount()
    my $self = shift;
    my $getUsersNamesCount = JPL::AutoLoader::getmeth('getUsersNamesCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getUsersNamesCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupsNamesCount {
	## METHOD: int getGroupsNamesCount()
    my $self = shift;
    my $getGroupsNamesCount = JPL::AutoLoader::getmeth('getGroupsNamesCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getGroupsNamesCount(); };
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
