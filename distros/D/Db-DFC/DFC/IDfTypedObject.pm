# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfTypedObject (com.documentum.fc.client.IDfTypedObject)
# ------------------------------------------------------------------ #

package IDfTypedObject;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfTypedObject';
use JPL::Class 'com.documentum.fc.client.IDfSession';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfValue';
use JPL::Class 'com.documentum.fc.common.IDfAttr';
use JPL::Class 'com.documentum.fc.common.IDfTime';


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

sub remove {
	## METHOD: void remove(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $remove = JPL::AutoLoader::getmeth('remove',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$remove($p0,$p1); };
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

sub removeAll {
	## METHOD: void removeAll(java.lang.String)
    my ($self,$p0) = @_;
    my $removeAll = JPL::AutoLoader::getmeth('removeAll',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAll($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setValue {
	## METHOD: void setValue(java.lang.String,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $setValue = JPL::AutoLoader::getmeth('setValue',['java.lang.String','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$setValue($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTime {
	## METHOD: void setTime(java.lang.String,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $setTime = JPL::AutoLoader::getmeth('setTime',['java.lang.String','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTime($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub findValue {
	## METHOD: int findValue(java.lang.String,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $findValue = JPL::AutoLoader::getmeth('findValue',['java.lang.String','com.documentum.fc.common.IDfValue'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findValue($p0,$$p1); };
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

sub setBoolean {
	## METHOD: void setBoolean(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $setBoolean = JPL::AutoLoader::getmeth('setBoolean',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setInt {
	## METHOD: void setInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $setInt = JPL::AutoLoader::getmeth('setInt',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDouble {
	## METHOD: void setDouble(java.lang.String,double)
    my ($self,$p0,$p1) = @_;
    my $setDouble = JPL::AutoLoader::getmeth('setDouble',['java.lang.String','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDouble($p0,$p1); };
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

sub isNull {
	## METHOD: boolean isNull(java.lang.String)
    my ($self,$p0) = @_;
    my $isNull = JPL::AutoLoader::getmeth('isNull',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNull($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSession {
	## METHOD: com.documentum.fc.client.IDfSession getSession()
    my $self = shift;
    my $getSession = JPL::AutoLoader::getmeth('getSession',[],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$getSession(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
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

sub appendDouble {
	## METHOD: void appendDouble(java.lang.String,double)
    my ($self,$p0,$p1) = @_;
    my $appendDouble = JPL::AutoLoader::getmeth('appendDouble',['java.lang.String','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendDouble($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertTime {
	## METHOD: void insertTime(java.lang.String,int,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertTime = JPL::AutoLoader::getmeth('insertTime',['java.lang.String','int','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertTime($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setId {
	## METHOD: void setId(java.lang.String,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $setId = JPL::AutoLoader::getmeth('setId',['java.lang.String','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertInt {
	## METHOD: void insertInt(java.lang.String,int,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertInt = JPL::AutoLoader::getmeth('insertInt',['java.lang.String','int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertInt($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertBoolean {
	## METHOD: void insertBoolean(java.lang.String,int,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertBoolean = JPL::AutoLoader::getmeth('insertBoolean',['java.lang.String','int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertBoolean($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendString {
	## METHOD: void appendString(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $appendString = JPL::AutoLoader::getmeth('appendString',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendTime {
	## METHOD: void appendTime(java.lang.String,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $appendTime = JPL::AutoLoader::getmeth('appendTime',['java.lang.String','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendTime($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setString {
	## METHOD: void setString(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setString = JPL::AutoLoader::getmeth('setString',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertDouble {
	## METHOD: void insertDouble(java.lang.String,int,double)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertDouble = JPL::AutoLoader::getmeth('insertDouble',['java.lang.String','int','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertDouble($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertId {
	## METHOD: void insertId(java.lang.String,int,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertId = JPL::AutoLoader::getmeth('insertId',['java.lang.String','int','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertId($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendId {
	## METHOD: void appendId(java.lang.String,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $appendId = JPL::AutoLoader::getmeth('appendId',['java.lang.String','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendValue {
	## METHOD: void appendValue(java.lang.String,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $appendValue = JPL::AutoLoader::getmeth('appendValue',['java.lang.String','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendValue($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertString {
	## METHOD: void insertString(java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertString = JPL::AutoLoader::getmeth('insertString',['java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertString($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendInt {
	## METHOD: void appendInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $appendInt = JPL::AutoLoader::getmeth('appendInt',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendBoolean {
	## METHOD: void appendBoolean(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $appendBoolean = JPL::AutoLoader::getmeth('appendBoolean',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertValue {
	## METHOD: void insertValue(java.lang.String,int,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertValue = JPL::AutoLoader::getmeth('insertValue',['java.lang.String','int','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertValue($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub truncate {
	## METHOD: void truncate(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $truncate = JPL::AutoLoader::getmeth('truncate',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$truncate($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub ztobj_reserved2 {
	## METHOD: void ztobj_reserved2()
    my $self = shift;
    my $ztobj_reserved2 = JPL::AutoLoader::getmeth('ztobj_reserved2',[],[]);
    my $rv = "";
    eval { $rv = $$self->$ztobj_reserved2(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findTime {
	## METHOD: int findTime(java.lang.String,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $findTime = JPL::AutoLoader::getmeth('findTime',['java.lang.String','com.documentum.fc.common.IDfTime'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findTime($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setNull {
	## METHOD: void setNull(java.lang.String)
    my ($self,$p0) = @_;
    my $setNull = JPL::AutoLoader::getmeth('setNull',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setNull($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub ztobj_reserved3 {
	## METHOD: void ztobj_reserved3()
    my $self = shift;
    my $ztobj_reserved3 = JPL::AutoLoader::getmeth('ztobj_reserved3',[],[]);
    my $rv = "";
    eval { $rv = $$self->$ztobj_reserved3(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingString {
	## METHOD: java.lang.String getRepeatingString(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingString = JPL::AutoLoader::getmeth('getRepeatingString',['java.lang.String','int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRepeatingString {
	## METHOD: void setRepeatingString(java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingString = JPL::AutoLoader::getmeth('setRepeatingString',['java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingString($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findAttrIndex {
	## METHOD: int findAttrIndex(java.lang.String)
    my ($self,$p0) = @_;
    my $findAttrIndex = JPL::AutoLoader::getmeth('findAttrIndex',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findAttrIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findInt {
	## METHOD: int findInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $findInt = JPL::AutoLoader::getmeth('findInt',['java.lang.String','int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findBoolean {
	## METHOD: int findBoolean(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $findBoolean = JPL::AutoLoader::getmeth('findBoolean',['java.lang.String','boolean'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectId {
	## METHOD: com.documentum.fc.common.IDfId getObjectId()
    my $self = shift;
    my $getObjectId = JPL::AutoLoader::getmeth('getObjectId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getObjectId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getAttr {
	## METHOD: com.documentum.fc.common.IDfAttr getAttr(int)
    my ($self,$p0) = @_;
    my $getAttr = JPL::AutoLoader::getmeth('getAttr',['int'],['com.documentum.fc.common.IDfAttr']);
    my $rv = "";
    eval { $rv = $$self->$getAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfAttr);
        return \$rv;
    }
}

sub getValueCount {
	## METHOD: int getValueCount(java.lang.String)
    my ($self,$p0) = @_;
    my $getValueCount = JPL::AutoLoader::getmeth('getValueCount',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getValueCount($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findDouble {
	## METHOD: int findDouble(java.lang.String,double)
    my ($self,$p0,$p1) = @_;
    my $findDouble = JPL::AutoLoader::getmeth('findDouble',['java.lang.String','double'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findDouble($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub enumAttrs {
	## METHOD: java.util.Enumeration enumAttrs()
    my $self = shift;
    my $enumAttrs = JPL::AutoLoader::getmeth('enumAttrs',[],['java.util.Enumeration']);
    my $rv = "";
    eval { $rv = $$self->$enumAttrs(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findString {
	## METHOD: int findString(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $findString = JPL::AutoLoader::getmeth('findString',['java.lang.String','java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isAttrRepeating {
	## METHOD: boolean isAttrRepeating(java.lang.String)
    my ($self,$p0) = @_;
    my $isAttrRepeating = JPL::AutoLoader::getmeth('isAttrRepeating',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isAttrRepeating($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrDataType {
	## METHOD: int getAttrDataType(java.lang.String)
    my ($self,$p0) = @_;
    my $getAttrDataType = JPL::AutoLoader::getmeth('getAttrDataType',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAttrDataType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingValue {
	## METHOD: com.documentum.fc.common.IDfValue getRepeatingValue(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingValue = JPL::AutoLoader::getmeth('getRepeatingValue',['java.lang.String','int'],['com.documentum.fc.common.IDfValue']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingValue($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValue);
        return \$rv;
    }
}

sub setRepeatingValue {
	## METHOD: void setRepeatingValue(java.lang.String,int,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingValue = JPL::AutoLoader::getmeth('setRepeatingValue',['java.lang.String','int','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingValue($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub ztobj_reserved5 {
	## METHOD: void ztobj_reserved5()
    my $self = shift;
    my $ztobj_reserved5 = JPL::AutoLoader::getmeth('ztobj_reserved5',[],[]);
    my $rv = "";
    eval { $rv = $$self->$ztobj_reserved5(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingId {
	## METHOD: com.documentum.fc.common.IDfId getRepeatingId(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingId = JPL::AutoLoader::getmeth('getRepeatingId',['java.lang.String','int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingId($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setRepeatingId {
	## METHOD: void setRepeatingId(java.lang.String,int,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingId = JPL::AutoLoader::getmeth('setRepeatingId',['java.lang.String','int','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingId($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingTime {
	## METHOD: com.documentum.fc.common.IDfTime getRepeatingTime(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingTime = JPL::AutoLoader::getmeth('getRepeatingTime',['java.lang.String','int'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingTime($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub setRepeatingTime {
	## METHOD: void setRepeatingTime(java.lang.String,int,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingTime = JPL::AutoLoader::getmeth('setRepeatingTime',['java.lang.String','int','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingTime($p0,$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasAttr {
	## METHOD: boolean hasAttr(java.lang.String)
    my ($self,$p0) = @_;
    my $hasAttr = JPL::AutoLoader::getmeth('hasAttr',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findId {
	## METHOD: int findId(java.lang.String,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $findId = JPL::AutoLoader::getmeth('findId',['java.lang.String','com.documentum.fc.common.IDfId'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAllRepeatingStrings {
	## METHOD: java.lang.String getAllRepeatingStrings(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getAllRepeatingStrings = JPL::AutoLoader::getmeth('getAllRepeatingStrings',['java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAllRepeatingStrings($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub ztobj_reserved4 {
	## METHOD: void ztobj_reserved4()
    my $self = shift;
    my $ztobj_reserved4 = JPL::AutoLoader::getmeth('ztobj_reserved4',[],[]);
    my $rv = "";
    eval { $rv = $$self->$ztobj_reserved4(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingBoolean {
	## METHOD: boolean getRepeatingBoolean(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingBoolean = JPL::AutoLoader::getmeth('getRepeatingBoolean',['java.lang.String','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRepeatingBoolean {
	## METHOD: void setRepeatingBoolean(java.lang.String,int,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingBoolean = JPL::AutoLoader::getmeth('setRepeatingBoolean',['java.lang.String','int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingBoolean($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrCount {
	## METHOD: int getAttrCount()
    my $self = shift;
    my $getAttrCount = JPL::AutoLoader::getmeth('getAttrCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAttrCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingDouble {
	## METHOD: double getRepeatingDouble(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingDouble = JPL::AutoLoader::getmeth('getRepeatingDouble',['java.lang.String','int'],['double']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingDouble($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRepeatingDouble {
	## METHOD: void setRepeatingDouble(java.lang.String,int,double)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingDouble = JPL::AutoLoader::getmeth('setRepeatingDouble',['java.lang.String','int','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingDouble($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getValueAt {
	## METHOD: com.documentum.fc.common.IDfValue getValueAt(int)
    my ($self,$p0) = @_;
    my $getValueAt = JPL::AutoLoader::getmeth('getValueAt',['int'],['com.documentum.fc.common.IDfValue']);
    my $rv = "";
    eval { $rv = $$self->$getValueAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValue);
        return \$rv;
    }
}

sub dump {
	## METHOD: java.lang.String dump()
    my $self = shift;
    my $dump = JPL::AutoLoader::getmeth('dump',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$dump(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRepeatingInt {
	## METHOD: int getRepeatingInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getRepeatingInt = JPL::AutoLoader::getmeth('getRepeatingInt',['java.lang.String','int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getRepeatingInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRepeatingInt {
	## METHOD: void setRepeatingInt(java.lang.String,int,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $setRepeatingInt = JPL::AutoLoader::getmeth('setRepeatingInt',['java.lang.String','int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRepeatingInt($p0,$p1,$p2); };
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
