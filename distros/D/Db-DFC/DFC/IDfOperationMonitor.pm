# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfOperationMonitor (com.documentum.operations.IDfOperationMonitor)
# ------------------------------------------------------------------ #

package IDfOperationMonitor;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfOperationMonitor';

use constant ABORT => -1;
use constant CONTINUE => 1;
use constant YES => 1;
use constant NO => 0;

sub reportError {
	## METHOD: int reportError(com.documentum.operations.IDfOperationError)
    my ($self,$p0) = @_;
    my $reportError = JPL::AutoLoader::getmeth('reportError',['com.documentum.operations.IDfOperationError'],['int']);
    my $rv = "";
    eval { $rv = $$self->$reportError($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub progressReport {
	## METHOD: int progressReport(com.documentum.operations.IDfOperation,int,com.documentum.operations.IDfOperationStep,int,com.documentum.operations.IDfOperationNode)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $progressReport = JPL::AutoLoader::getmeth('progressReport',['com.documentum.operations.IDfOperation','int','com.documentum.operations.IDfOperationStep','int','com.documentum.operations.IDfOperationNode'],['int']);
    my $rv = "";
    eval { $rv = $$self->$progressReport($$p0,$p1,$$p2,$p3,$$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getYesNoAnswer {
	## METHOD: int getYesNoAnswer(com.documentum.operations.IDfOperationError)
    my ($self,$p0) = @_;
    my $getYesNoAnswer = JPL::AutoLoader::getmeth('getYesNoAnswer',['com.documentum.operations.IDfOperationError'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getYesNoAnswer($$p0); };
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
