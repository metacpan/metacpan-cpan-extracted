# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfAssembly (com.documentum.fc.client.IDfAssembly)
# ------------------------------------------------------------------ #

package IDfAssembly;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfAssembly';
use JPL::Class 'com.documentum.fc.common.IDfId';


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

sub getDepth {
	## METHOD: int getDepth()
    my $self = shift;
    my $getDepth = JPL::AutoLoader::getmeth('getDepth',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDepth(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDepth {
	## METHOD: void setDepth(int)
    my ($self,$p0) = @_;
    my $setDepth = JPL::AutoLoader::getmeth('setDepth',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDepth($p0); };
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

sub setParentId {
	## METHOD: void setParentId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setParentId = JPL::AutoLoader::getmeth('setParentId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setParentId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub setOrderNumber {
	## METHOD: void setOrderNumber(double)
    my ($self,$p0) = @_;
    my $setOrderNumber = JPL::AutoLoader::getmeth('setOrderNumber',['double'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOrderNumber($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setComponentId {
	## METHOD: void setComponentId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setComponentId = JPL::AutoLoader::getmeth('setComponentId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setComponentId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBookId {
	## METHOD: com.documentum.fc.common.IDfId getBookId()
    my $self = shift;
    my $getBookId = JPL::AutoLoader::getmeth('getBookId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getBookId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setBookId {
	## METHOD: void setBookId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setBookId = JPL::AutoLoader::getmeth('setBookId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setBookId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getComponentChronicleId {
	## METHOD: com.documentum.fc.common.IDfId getComponentChronicleId()
    my $self = shift;
    my $getComponentChronicleId = JPL::AutoLoader::getmeth('getComponentChronicleId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getComponentChronicleId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setComponentChronicleId {
	## METHOD: void setComponentChronicleId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setComponentChronicleId = JPL::AutoLoader::getmeth('setComponentChronicleId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setComponentChronicleId($$p0); };
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
