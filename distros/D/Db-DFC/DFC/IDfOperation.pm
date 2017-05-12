# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfOperation (com.documentum.operations.IDfOperation)
# ------------------------------------------------------------------ #

package IDfOperation;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfOperation';
use JPL::Class 'com.documentum.operations.IDfOperationNode';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.operations.IDfOperationMonitor';
use JPL::Class 'com.documentum.fc.common.IDfProperties';


sub getName {
	## METHOD: java.lang.String getName()
    my $self = shift;
    my $getName = JPL::AutoLoader::getmeth('getName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub add {
	## METHOD: com.documentum.operations.IDfOperationNode add(java.lang.Object)
    my ($self,$p0) = @_;
    my $add = JPL::AutoLoader::getmeth('add',['java.lang.Object'],['com.documentum.operations.IDfOperationNode']);
    my $rv = "";
    eval { $rv = $$self->$add($p0); };
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

sub execute {
	## METHOD: boolean execute()
    my $self = shift;
    my $execute = JPL::AutoLoader::getmeth('execute',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$execute(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeNode {
	## METHOD: void removeNode(com.documentum.operations.IDfOperationNode)
    my ($self,$p0) = @_;
    my $removeNode = JPL::AutoLoader::getmeth('removeNode',['com.documentum.operations.IDfOperationNode'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeNode($$p0); };
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

sub succeeded {
	## METHOD: boolean succeeded(java.lang.Object)
    my ($self,$p0) = @_;
    my $succeeded = JPL::AutoLoader::getmeth('succeeded',['java.lang.Object'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$succeeded($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getOperationType {
	## METHOD: java.lang.String getOperationType()
    my $self = shift;
    my $getOperationType = JPL::AutoLoader::getmeth('getOperationType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getOperationType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub reportError {
	## METHOD: void reportError(com.documentum.operations.IDfOperationNode,int,java.lang.String,com.documentum.fc.common.IDfException)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $reportError = JPL::AutoLoader::getmeth('reportError',['com.documentum.operations.IDfOperationNode','int','java.lang.String','com.documentum.fc.common.IDfException'],[]);
    my $rv = "";
    eval { $rv = $$self->$reportError($$p0,$p1,$p2,$$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getErrors {
	## METHOD: com.documentum.fc.common.IDfList getErrors()
    my $self = shift;
    my $getErrors = JPL::AutoLoader::getmeth('getErrors',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getErrors(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub resetErrors {
	## METHOD: void resetErrors()
    my $self = shift;
    my $resetErrors = JPL::AutoLoader::getmeth('resetErrors',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resetErrors(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub logError {
	## METHOD: void logError(com.documentum.operations.IDfOperationError)
    my ($self,$p0) = @_;
    my $logError = JPL::AutoLoader::getmeth('logError',['com.documentum.operations.IDfOperationError'],[]);
    my $rv = "";
    eval { $rv = $$self->$logError($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOperationMonitor {
	## METHOD: com.documentum.operations.IDfOperationMonitor setOperationMonitor(com.documentum.operations.IDfOperationMonitor)
    my ($self,$p0) = @_;
    my $setOperationMonitor = JPL::AutoLoader::getmeth('setOperationMonitor',['com.documentum.operations.IDfOperationMonitor'],['com.documentum.operations.IDfOperationMonitor']);
    my $rv = "";
    eval { $rv = $$self->$setOperationMonitor($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfOperationMonitor);
        return \$rv;
    }
}

sub abort {
	## METHOD: void abort()
    my $self = shift;
    my $abort = JPL::AutoLoader::getmeth('abort',[],[]);
    my $rv = "";
    eval { $rv = $$self->$abort(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRootNodes {
	## METHOD: com.documentum.fc.common.IDfList getRootNodes()
    my $self = shift;
    my $getRootNodes = JPL::AutoLoader::getmeth('getRootNodes',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getRootNodes(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getNodes {
	## METHOD: com.documentum.fc.common.IDfList getNodes()
    my $self = shift;
    my $getNodes = JPL::AutoLoader::getmeth('getNodes',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getNodes(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getSteps {
	## METHOD: com.documentum.fc.common.IDfList getSteps()
    my $self = shift;
    my $getSteps = JPL::AutoLoader::getmeth('getSteps',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getSteps(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
