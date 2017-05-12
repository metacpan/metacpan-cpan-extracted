# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfAttrLine (com.documentum.fc.client.qb.IDfAttrLine)
# ------------------------------------------------------------------ #

package IDfAttrLine;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfAttrLine';
use JPL::Class 'com.documentum.fc.common.IDfList';

use constant TYPE_NONE => 99;
use constant TYPE_STRING => 2;
use constant TYPE_TIME => 4;
use constant TYPE_INTEGER => 1;
use constant TYPE_BOOL => 0;
use constant TYPE_ID => 3;
use constant TYPE_DOUBLE => 5;
use constant OPER_EQUALS => 1;
use constant OPER_NOTEQUAL => 2;
use constant OPER_GREATERTHAN => 3;
use constant OPER_LESSTHAN => 4;
use constant OPER_GREATEREQUAL => 5;
use constant OPER_LESSEQUAL => 6;
use constant OPER_BEGINSWITH => 7;
use constant OPER_CONTAINS => 8;
use constant OPER_NOTCONTAIN => 9;
use constant OPER_ENDSWITH => 10;
use constant OPER_IN => 11;
use constant OPER_NOTIN => 12;
use constant OPER_BETWEEN => 13;
use constant OPER_ISNULL => 14;
use constant OPER_NOTNULL => 15;
use constant OPER_NOT => 16;
use constant OPER_TRUE => 100;
use constant OPER_FALSE => 101;

sub getValue {
	## METHOD: java.lang.String getValue()
    my $self = shift;
    my $getValue = JPL::AutoLoader::getmeth('getValue',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub join {
	## METHOD: boolean join()
    my $self = shift;
    my $join = JPL::AutoLoader::getmeth('join',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$join(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setValue {
	## METHOD: void setValue(java.lang.String)
    my ($self,$p0) = @_;
    my $setValue = JPL::AutoLoader::getmeth('setValue',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttr {
	## METHOD: java.lang.String getAttr()
    my $self = shift;
    my $getAttr = JPL::AutoLoader::getmeth('getAttr',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAttr(); };
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

sub isVisible {
	## METHOD: boolean isVisible()
    my $self = shift;
    my $isVisible = JPL::AutoLoader::getmeth('isVisible',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isVisible(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setVisible {
	## METHOD: void setVisible(boolean)
    my ($self,$p0) = @_;
    my $setVisible = JPL::AutoLoader::getmeth('setVisible',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVisible($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRepeating {
	## METHOD: boolean isRepeating()
    my $self = shift;
    my $isRepeating = JPL::AutoLoader::getmeth('isRepeating',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRepeating(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAttr {
	## METHOD: void setAttr(java.lang.String)
    my ($self,$p0) = @_;
    my $setAttr = JPL::AutoLoader::getmeth('setAttr',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setLogicOp {
	## METHOD: void setLogicOp(java.lang.String)
    my ($self,$p0) = @_;
    my $setLogicOp = JPL::AutoLoader::getmeth('setLogicOp',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setLogicOp($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupID {
	## METHOD: int getGroupID()
    my $self = shift;
    my $getGroupID = JPL::AutoLoader::getmeth('getGroupID',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getGroupID(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLogicOp {
	## METHOD: java.lang.String getLogicOp()
    my $self = shift;
    my $getLogicOp = JPL::AutoLoader::getmeth('getLogicOp',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLogicOp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRelationalOp {
	## METHOD: void setRelationalOp(int)
    my ($self,$p0) = @_;
    my $setRelationalOp = JPL::AutoLoader::getmeth('setRelationalOp',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRelationalOp($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setEndValue {
	## METHOD: void setEndValue(java.lang.String)
    my ($self,$p0) = @_;
    my $setEndValue = JPL::AutoLoader::getmeth('setEndValue',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setEndValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getEndValue {
	## METHOD: java.lang.String getEndValue()
    my $self = shift;
    my $getEndValue = JPL::AutoLoader::getmeth('getEndValue',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getEndValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrList {
	## METHOD: com.documentum.fc.common.IDfList getAttrList()
    my $self = shift;
    my $getAttrList = JPL::AutoLoader::getmeth('getAttrList',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getAttrList(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getRelationalOp {
	## METHOD: int getRelationalOp()
    my $self = shift;
    my $getRelationalOp = JPL::AutoLoader::getmeth('getRelationalOp',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getRelationalOp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRelationalOpList {
	## METHOD: com.documentum.fc.common.IDfList getRelationalOpList()
    my $self = shift;
    my $getRelationalOpList = JPL::AutoLoader::getmeth('getRelationalOpList',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getRelationalOpList(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getValueList {
	## METHOD: com.documentum.fc.common.IDfList getValueList()
    my $self = shift;
    my $getValueList = JPL::AutoLoader::getmeth('getValueList',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getValueList(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub split {
	## METHOD: boolean split()
    my $self = shift;
    my $split = JPL::AutoLoader::getmeth('split',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$split(); };
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
