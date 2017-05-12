# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfRelation (com.documentum.fc.client.IDfRelation)
# ------------------------------------------------------------------ #

package IDfRelation;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfRelation';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';


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

sub setDescription {
	## METHOD: void setDescription(java.lang.String)
    my ($self,$p0) = @_;
    my $setDescription = JPL::AutoLoader::getmeth('setDescription',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDescription($p0); };
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
	## METHOD: int getOrderNumber()
    my $self = shift;
    my $getOrderNumber = JPL::AutoLoader::getmeth('getOrderNumber',[],['int']);
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
	## METHOD: void setOrderNumber(int)
    my ($self,$p0) = @_;
    my $setOrderNumber = JPL::AutoLoader::getmeth('setOrderNumber',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOrderNumber($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRelationName {
	## METHOD: java.lang.String getRelationName()
    my $self = shift;
    my $getRelationName = JPL::AutoLoader::getmeth('getRelationName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getRelationName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRelationName {
	## METHOD: void setRelationName(java.lang.String)
    my ($self,$p0) = @_;
    my $setRelationName = JPL::AutoLoader::getmeth('setRelationName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRelationName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getEffectiveDate {
	## METHOD: com.documentum.fc.common.IDfTime getEffectiveDate()
    my $self = shift;
    my $getEffectiveDate = JPL::AutoLoader::getmeth('getEffectiveDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getEffectiveDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getExpirationDate {
	## METHOD: com.documentum.fc.common.IDfTime getExpirationDate()
    my $self = shift;
    my $getExpirationDate = JPL::AutoLoader::getmeth('getExpirationDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getExpirationDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub setEffectiveDate {
	## METHOD: void setEffectiveDate(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $setEffectiveDate = JPL::AutoLoader::getmeth('setEffectiveDate',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$setEffectiveDate($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExpirationDate {
	## METHOD: void setExpirationDate(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $setExpirationDate = JPL::AutoLoader::getmeth('setExpirationDate',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExpirationDate($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChildId {
	## METHOD: com.documentum.fc.common.IDfId getChildId()
    my $self = shift;
    my $getChildId = JPL::AutoLoader::getmeth('getChildId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getChildId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setChildId {
	## METHOD: void setChildId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $setChildId = JPL::AutoLoader::getmeth('setChildId',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setChildId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChildLabel {
	## METHOD: java.lang.String getChildLabel()
    my $self = shift;
    my $getChildLabel = JPL::AutoLoader::getmeth('getChildLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getChildLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setChildLabel {
	## METHOD: void setChildLabel(java.lang.String)
    my ($self,$p0) = @_;
    my $setChildLabel = JPL::AutoLoader::getmeth('setChildLabel',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setChildLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPermanentLink {
	## METHOD: boolean getPermanentLink()
    my $self = shift;
    my $getPermanentLink = JPL::AutoLoader::getmeth('getPermanentLink',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getPermanentLink(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPermanentLink {
	## METHOD: void setPermanentLink(boolean)
    my ($self,$p0) = @_;
    my $setPermanentLink = JPL::AutoLoader::getmeth('setPermanentLink',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPermanentLink($p0); };
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
