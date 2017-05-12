# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfWorkflowBuilder (com.documentum.fc.client.IDfWorkflowBuilder)
# ------------------------------------------------------------------ #

package IDfWorkflowBuilder;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfWorkflowBuilder';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfProcess';
use JPL::Class 'com.documentum.fc.client.IDfWorkflow';

use constant DF_WB_CAN_START => 0;
use constant DF_WB_UNINSTALLED_PROCESS => 1;
use constant DF_WB_NO_RELATE_PERMISSION => 2;
use constant DF_WB_NO_EXECUTE_PERMISSION => 3;

sub addPackage {
	## METHOD: com.documentum.fc.common.IDfId addPackage(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,boolean,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6) = @_;
    my $addPackage = JPL::AutoLoader::getmeth('addPackage',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','boolean','com.documentum.fc.common.IDfList'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$addPackage($p0,$p1,$p2,$p3,$p4,$p5,$$p6); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub removePackage {
	## METHOD: void removePackage(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $removePackage = JPL::AutoLoader::getmeth('removePackage',['java.lang.String','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePackage($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorkflowAliasSetId {
	## METHOD: com.documentum.fc.common.IDfId getWorkflowAliasSetId()
    my $self = shift;
    my $getWorkflowAliasSetId = JPL::AutoLoader::getmeth('getWorkflowAliasSetId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getWorkflowAliasSetId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getStartStatus {
	## METHOD: int getStartStatus()
    my $self = shift;
    my $getStartStatus = JPL::AutoLoader::getmeth('getStartStatus',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getStartStatus(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub startWorkflow {
	## METHOD: com.documentum.fc.common.IDfId startWorkflow()
    my $self = shift;
    my $startWorkflow = JPL::AutoLoader::getmeth('startWorkflow',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$startWorkflow(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getWorkflow {
	## METHOD: com.documentum.fc.client.IDfWorkflow getWorkflow()
    my $self = shift;
    my $getWorkflow = JPL::AutoLoader::getmeth('getWorkflow',[],['com.documentum.fc.client.IDfWorkflow']);
    my $rv = "";
    eval { $rv = $$self->$getWorkflow(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfWorkflow);
        return \$rv;
    }
}

sub getStartActivityNames {
	## METHOD: com.documentum.fc.common.IDfList getStartActivityNames()
    my $self = shift;
    my $getStartActivityNames = JPL::AutoLoader::getmeth('getStartActivityNames',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getStartActivityNames(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getStartActivityIds {
	## METHOD: com.documentum.fc.common.IDfList getStartActivityIds()
    my $self = shift;
    my $getStartActivityIds = JPL::AutoLoader::getmeth('getStartActivityIds',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getStartActivityIds(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub initWorkflow {
	## METHOD: com.documentum.fc.common.IDfId initWorkflow()
    my $self = shift;
    my $initWorkflow = JPL::AutoLoader::getmeth('initWorkflow',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$initWorkflow(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub runWorkflow {
	## METHOD: com.documentum.fc.common.IDfId runWorkflow()
    my $self = shift;
    my $runWorkflow = JPL::AutoLoader::getmeth('runWorkflow',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$runWorkflow(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getProcess {
	## METHOD: com.documentum.fc.client.IDfProcess getProcess()
    my $self = shift;
    my $getProcess = JPL::AutoLoader::getmeth('getProcess',[],['com.documentum.fc.client.IDfProcess']);
    my $rv = "";
    eval { $rv = $$self->$getProcess(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProcess);
        return \$rv;
    }
}

sub isRunnable {
	## METHOD: boolean isRunnable()
    my $self = shift;
    my $isRunnable = JPL::AutoLoader::getmeth('isRunnable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRunnable(); };
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
