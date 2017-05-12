# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfPackage (com.documentum.fc.client.IDfPackage)
# ------------------------------------------------------------------ #

package IDfPackage;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfPackage';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


sub getComponentId {
	## METHOD: com.documentum.fc.common.IDfId getComponentId(int)
    my ($self,$p0) = @_;
    my $getComponentId = JPL::AutoLoader::getmeth('getComponentId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getComponentId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getComponentIdCount {
	## METHOD: int getComponentIdCount()
    my $self = shift;
    my $getComponentIdCount = JPL::AutoLoader::getmeth('getComponentIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getComponentIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeNote {
	## METHOD: void removeNote(int)
    my ($self,$p0) = @_;
    my $removeNote = JPL::AutoLoader::getmeth('removeNote',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeNote($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageOperation {
	## METHOD: java.lang.String getPackageOperation()
    my $self = shift;
    my $getPackageOperation = JPL::AutoLoader::getmeth('getPackageOperation',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageOperation(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageType {
	## METHOD: java.lang.String getPackageType()
    my $self = shift;
    my $getPackageType = JPL::AutoLoader::getmeth('getPackageType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageCount {
	## METHOD: int getPackageCount()
    my $self = shift;
    my $getPackageCount = JPL::AutoLoader::getmeth('getPackageCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPackageCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageId {
	## METHOD: com.documentum.fc.common.IDfId getPackageId(int)
    my ($self,$p0) = @_;
    my $getPackageId = JPL::AutoLoader::getmeth('getPackageId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getPackageId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getPackageLabel {
	## METHOD: java.lang.String getPackageLabel(int)
    my ($self,$p0) = @_;
    my $getPackageLabel = JPL::AutoLoader::getmeth('getPackageLabel',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageName {
	## METHOD: java.lang.String getPackageName()
    my $self = shift;
    my $getPackageName = JPL::AutoLoader::getmeth('getPackageName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPackageName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExecMethodId {
	## METHOD: com.documentum.fc.common.IDfId getExecMethodId()
    my $self = shift;
    my $getExecMethodId = JPL::AutoLoader::getmeth('getExecMethodId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getExecMethodId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getPortName {
	## METHOD: java.lang.String getPortName()
    my $self = shift;
    my $getPortName = JPL::AutoLoader::getmeth('getPortName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPortName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPackageOrder {
	## METHOD: int getPackageOrder()
    my $self = shift;
    my $getPackageOrder = JPL::AutoLoader::getmeth('getPackageOrder',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPackageOrder(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNoteWriter {
	## METHOD: java.lang.String getNoteWriter(int)
    my ($self,$p0) = @_;
    my $getNoteWriter = JPL::AutoLoader::getmeth('getNoteWriter',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNoteWriter($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNoteId {
	## METHOD: com.documentum.fc.common.IDfId getNoteId(int)
    my ($self,$p0) = @_;
    my $getNoteId = JPL::AutoLoader::getmeth('getNoteId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getNoteId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub appendNote {
	## METHOD: int appendNote(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $appendNote = JPL::AutoLoader::getmeth('appendNote',['java.lang.String','boolean'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendNote($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNoteCount {
	## METHOD: int getNoteCount()
    my $self = shift;
    my $getNoteCount = JPL::AutoLoader::getmeth('getNoteCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getNoteCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAcceptanceDate {
	## METHOD: com.documentum.fc.common.IDfTime getAcceptanceDate()
    my $self = shift;
    my $getAcceptanceDate = JPL::AutoLoader::getmeth('getAcceptanceDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getAcceptanceDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getActSeqno {
	## METHOD: int getActSeqno()
    my $self = shift;
    my $getActSeqno = JPL::AutoLoader::getmeth('getActSeqno',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getActSeqno(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNoteFlag {
	## METHOD: int getNoteFlag(int)
    my ($self,$p0) = @_;
    my $getNoteFlag = JPL::AutoLoader::getmeth('getNoteFlag',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getNoteFlag($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNoteCreationDate {
	## METHOD: com.documentum.fc.common.IDfTime getNoteCreationDate(int)
    my ($self,$p0) = @_;
    my $getNoteCreationDate = JPL::AutoLoader::getmeth('getNoteCreationDate',['int'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getNoteCreationDate($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isManufactured {
	## METHOD: boolean isManufactured()
    my $self = shift;
    my $isManufactured = JPL::AutoLoader::getmeth('isManufactured',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isManufactured(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorkflowId {
	## METHOD: com.documentum.fc.common.IDfId getWorkflowId()
    my $self = shift;
    my $getWorkflowId = JPL::AutoLoader::getmeth('getWorkflowId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getWorkflowId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getNoteText {
	## METHOD: java.lang.String getNoteText(int)
    my ($self,$p0) = @_;
    my $getNoteText = JPL::AutoLoader::getmeth('getNoteText',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNoteText($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNotePersistance {
	## METHOD: boolean getNotePersistance(int)
    my ($self,$p0) = @_;
    my $getNotePersistance = JPL::AutoLoader::getmeth('getNotePersistance',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getNotePersistance($p0); };
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
