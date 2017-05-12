# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfType (com.documentum.fc.client.IDfType)
# ------------------------------------------------------------------ #

package IDfType;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfType';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.client.IDfValidator';
use JPL::Class 'com.documentum.fc.client.IDfType';

use constant DF_BOOLEAN => 0;
use constant DF_INTEGER => 1;
use constant DF_STRING => 2;
use constant DF_ID => 3;
use constant DF_TIME => 4;
use constant DF_DOUBLE => 5;
use constant DF_UNDEFINED => 6;

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

sub getSuperType {
	## METHOD: com.documentum.fc.client.IDfType getSuperType()
    my $self = shift;
    my $getSuperType = JPL::AutoLoader::getmeth('getSuperType',[],['com.documentum.fc.client.IDfType']);
    my $rv = "";
    eval { $rv = $$self->$getSuperType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfType);
        return \$rv;
    }
}

sub getTypeAttrCount {
	## METHOD: int getTypeAttrCount()
    my $self = shift;
    my $getTypeAttrCount = JPL::AutoLoader::getmeth('getTypeAttrCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrNameAt {
	## METHOD: java.lang.String getTypeAttrNameAt(int)
    my ($self,$p0) = @_;
    my $getTypeAttrNameAt = JPL::AutoLoader::getmeth('getTypeAttrNameAt',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrNameAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrDataType {
	## METHOD: int getTypeAttrDataType(java.lang.String)
    my ($self,$p0) = @_;
    my $getTypeAttrDataType = JPL::AutoLoader::getmeth('getTypeAttrDataType',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrDataType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isTypeAttrRepeating {
	## METHOD: boolean isTypeAttrRepeating(java.lang.String)
    my ($self,$p0) = @_;
    my $isTypeAttrRepeating = JPL::AutoLoader::getmeth('isTypeAttrRepeating',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isTypeAttrRepeating($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrAsstDependencies {
	## METHOD: com.documentum.fc.common.IDfList getTypeAttrAsstDependencies(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $getTypeAttrAsstDependencies = JPL::AutoLoader::getmeth('getTypeAttrAsstDependencies',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrAsstDependencies($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub isSubTypeOf {
	## METHOD: boolean isSubTypeOf(java.lang.String)
    my ($self,$p0) = @_;
    my $isSubTypeOf = JPL::AutoLoader::getmeth('isSubTypeOf',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSubTypeOf($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isTypeAttrRepeatingAt {
	## METHOD: boolean isTypeAttrRepeatingAt(int)
    my ($self,$p0) = @_;
    my $isTypeAttrRepeatingAt = JPL::AutoLoader::getmeth('isTypeAttrRepeatingAt',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isTypeAttrRepeatingAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrLengthAt {
	## METHOD: int getTypeAttrLengthAt(int)
    my ($self,$p0) = @_;
    my $getTypeAttrLengthAt = JPL::AutoLoader::getmeth('getTypeAttrLengthAt',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrLengthAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrDescriptionAt {
	## METHOD: java.lang.String getTypeAttrDescriptionAt(int)
    my ($self,$p0) = @_;
    my $getTypeAttrDescriptionAt = JPL::AutoLoader::getmeth('getTypeAttrDescriptionAt',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrDescriptionAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findTypeAttrIndex {
	## METHOD: int findTypeAttrIndex(java.lang.String)
    my ($self,$p0) = @_;
    my $findTypeAttrIndex = JPL::AutoLoader::getmeth('findTypeAttrIndex',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findTypeAttrIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSuperName {
	## METHOD: java.lang.String getSuperName()
    my $self = shift;
    my $getSuperName = JPL::AutoLoader::getmeth('getSuperName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSuperName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeWidgetType {
	## METHOD: java.lang.String getTypeWidgetType(int,java.lang.String,com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getTypeWidgetType = JPL::AutoLoader::getmeth('getTypeWidgetType',['int','java.lang.String','com.documentum.fc.common.IDfId','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeWidgetType($p0,$p1,$$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateTypeAttrRulesWithValue {
	## METHOD: void validateTypeAttrRulesWithValue(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,int)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6) = @_;
    my $validateTypeAttrRulesWithValue = JPL::AutoLoader::getmeth('validateTypeAttrRulesWithValue',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateTypeAttrRulesWithValue($p0,$$p1,$p2,$p3,$$p4,$$p5,$p6); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeValidator {
	## METHOD: com.documentum.fc.client.IDfValidator getTypeValidator(com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getTypeValidator = JPL::AutoLoader::getmeth('getTypeValidator',['com.documentum.fc.common.IDfId','java.lang.String'],['com.documentum.fc.client.IDfValidator']);
    my $rv = "";
    eval { $rv = $$self->$getTypeValidator($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValidator);
        return \$rv;
    }
}

sub getTypeAttrLength {
	## METHOD: int getTypeAttrLength(java.lang.String)
    my ($self,$p0) = @_;
    my $getTypeAttrLength = JPL::AutoLoader::getmeth('getTypeAttrLength',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrLength($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateTypeAttrRulesWithValues {
	## METHOD: void validateTypeAttrRulesWithValues(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,int)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6) = @_;
    my $validateTypeAttrRulesWithValues = JPL::AutoLoader::getmeth('validateTypeAttrRulesWithValues',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateTypeAttrRulesWithValues($p0,$$p1,$p2,$$p3,$$p4,$$p5,$p6); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateTypeObjRulesWithValues {
	## METHOD: void validateTypeObjRulesWithValues(com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfId,java.lang.String,com.documentum.fc.common.IDfList,int)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $validateTypeObjRulesWithValues = JPL::AutoLoader::getmeth('validateTypeObjRulesWithValues',['com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfId','java.lang.String','com.documentum.fc.common.IDfList','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateTypeObjRulesWithValues($$p0,$$p1,$p2,$$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrAssistanceWithValues {
	## METHOD: com.documentum.fc.common.IDfList getTypeAttrAssistanceWithValues(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $getTypeAttrAssistanceWithValues = JPL::AutoLoader::getmeth('getTypeAttrAssistanceWithValues',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrAssistanceWithValues($p0,$$p1,$p2,$$p3,$$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getTypeAttrDataTypeAt {
	## METHOD: int getTypeAttrDataTypeAt(int)
    my ($self,$p0) = @_;
    my $getTypeAttrDataTypeAt = JPL::AutoLoader::getmeth('getTypeAttrDataTypeAt',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrDataTypeAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeAttrDescription {
	## METHOD: java.lang.String getTypeAttrDescription(java.lang.String)
    my ($self,$p0) = @_;
    my $getTypeAttrDescription = JPL::AutoLoader::getmeth('getTypeAttrDescription',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeAttrDescription($p0); };
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
