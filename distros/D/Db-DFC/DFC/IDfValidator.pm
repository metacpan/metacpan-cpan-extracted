# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfValidator (com.documentum.fc.client.IDfValidator)
# ------------------------------------------------------------------ #

package IDfValidator;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfValidator';
use JPL::Class 'com.documentum.fc.client.IDfValueAssistance';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfPersistentObject';
use JPL::Class 'com.documentum.fc.common.IDfProperties';


sub getObjectType {
	## METHOD: java.lang.String getObjectType()
    my $self = shift;
    my $getObjectType = JPL::AutoLoader::getmeth('getObjectType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWidgetType {
	## METHOD: java.lang.String getWidgetType(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getWidgetType = JPL::AutoLoader::getmeth('getWidgetType',['int','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getWidgetType($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateAttrRules {
	## METHOD: void validateAttrRules(java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfProperties)
    my ($self,$p0,$p1,$p2) = @_;
    my $validateAttrRules = JPL::AutoLoader::getmeth('validateAttrRules',['java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfProperties'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAttrRules($p0,$$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getValueAssistance {
	## METHOD: com.documentum.fc.client.IDfValueAssistance getValueAssistance(java.lang.String,com.documentum.fc.common.IDfProperties)
    my ($self,$p0,$p1) = @_;
    my $getValueAssistance = JPL::AutoLoader::getmeth('getValueAssistance',['java.lang.String','com.documentum.fc.common.IDfProperties'],['com.documentum.fc.client.IDfValueAssistance']);
    my $rv = "";
    eval { $rv = $$self->$getValueAssistance($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValueAssistance);
        return \$rv;
    }
}

sub getTimePattern {
	## METHOD: java.lang.String getTimePattern()
    my $self = shift;
    my $getTimePattern = JPL::AutoLoader::getmeth('getTimePattern',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTimePattern(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTimePattern {
	## METHOD: void setTimePattern(java.lang.String)
    my ($self,$p0) = @_;
    my $setTimePattern = JPL::AutoLoader::getmeth('setTimePattern',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTimePattern($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateAll {
	## METHOD: void validateAll(com.documentum.fc.common.IDfProperties,boolean)
    my ($self,$p0,$p1) = @_;
    my $validateAll = JPL::AutoLoader::getmeth('validateAll',['com.documentum.fc.common.IDfProperties','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAll($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getValueAssistanceDependencies {
	## METHOD: com.documentum.fc.common.IDfProperties getValueAssistanceDependencies(java.lang.String)
    my ($self,$p0) = @_;
    my $getValueAssistanceDependencies = JPL::AutoLoader::getmeth('getValueAssistanceDependencies',['java.lang.String'],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getValueAssistanceDependencies($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub setMaxErrorBeforeStop {
	## METHOD: void setMaxErrorBeforeStop(int)
    my ($self,$p0) = @_;
    my $setMaxErrorBeforeStop = JPL::AutoLoader::getmeth('setMaxErrorBeforeStop',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setMaxErrorBeforeStop($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateAllAttrRules {
	## METHOD: void validateAllAttrRules(com.documentum.fc.common.IDfProperties,boolean)
    my ($self,$p0,$p1) = @_;
    my $validateAllAttrRules = JPL::AutoLoader::getmeth('validateAllAttrRules',['com.documentum.fc.common.IDfProperties','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAllAttrRules($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAssociatedObject {
	## METHOD: com.documentum.fc.client.IDfPersistentObject getAssociatedObject()
    my $self = shift;
    my $getAssociatedObject = JPL::AutoLoader::getmeth('getAssociatedObject',[],['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $$self->$getAssociatedObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfPersistentObject);
        return \$rv;
    }
}

sub hasValueAssistance {
	## METHOD: boolean hasValueAssistance(java.lang.String)
    my ($self,$p0) = @_;
    my $hasValueAssistance = JPL::AutoLoader::getmeth('hasValueAssistance',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasValueAssistance($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPolicyID {
	## METHOD: com.documentum.fc.common.IDfId getPolicyID()
    my $self = shift;
    my $getPolicyID = JPL::AutoLoader::getmeth('getPolicyID',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getPolicyID(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getStateName {
	## METHOD: java.lang.String getStateName()
    my $self = shift;
    my $getStateName = JPL::AutoLoader::getmeth('getStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateAllObjRules {
	## METHOD: void validateAllObjRules(com.documentum.fc.common.IDfProperties)
    my ($self,$p0) = @_;
    my $validateAllObjRules = JPL::AutoLoader::getmeth('validateAllObjRules',['com.documentum.fc.common.IDfProperties'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAllObjRules($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMaxErrorBeforeStop {
	## METHOD: int getMaxErrorBeforeStop()
    my $self = shift;
    my $getMaxErrorBeforeStop = JPL::AutoLoader::getmeth('getMaxErrorBeforeStop',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getMaxErrorBeforeStop(); };
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
