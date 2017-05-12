# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfContainment (com.documentum.fc.client.IDfContainment)
# ------------------------------------------------------------------ #

package IDfContainment;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfContainment';
use JPL::Class 'com.documentum.fc.common.IDfId';


sub getFollowAssembly {
	## METHOD: boolean getFollowAssembly()
    my $self = shift;
    my $getFollowAssembly = JPL::AutoLoader::getmeth('getFollowAssembly',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFollowAssembly(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCopyBehavior {
	## METHOD: int getCopyBehavior()
    my $self = shift;
    my $getCopyBehavior = JPL::AutoLoader::getmeth('getCopyBehavior',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCopyBehavior(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getComponentId {
	## METHOD: com.documentum.fc.common.IDfId getComponentId()
    my $self = shift;
    my $getComponentId = JPL::AutoLoader::getmeth('getComponentId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getComponentId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getVersionLabel {
	## METHOD: java.lang.String getVersionLabel()
    my $self = shift;
    my $getVersionLabel = JPL::AutoLoader::getmeth('getVersionLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getParentId {
	## METHOD: com.documentum.fc.common.IDfId getParentId()
    my $self = shift;
    my $getParentId = JPL::AutoLoader::getmeth('getParentId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getParentId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getOrderNumber {
	## METHOD: double getOrderNumber()
    my $self = shift;
    my $getOrderNumber = JPL::AutoLoader::getmeth('getOrderNumber',[],['double']);
    my $rv = "";
    eval { $rv = $$self->$getOrderNumber(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUseNodeVerLabel {
	## METHOD: boolean getUseNodeVerLabel()
    my $self = shift;
    my $getUseNodeVerLabel = JPL::AutoLoader::getmeth('getUseNodeVerLabel',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getUseNodeVerLabel(); };
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
