# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfUser (com.documentum.fc.client.IDfUser)
# ------------------------------------------------------------------ #

package IDfUser;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfUser';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


sub getAliasSet {
	## METHOD: java.lang.String getAliasSet()
    my $self = shift;
    my $getAliasSet = JPL::AutoLoader::getmeth('getAliasSet',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAliasSet(); };
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

sub getACLName {
	## METHOD: java.lang.String getACLName()
    my $self = shift;
    my $getACLName = JPL::AutoLoader::getmeth('getACLName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getACLName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getACLDomain {
	## METHOD: java.lang.String getACLDomain()
    my $self = shift;
    my $getACLDomain = JPL::AutoLoader::getmeth('getACLDomain',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getACLDomain(); };
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

sub isGroup {
	## METHOD: boolean isGroup()
    my $self = shift;
    my $isGroup = JPL::AutoLoader::getmeth('isGroup',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isGroup(); };
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

sub isWorkflowDisabled {
	## METHOD: boolean isWorkflowDisabled()
    my $self = shift;
    my $isWorkflowDisabled = JPL::AutoLoader::getmeth('isWorkflowDisabled',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isWorkflowDisabled(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserOSName {
	## METHOD: java.lang.String getUserOSName()
    my $self = shift;
    my $getUserOSName = JPL::AutoLoader::getmeth('getUserOSName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserOSName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSuperUser {
	## METHOD: boolean isSuperUser()
    my $self = shift;
    my $isSuperUser = JPL::AutoLoader::getmeth('isSuperUser',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSuperUser(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultFolder {
	## METHOD: java.lang.String getDefaultFolder()
    my $self = shift;
    my $getDefaultFolder = JPL::AutoLoader::getmeth('getDefaultFolder',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultFolder(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserDelegation {
	## METHOD: java.lang.String getUserDelegation()
    my $self = shift;
    my $getUserDelegation = JPL::AutoLoader::getmeth('getUserDelegation',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserDelegation(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSystemAdmin {
	## METHOD: boolean isSystemAdmin()
    my $self = shift;
    my $isSystemAdmin = JPL::AutoLoader::getmeth('isSystemAdmin',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSystemAdmin(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorldDefPermit {
	## METHOD: int getWorldDefPermit()
    my $self = shift;
    my $getWorldDefPermit = JPL::AutoLoader::getmeth('getWorldDefPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getWorldDefPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserOSDomain {
	## METHOD: java.lang.String getUserOSDomain()
    my $self = shift;
    my $getUserOSDomain = JPL::AutoLoader::getmeth('getUserOSDomain',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserOSDomain(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserState {
	## METHOD: int getUserState()
    my $self = shift;
    my $getUserState = JPL::AutoLoader::getmeth('getUserState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getUserState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserAddress {
	## METHOD: java.lang.String getUserAddress()
    my $self = shift;
    my $getUserAddress = JPL::AutoLoader::getmeth('getUserAddress',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserAddress(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserGroupName {
	## METHOD: java.lang.String getUserGroupName()
    my $self = shift;
    my $getUserGroupName = JPL::AutoLoader::getmeth('getUserGroupName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserGroupName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHomeDocbase {
	## METHOD: java.lang.String getHomeDocbase()
    my $self = shift;
    my $getHomeDocbase = JPL::AutoLoader::getmeth('getHomeDocbase',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getHomeDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getOwnerDefPermit {
	## METHOD: int getOwnerDefPermit()
    my $self = shift;
    my $getOwnerDefPermit = JPL::AutoLoader::getmeth('getOwnerDefPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getOwnerDefPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserPrivileges {
	## METHOD: int getUserPrivileges()
    my $self = shift;
    my $getUserPrivileges = JPL::AutoLoader::getmeth('getUserPrivileges',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getUserPrivileges(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserDBName {
	## METHOD: java.lang.String getUserDBName()
    my $self = shift;
    my $getUserDBName = JPL::AutoLoader::getmeth('getUserDBName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserDBName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupDefPermit {
	## METHOD: int getGroupDefPermit()
    my $self = shift;
    my $getGroupDefPermit = JPL::AutoLoader::getmeth('getGroupDefPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getGroupDefPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getClientCapability {
	## METHOD: int getClientCapability()
    my $self = shift;
    my $getClientCapability = JPL::AutoLoader::getmeth('getClientCapability',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getClientCapability(); };
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


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
