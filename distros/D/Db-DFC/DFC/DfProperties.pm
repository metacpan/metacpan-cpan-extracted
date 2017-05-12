# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfProperties (com.documentum.fc.common.DfProperties)
# ------------------------------------------------------------------ #

package DfProperties;
@ISA = (IDfProperties);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfProperties';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfValue';



sub new {
    my ($class,$p0) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfProperties()
    ## CONSTRUCTOR: com.documentum.fc.common.DfProperties(int)

    if ($p0 =~ /\d+/) {
        my $new = JPL::AutoLoader::getmeth('new',['int'],[]);
        eval { $rv = com::documentum::fc::common::DfProperties->$new($p0); };
    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfProperties->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfProperties);
        return \$rv;
    }
}

sub put {
	## METHOD: void put(java.lang.String,java.lang.Object)
    my ($self,$p0,$p1) = @_;
    my $put = JPL::AutoLoader::getmeth('put',['java.lang.String','java.lang.Object'],[]);
    my $rv = "";
    eval { $rv = $$self->$put($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub get {
	## METHOD: java.lang.Object get(java.lang.String)
    my ($self,$p0) = @_;
    my $get = JPL::AutoLoader::getmeth('get',['java.lang.String'],['java.lang.Object']);
    my $rv = "";
    eval { $rv = $$self->$get($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getValue {
	## METHOD: com.documentum.fc.common.IDfValue getValue(java.lang.String)
    my ($self,$p0) = @_;
    my $getValue = JPL::AutoLoader::getmeth('getValue',['java.lang.String'],['com.documentum.fc.common.IDfValue']);
    my $rv = "";
    eval { $rv = $$self->$getValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValue);
        return \$rv;
    }
}

sub clear {
	## METHOD: void clear()
    my $self = shift;
    my $clear = JPL::AutoLoader::getmeth('clear',[],[]);
    my $rv = "";
    eval { $rv = $$self->$clear(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub remove {
	## METHOD: void remove(java.lang.String)
    my ($self,$p0) = @_;
    my $remove = JPL::AutoLoader::getmeth('remove',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$remove($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isEmpty {
	## METHOD: boolean isEmpty()
    my $self = shift;
    my $isEmpty = JPL::AutoLoader::getmeth('isEmpty',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isEmpty(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub containsValue {
	## METHOD: boolean containsValue(java.lang.Object)
    my ($self,$p0) = @_;
    my $containsValue = JPL::AutoLoader::getmeth('containsValue',['java.lang.Object'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$containsValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBoolean {
	## METHOD: boolean getBoolean(java.lang.String)
    my ($self,$p0) = @_;
    my $getBoolean = JPL::AutoLoader::getmeth('getBoolean',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getBoolean($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getProperties {
	## METHOD: com.documentum.fc.common.IDfList getProperties()
    my $self = shift;
    my $getProperties = JPL::AutoLoader::getmeth('getProperties',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getProperties(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getTime {
	## METHOD: com.documentum.fc.common.IDfTime getTime(java.lang.String)
    my ($self,$p0) = @_;
    my $getTime = JPL::AutoLoader::getmeth('getTime',['java.lang.String'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getTime($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub putValue {
	## METHOD: void putValue(java.lang.String,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $putValue = JPL::AutoLoader::getmeth('putValue',['java.lang.String','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$putValue($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getInt {
	## METHOD: int getInt(java.lang.String)
    my ($self,$p0) = @_;
    my $getInt = JPL::AutoLoader::getmeth('getInt',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getInt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDouble {
	## METHOD: double getDouble(java.lang.String)
    my ($self,$p0) = @_;
    my $getDouble = JPL::AutoLoader::getmeth('getDouble',['java.lang.String'],['double']);
    my $rv = "";
    eval { $rv = $$self->$getDouble($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getId {
	## METHOD: com.documentum.fc.common.IDfId getId(java.lang.String)
    my ($self,$p0) = @_;
    my $getId = JPL::AutoLoader::getmeth('getId',['java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getList {
	## METHOD: com.documentum.fc.common.IDfList getList(java.lang.String)
    my ($self,$p0) = @_;
    my $getList = JPL::AutoLoader::getmeth('getList',['java.lang.String'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getList($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub putString {
	## METHOD: void putString(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $putString = JPL::AutoLoader::getmeth('putString',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$putString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putInt {
	## METHOD: void putInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $putInt = JPL::AutoLoader::getmeth('putInt',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$putInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCount {
	## METHOD: int getCount()
    my $self = shift;
    my $getCount = JPL::AutoLoader::getmeth('getCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getString {
	## METHOD: java.lang.String getString(java.lang.String)
    my ($self,$p0) = @_;
    my $getString = JPL::AutoLoader::getmeth('getString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putId {
	## METHOD: void putId(java.lang.String,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $putId = JPL::AutoLoader::getmeth('putId',['java.lang.String','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$putId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putTime {
	## METHOD: void putTime(java.lang.String,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $putTime = JPL::AutoLoader::getmeth('putTime',['java.lang.String','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$putTime($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putList {
	## METHOD: void putList(java.lang.String,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1) = @_;
    my $putList = JPL::AutoLoader::getmeth('putList',['java.lang.String','com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$putList($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putBoolean {
	## METHOD: void putBoolean(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $putBoolean = JPL::AutoLoader::getmeth('putBoolean',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$putBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPropertyType {
	## METHOD: int getPropertyType(java.lang.String)
    my ($self,$p0) = @_;
    my $getPropertyType = JPL::AutoLoader::getmeth('getPropertyType',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPropertyType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub containsProperty {
	## METHOD: boolean containsProperty(java.lang.String)
    my ($self,$p0) = @_;
    my $containsProperty = JPL::AutoLoader::getmeth('containsProperty',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$containsProperty($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub putDouble {
	## METHOD: void putDouble(java.lang.String,double)
    my ($self,$p0,$p1) = @_;
    my $putDouble = JPL::AutoLoader::getmeth('putDouble',['java.lang.String','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$putDouble($p0,$p1); };
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
