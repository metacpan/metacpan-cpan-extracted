# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfValue (com.documentum.fc.common.IDfValue)
# ------------------------------------------------------------------ #

package IDfValue;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfValue';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfTime';

use constant DF_BOOLEAN => 0;
use constant DF_INTEGER => 1;
use constant DF_STRING => 2;
use constant DF_ID => 3;
use constant DF_TIME => 4;
use constant DF_DOUBLE => 5;
use constant DF_UNDEFINED => 6;

sub compareTo {
	## METHOD: int compareTo(com.documentum.fc.common.IDfValue)
    my ($self,$p0) = @_;
    my $compareTo = JPL::AutoLoader::getmeth('compareTo',['com.documentum.fc.common.IDfValue'],['int']);
    my $rv = "";
    eval { $rv = $$self->$compareTo($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub equals {
	## METHOD: boolean equals(java.lang.Object)
    my ($self,$p0) = @_;
    my $equals = JPL::AutoLoader::getmeth('equals',['java.lang.Object'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$equals($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asString {
	## METHOD: java.lang.String asString()
    my $self = shift;
    my $asString = JPL::AutoLoader::getmeth('asString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$asString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDataType {
	## METHOD: int getDataType()
    my $self = shift;
    my $getDataType = JPL::AutoLoader::getmeth('getDataType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDataType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asInteger {
	## METHOD: int asInteger()
    my $self = shift;
    my $asInteger = JPL::AutoLoader::getmeth('asInteger',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$asInteger(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asId {
	## METHOD: com.documentum.fc.common.IDfId asId()
    my $self = shift;
    my $asId = JPL::AutoLoader::getmeth('asId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$asId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub asTime {
	## METHOD: com.documentum.fc.common.IDfTime asTime()
    my $self = shift;
    my $asTime = JPL::AutoLoader::getmeth('asTime',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$asTime(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub asBoolean {
	## METHOD: boolean asBoolean()
    my $self = shift;
    my $asBoolean = JPL::AutoLoader::getmeth('asBoolean',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$asBoolean(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asDouble {
	## METHOD: double asDouble()
    my $self = shift;
    my $asDouble = JPL::AutoLoader::getmeth('asDouble',[],['double']);
    my $rv = "";
    eval { $rv = $$self->$asDouble(); };
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
