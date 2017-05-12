# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfOperationNode (com.documentum.operations.IDfOperationNode)
# ------------------------------------------------------------------ #

package IDfOperationNode;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfOperationNode';
use JPL::Class 'com.documentum.operations.IDfOperationNode';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.operations.IDfOperation';
use JPL::Class 'com.documentum.fc.common.IDfProperties';


sub getParent {
	## METHOD: com.documentum.operations.IDfOperationNode getParent()
    my $self = shift;
    my $getParent = JPL::AutoLoader::getmeth('getParent',[],['com.documentum.operations.IDfOperationNode']);
    my $rv = "";
    eval { $rv = $$self->$getParent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfOperationNode);
        return \$rv;
    }
}

sub getProperties {
	## METHOD: com.documentum.fc.common.IDfProperties getProperties()
    my $self = shift;
    my $getProperties = JPL::AutoLoader::getmeth('getProperties',[],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getProperties(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub getId {
	## METHOD: com.documentum.fc.common.IDfId getId()
    my $self = shift;
    my $getId = JPL::AutoLoader::getmeth('getId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getOperation {
	## METHOD: com.documentum.operations.IDfOperation getOperation()
    my $self = shift;
    my $getOperation = JPL::AutoLoader::getmeth('getOperation',[],['com.documentum.operations.IDfOperation']);
    my $rv = "";
    eval { $rv = $$self->$getOperation(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfOperation);
        return \$rv;
    }
}

sub isRoot {
	## METHOD: boolean isRoot()
    my $self = shift;
    my $isRoot = JPL::AutoLoader::getmeth('isRoot',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRoot(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChildren {
	## METHOD: com.documentum.fc.common.IDfList getChildren()
    my $self = shift;
    my $getChildren = JPL::AutoLoader::getmeth('getChildren',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getChildren(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getEdgeProperties {
	## METHOD: com.documentum.fc.common.IDfProperties getEdgeProperties()
    my $self = shift;
    my $getEdgeProperties = JPL::AutoLoader::getmeth('getEdgeProperties',[],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getEdgeProperties(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
