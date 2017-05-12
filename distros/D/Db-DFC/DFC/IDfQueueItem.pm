# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueueItem (com.documentum.fc.client.IDfQueueItem)
# ------------------------------------------------------------------ #

package IDfQueueItem;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfQueueItem';
use JPL::Class 'com.documentum.fc.client.IDfWorkitem';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


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

sub getMessage {
	## METHOD: java.lang.String getMessage()
    my $self = shift;
    my $getMessage = JPL::AutoLoader::getmeth('getMessage',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMessage(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPriority {
	## METHOD: int getPriority()
    my $self = shift;
    my $getPriority = JPL::AutoLoader::getmeth('getPriority',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPriority(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContentType {
	## METHOD: java.lang.String getContentType()
    my $self = shift;
    my $getContentType = JPL::AutoLoader::getmeth('getContentType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getContentType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDueDate {
	## METHOD: com.documentum.fc.common.IDfTime getDueDate()
    my $self = shift;
    my $getDueDate = JPL::AutoLoader::getmeth('getDueDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getDueDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getSignOffDate {
	## METHOD: com.documentum.fc.common.IDfTime getSignOffDate()
    my $self = shift;
    my $getSignOffDate = JPL::AutoLoader::getmeth('getSignOffDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getSignOffDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isSignOffRequired {
	## METHOD: boolean isSignOffRequired()
    my $self = shift;
    my $isSignOffRequired = JPL::AutoLoader::getmeth('isSignOffRequired',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSignOffRequired(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorkitem {
	## METHOD: com.documentum.fc.client.IDfWorkitem getWorkitem()
    my $self = shift;
    my $getWorkitem = JPL::AutoLoader::getmeth('getWorkitem',[],['com.documentum.fc.client.IDfWorkitem']);
    my $rv = "";
    eval { $rv = $$self->$getWorkitem(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfWorkitem);
        return \$rv;
    }
}

sub getItemId {
	## METHOD: com.documentum.fc.common.IDfId getItemId()
    my $self = shift;
    my $getItemId = JPL::AutoLoader::getmeth('getItemId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getItemId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getSupervisorName {
	## METHOD: java.lang.String getSupervisorName()
    my $self = shift;
    my $getSupervisorName = JPL::AutoLoader::getmeth('getSupervisorName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSupervisorName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getItemType {
	## METHOD: java.lang.String getItemType()
    my $self = shift;
    my $getItemType = JPL::AutoLoader::getmeth('getItemType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getItemType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTaskType {
	## METHOD: java.lang.String getTaskType()
    my $self = shift;
    my $getTaskType = JPL::AutoLoader::getmeth('getTaskType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTaskType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDependencyType {
	## METHOD: java.lang.String getDependencyType()
    my $self = shift;
    my $getDependencyType = JPL::AutoLoader::getmeth('getDependencyType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDependencyType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAContentType {
	## METHOD: java.lang.String getAContentType()
    my $self = shift;
    my $getAContentType = JPL::AutoLoader::getmeth('getAContentType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAContentType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTargetDocbase {
	## METHOD: java.lang.String getTargetDocbase()
    my $self = shift;
    my $getTargetDocbase = JPL::AutoLoader::getmeth('getTargetDocbase',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTargetDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDateSent {
	## METHOD: com.documentum.fc.common.IDfTime getDateSent()
    my $self = shift;
    my $getDateSent = JPL::AutoLoader::getmeth('getDateSent',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getDateSent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isDeleteFlag {
	## METHOD: boolean isDeleteFlag()
    my $self = shift;
    my $isDeleteFlag = JPL::AutoLoader::getmeth('isDeleteFlag',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDeleteFlag(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStamp {
	## METHOD: com.documentum.fc.common.IDfId getStamp()
    my $self = shift;
    my $getStamp = JPL::AutoLoader::getmeth('getStamp',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getStamp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getSentBy {
	## METHOD: java.lang.String getSentBy()
    my $self = shift;
    my $getSentBy = JPL::AutoLoader::getmeth('getSentBy',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSentBy(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSourceDocbase {
	## METHOD: java.lang.String getSourceDocbase()
    my $self = shift;
    my $getSourceDocbase = JPL::AutoLoader::getmeth('getSourceDocbase',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSourceDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRemotePending {
	## METHOD: boolean isRemotePending()
    my $self = shift;
    my $isRemotePending = JPL::AutoLoader::getmeth('isRemotePending',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRemotePending(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDequeuedBy {
	## METHOD: java.lang.String getDequeuedBy()
    my $self = shift;
    my $getDequeuedBy = JPL::AutoLoader::getmeth('getDequeuedBy',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDequeuedBy(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSignOffUser {
	## METHOD: java.lang.String getSignOffUser()
    my $self = shift;
    my $getSignOffUser = JPL::AutoLoader::getmeth('getSignOffUser',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSignOffUser(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSourceStamp {
	## METHOD: int getSourceStamp()
    my $self = shift;
    my $getSourceStamp = JPL::AutoLoader::getmeth('getSourceStamp',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getSourceStamp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getOperations {
	## METHOD: java.lang.String getOperations()
    my $self = shift;
    my $getOperations = JPL::AutoLoader::getmeth('getOperations',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getOperations(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPlanStartDate {
	## METHOD: com.documentum.fc.common.IDfTime getPlanStartDate()
    my $self = shift;
    my $getPlanStartDate = JPL::AutoLoader::getmeth('getPlanStartDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getPlanStartDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getActualStartDate {
	## METHOD: com.documentum.fc.common.IDfTime getActualStartDate()
    my $self = shift;
    my $getActualStartDate = JPL::AutoLoader::getmeth('getActualStartDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getActualStartDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getSourceEvent {
	## METHOD: com.documentum.fc.common.IDfId getSourceEvent()
    my $self = shift;
    my $getSourceEvent = JPL::AutoLoader::getmeth('getSourceEvent',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getSourceEvent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getItemName {
	## METHOD: java.lang.String getItemName()
    my $self = shift;
    my $getItemName = JPL::AutoLoader::getmeth('getItemName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getItemName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTaskName {
	## METHOD: java.lang.String getTaskName()
    my $self = shift;
    my $getTaskName = JPL::AutoLoader::getmeth('getTaskName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTaskName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getInstructionPage {
	## METHOD: int getInstructionPage()
    my $self = shift;
    my $getInstructionPage = JPL::AutoLoader::getmeth('getInstructionPage',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getInstructionPage(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPosition {
	## METHOD: double getPosition()
    my $self = shift;
    my $getPosition = JPL::AutoLoader::getmeth('getPosition',[],['double']);
    my $rv = "";
    eval { $rv = $$self->$getPosition(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRouterId {
	## METHOD: com.documentum.fc.common.IDfId getRouterId()
    my $self = shift;
    my $getRouterId = JPL::AutoLoader::getmeth('getRouterId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getRouterId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getTaskNumber {
	## METHOD: java.lang.String getTaskNumber()
    my $self = shift;
    my $getTaskNumber = JPL::AutoLoader::getmeth('getTaskNumber',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTaskNumber(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getEvent {
	## METHOD: java.lang.String getEvent()
    my $self = shift;
    my $getEvent = JPL::AutoLoader::getmeth('getEvent',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getEvent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTaskState {
	## METHOD: java.lang.String getTaskState()
    my $self = shift;
    my $getTaskState = JPL::AutoLoader::getmeth('getTaskState',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTaskState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDequeuedDate {
	## METHOD: com.documentum.fc.common.IDfTime getDequeuedDate()
    my $self = shift;
    my $getDequeuedDate = JPL::AutoLoader::getmeth('getDequeuedDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getDequeuedDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isReadFlag {
	## METHOD: boolean isReadFlag()
    my $self = shift;
    my $isReadFlag = JPL::AutoLoader::getmeth('isReadFlag',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isReadFlag(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNextTasksType {
	## METHOD: java.lang.String getNextTasksType()
    my $self = shift;
    my $getNextTasksType = JPL::AutoLoader::getmeth('getNextTasksType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNextTasksType(); };
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
