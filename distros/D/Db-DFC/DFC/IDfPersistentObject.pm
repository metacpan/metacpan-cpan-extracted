# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfPersistentObject (com.documentum.fc.client.IDfPersistentObject)
# ------------------------------------------------------------------ #

package IDfPersistentObject;
@ISA = (IDfTypedObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfPersistentObject';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.client.IDfSession';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfValue';
use JPL::Class 'com.documentum.fc.client.IDfValidator';
use JPL::Class 'com.documentum.fc.common.IDfAttr';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.client.IDfRelation';
use JPL::Class 'com.documentum.fc.client.IDfType';
use JPL::Class 'com.documentum.fc.client.IDfCollection';


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

sub destroy {
	## METHOD: void destroy()
    my $self = shift;
    my $destroy = JPL::AutoLoader::getmeth('destroy',[],[]);
    my $rv = "";
    eval { $rv = $$self->$destroy(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub save {
	## METHOD: void save()
    my $self = shift;
    my $save = JPL::AutoLoader::getmeth('save',[],[]);
    my $rv = "";
    eval { $rv = $$self->$save(); };
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

sub getType {
	## METHOD: com.documentum.fc.client.IDfType getType()
    my $self = shift;
    my $getType = JPL::AutoLoader::getmeth('getType',[],['com.documentum.fc.client.IDfType']);
    my $rv = "";
    eval { $rv = $$self->$getType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfType);
        return \$rv;
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

sub apiSet {
	## METHOD: boolean apiSet(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $apiSet = JPL::AutoLoader::getmeth('apiSet',['java.lang.String','java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$apiSet($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub apiGet {
	## METHOD: java.lang.String apiGet(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $apiGet = JPL::AutoLoader::getmeth('apiGet',['java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$apiGet($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub apiExec {
	## METHOD: boolean apiExec(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $apiExec = JPL::AutoLoader::getmeth('apiExec',['java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$apiExec($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeChildRelative {
	## METHOD: void removeChildRelative(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $removeChildRelative = JPL::AutoLoader::getmeth('removeChildRelative',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeChildRelative($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrAssistance {
	## METHOD: com.documentum.fc.common.IDfList getAttrAssistance(java.lang.String)
    my ($self,$p0) = @_;
    my $getAttrAssistance = JPL::AutoLoader::getmeth('getAttrAssistance',['java.lang.String'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getAttrAssistance($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
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

sub revert {
	## METHOD: void revert()
    my $self = shift;
    my $revert = JPL::AutoLoader::getmeth('revert',[],[]);
    my $rv = "";
    eval { $rv = $$self->$revert(); };
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

sub signoff {
	## METHOD: void signoff(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $signoff = JPL::AutoLoader::getmeth('signoff',['java.lang.String','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$signoff($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zpobj_reserved11 {
	## METHOD: void zpobj_reserved11()
    my $self = shift;
    my $zpobj_reserved11 = JPL::AutoLoader::getmeth('zpobj_reserved11',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved11(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChildRelatives {
	## METHOD: com.documentum.fc.client.IDfCollection getChildRelatives(java.lang.String)
    my ($self,$p0) = @_;
    my $getChildRelatives = JPL::AutoLoader::getmeth('getChildRelatives',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getChildRelatives($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub zpobj_reserved8 {
	## METHOD: void zpobj_reserved8()
    my $self = shift;
    my $zpobj_reserved8 = JPL::AutoLoader::getmeth('zpobj_reserved8',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved8(); };
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

sub validateAttrRules {
	## METHOD: void validateAttrRules(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $validateAttrRules = JPL::AutoLoader::getmeth('validateAttrRules',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAttrRules($p0,$p1); };
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

sub getVStamp {
	## METHOD: int getVStamp()
    my $self = shift;
    my $getVStamp = JPL::AutoLoader::getmeth('getVStamp',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVStamp(); };
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

sub validateAttrRulesWithValue {
	## METHOD: void validateAttrRulesWithValue(java.lang.String,java.lang.String,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $validateAttrRulesWithValue = JPL::AutoLoader::getmeth('validateAttrRulesWithValue',['java.lang.String','java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAttrRulesWithValue($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zpobj_reserved5 {
	## METHOD: void zpobj_reserved5()
    my $self = shift;
    my $zpobj_reserved5 = JPL::AutoLoader::getmeth('zpobj_reserved5',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved5(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addChildRelative {
	## METHOD: com.documentum.fc.client.IDfRelation addChildRelative(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,boolean,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $addChildRelative = JPL::AutoLoader::getmeth('addChildRelative',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','boolean','java.lang.String'],['com.documentum.fc.client.IDfRelation']);
    my $rv = "";
    eval { $rv = $$self->$addChildRelative($p0,$$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfRelation);
        return \$rv;
    }
}

sub zpobj_reserved7 {
	## METHOD: void zpobj_reserved7()
    my $self = shift;
    my $zpobj_reserved7 = JPL::AutoLoader::getmeth('zpobj_reserved7',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved7(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateAttrRulesWithValues {
	## METHOD: void validateAttrRulesWithValues(java.lang.String,com.documentum.fc.common.IDfList,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $validateAttrRulesWithValues = JPL::AutoLoader::getmeth('validateAttrRulesWithValues',['java.lang.String','com.documentum.fc.common.IDfList','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAttrRulesWithValues($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isDirty {
	## METHOD: boolean isDirty()
    my $self = shift;
    my $isDirty = JPL::AutoLoader::getmeth('isDirty',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDirty(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zpobj_reserved12 {
	## METHOD: void zpobj_reserved12()
    my $self = shift;
    my $zpobj_reserved12 = JPL::AutoLoader::getmeth('zpobj_reserved12',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved12(); };
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

sub getValidator {
	## METHOD: com.documentum.fc.client.IDfValidator getValidator()
    my $self = shift;
    my $getValidator = JPL::AutoLoader::getmeth('getValidator',[],['com.documentum.fc.client.IDfValidator']);
    my $rv = "";
    eval { $rv = $$self->$getValidator(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfValidator);
        return \$rv;
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

sub zpobj_reserved4 {
	## METHOD: void zpobj_reserved4()
    my $self = shift;
    my $zpobj_reserved4 = JPL::AutoLoader::getmeth('zpobj_reserved4',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved4(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub isNew {
	## METHOD: boolean isNew()
    my $self = shift;
    my $isNew = JPL::AutoLoader::getmeth('isNew',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNew(); };
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

sub getParentRelatives {
	## METHOD: com.documentum.fc.client.IDfCollection getParentRelatives(java.lang.String)
    my ($self,$p0) = @_;
    my $getParentRelatives = JPL::AutoLoader::getmeth('getParentRelatives',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getParentRelatives($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub validateAllRules {
	## METHOD: void validateAllRules(int)
    my ($self,$p0) = @_;
    my $validateAllRules = JPL::AutoLoader::getmeth('validateAllRules',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateAllRules($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateObjRules {
	## METHOD: void validateObjRules(int)
    my ($self,$p0) = @_;
    my $validateObjRules = JPL::AutoLoader::getmeth('validateObjRules',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateObjRules($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isDeleted {
	## METHOD: boolean isDeleted()
    my $self = shift;
    my $isDeleted = JPL::AutoLoader::getmeth('isDeleted',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDeleted(); };
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

sub removeParentRelative {
	## METHOD: void removeParentRelative(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $removeParentRelative = JPL::AutoLoader::getmeth('removeParentRelative',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeParentRelative($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateObjRulesWithValues {
	## METHOD: void validateObjRulesWithValues(com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $validateObjRulesWithValues = JPL::AutoLoader::getmeth('validateObjRulesWithValues',['com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateObjRulesWithValues($$p0,$$p1,$p2); };
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

sub getAttrAsstDependencies {
	## METHOD: com.documentum.fc.common.IDfList getAttrAsstDependencies(java.lang.String)
    my ($self,$p0) = @_;
    my $getAttrAsstDependencies = JPL::AutoLoader::getmeth('getAttrAsstDependencies',['java.lang.String'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getAttrAsstDependencies($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getAttrAssistanceWithValues {
	## METHOD: com.documentum.fc.common.IDfList getAttrAssistanceWithValues(java.lang.String,com.documentum.fc.common.IDfList,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1,$p2) = @_;
    my $getAttrAssistanceWithValues = JPL::AutoLoader::getmeth('getAttrAssistanceWithValues',['java.lang.String','com.documentum.fc.common.IDfList','com.documentum.fc.common.IDfList'],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getAttrAssistanceWithValues($p0,$$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub zpobj_reserved6 {
	## METHOD: void zpobj_reserved6()
    my $self = shift;
    my $zpobj_reserved6 = JPL::AutoLoader::getmeth('zpobj_reserved6',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved6(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addParentRelative {
	## METHOD: com.documentum.fc.client.IDfRelation addParentRelative(java.lang.String,com.documentum.fc.common.IDfId,java.lang.String,boolean,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $addParentRelative = JPL::AutoLoader::getmeth('addParentRelative',['java.lang.String','com.documentum.fc.common.IDfId','java.lang.String','boolean','java.lang.String'],['com.documentum.fc.client.IDfRelation']);
    my $rv = "";
    eval { $rv = $$self->$addParentRelative($p0,$$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfRelation);
        return \$rv;
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

sub zpobj_reserved9 {
	## METHOD: void zpobj_reserved9()
    my $self = shift;
    my $zpobj_reserved9 = JPL::AutoLoader::getmeth('zpobj_reserved9',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved9(); };
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

sub zpobj_reserved10 {
	## METHOD: void zpobj_reserved10()
    my $self = shift;
    my $zpobj_reserved10 = JPL::AutoLoader::getmeth('zpobj_reserved10',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zpobj_reserved10(); };
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

sub isReplica {
	## METHOD: boolean isReplica()
    my $self = shift;
    my $isReplica = JPL::AutoLoader::getmeth('isReplica',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isReplica(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub fetch {
	## METHOD: boolean fetch(java.lang.String)
    my ($self,$p0) = @_;
    my $fetch = JPL::AutoLoader::getmeth('fetch',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$fetch($p0); };
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
