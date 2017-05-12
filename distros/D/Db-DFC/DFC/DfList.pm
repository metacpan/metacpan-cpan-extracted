# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfList (com.documentum.fc.common.DfList)
# ------------------------------------------------------------------ #

package DfList;
@ISA = (IDfList);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfList';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.common.IDfValue';



sub new {
    my ($class,$p0,$p1) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfList()
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(int)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(int,int)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(java.util.Vector)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(com.documentum.fc.common.IDfList)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(com.documentum.fc.common.IDfList[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(java.lang.String[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(java.lang.Object[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(int[])
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(com.documentum.fc.common.IDfValue[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(com.documentum.fc.common.IDfTime[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(com.documentum.fc.common.IDfId[];)
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(boolean[])
    ## CONSTRUCTOR: com.documentum.fc.common.DfList(double[])

    if (ref($p0) =~ /ARRAY/) {

        if (ref(@$p0[0]) =~ /List/) {
            my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfList[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(@$p0[0] =~ /\d+/) {
            my $new = JPL::AutoLoader::getmeth('new',['int[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(@$p0[0] =~ /\w+/) {
            my $new = JPL::AutoLoader::getmeth('new',['java.lang.String[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(ref(@$p0[0]) =~ /Object/) {
            my $new = JPL::AutoLoader::getmeth('new',['java.lang.Object[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(ref(@$p0[0]) =~ /Value/) {
            my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfValue[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(ref(@$p0[0]) =~ /time/) {
            my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfTime[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        } elsif(ref(@$p0[0]) =~ /Id/) {
            my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfId[]'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        }

## NO boolean[] or double[]

    } elsif ($p0 =~ /\d+/) {

        if ($p1 =~ /\d+/) {
            my $new = JPL::AutoLoader::getmeth('new',['int','int'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0,$p1); };
        } else {
            my $new = JPL::AutoLoader::getmeth('new',['int'],[]);
            eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
        }
    } elsif (ref($p0) =~ /Vector/) {
        my $new = JPL::AutoLoader::getmeth('new',['java.util.Vector'],[]);
        eval { $rv = com::documentum::fc::common::DfList->$new($p0); };
    } elsif (ref($p0) =~ /List/) {
        my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfList'],[]);
        eval { $rv = com::documentum::fc::common::DfList->$new($$p0); };
    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfList->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfList);
        return \$rv;
    }
}

sub append {
	## METHOD: int append(java.lang.Object)
    my ($self,$p0) = @_;
    my $append = JPL::AutoLoader::getmeth('append',['java.lang.Object'],['int']);
    my $rv = "";
    eval { $rv = $$self->$append($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub get {
	## METHOD: java.lang.Object get(int)
    my ($self,$p0) = @_;
    my $get = JPL::AutoLoader::getmeth('get',['int'],['java.lang.Object']);
    my $rv = "";
    eval { $rv = $$self->$get($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub set {
	## METHOD: void set(int,java.lang.Object)
    my ($self,$p0,$p1) = @_;
    my $set = JPL::AutoLoader::getmeth('set',['int','java.lang.Object'],[]);
    my $rv = "";
    eval { $rv = $$self->$set($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getValue {
	## METHOD: com.documentum.fc.common.IDfValue getValue(int)
    my ($self,$p0) = @_;
    my $getValue = JPL::AutoLoader::getmeth('getValue',['int'],['com.documentum.fc.common.IDfValue']);
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
	## METHOD: void remove(int)
    my ($self,$p0) = @_;
    my $remove = JPL::AutoLoader::getmeth('remove',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$remove($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBoolean {
	## METHOD: boolean getBoolean(int)
    my ($self,$p0) = @_;
    my $getBoolean = JPL::AutoLoader::getmeth('getBoolean',['int'],['boolean']);
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
	## METHOD: void removeAll()
    my $self = shift;
    my $removeAll = JPL::AutoLoader::getmeth('removeAll',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAll(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setValue {
	## METHOD: void setValue(int,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $setValue = JPL::AutoLoader::getmeth('setValue',['int','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$setValue($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insert {
	## METHOD: void insert(int,java.lang.Object)
    my ($self,$p0,$p1) = @_;
    my $insert = JPL::AutoLoader::getmeth('insert',['int','java.lang.Object'],[]);
    my $rv = "";
    eval { $rv = $$self->$insert($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTime {
	## METHOD: void setTime(int,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $setTime = JPL::AutoLoader::getmeth('setTime',['int','com.documentum.fc.common.IDfTime'],[]);
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
	## METHOD: com.documentum.fc.common.IDfTime getTime(int)
    my ($self,$p0) = @_;
    my $getTime = JPL::AutoLoader::getmeth('getTime',['int'],['com.documentum.fc.common.IDfTime']);
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

sub getInt {
	## METHOD: int getInt(int)
    my ($self,$p0) = @_;
    my $getInt = JPL::AutoLoader::getmeth('getInt',['int'],['int']);
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
	## METHOD: double getDouble(int)
    my ($self,$p0) = @_;
    my $getDouble = JPL::AutoLoader::getmeth('getDouble',['int'],['double']);
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
	## METHOD: void setBoolean(int,boolean)
    my ($self,$p0,$p1) = @_;
    my $setBoolean = JPL::AutoLoader::getmeth('setBoolean',['int','boolean'],[]);
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
	## METHOD: void setInt(int,int)
    my ($self,$p0,$p1) = @_;
    my $setInt = JPL::AutoLoader::getmeth('setInt',['int','int'],[]);
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
	## METHOD: void setDouble(int,double)
    my ($self,$p0,$p1) = @_;
    my $setDouble = JPL::AutoLoader::getmeth('setDouble',['int','double'],[]);
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
	## METHOD: com.documentum.fc.common.IDfId getId(int)
    my ($self,$p0) = @_;
    my $getId = JPL::AutoLoader::getmeth('getId',['int'],['com.documentum.fc.common.IDfId']);
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
	## METHOD: com.documentum.fc.common.IDfList getList(int)
    my ($self,$p0) = @_;
    my $getList = JPL::AutoLoader::getmeth('getList',['int'],['com.documentum.fc.common.IDfList']);
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
	## METHOD: java.lang.String getString(int)
    my ($self,$p0) = @_;
    my $getString = JPL::AutoLoader::getmeth('getString',['int'],['java.lang.String']);
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
	## METHOD: int appendDouble(double)
    my ($self,$p0) = @_;
    my $appendDouble = JPL::AutoLoader::getmeth('appendDouble',['double'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendDouble($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertTime {
	## METHOD: void insertTime(int,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $insertTime = JPL::AutoLoader::getmeth('insertTime',['int','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertTime($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setId {
	## METHOD: void setId(int,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $setId = JPL::AutoLoader::getmeth('setId',['int','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$setId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertList {
	## METHOD: void insertList(int,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1) = @_;
    my $insertList = JPL::AutoLoader::getmeth('insertList',['int','com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertList($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertInt {
	## METHOD: void insertInt(int,int)
    my ($self,$p0,$p1) = @_;
    my $insertInt = JPL::AutoLoader::getmeth('insertInt',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertBoolean {
	## METHOD: void insertBoolean(int,boolean)
    my ($self,$p0,$p1) = @_;
    my $insertBoolean = JPL::AutoLoader::getmeth('insertBoolean',['int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertBoolean($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findIdIndex {
	## METHOD: int findIdIndex(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $findIdIndex = JPL::AutoLoader::getmeth('findIdIndex',['com.documentum.fc.common.IDfId'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findIdIndex($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendString {
	## METHOD: int appendString(java.lang.String)
    my ($self,$p0) = @_;
    my $appendString = JPL::AutoLoader::getmeth('appendString',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendTime {
	## METHOD: int appendTime(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $appendTime = JPL::AutoLoader::getmeth('appendTime',['com.documentum.fc.common.IDfTime'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendTime($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setString {
	## METHOD: void setString(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setString = JPL::AutoLoader::getmeth('setString',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findTimeIndex {
	## METHOD: int findTimeIndex(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $findTimeIndex = JPL::AutoLoader::getmeth('findTimeIndex',['com.documentum.fc.common.IDfTime'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findTimeIndex($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendList {
	## METHOD: int appendList(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $appendList = JPL::AutoLoader::getmeth('appendList',['com.documentum.fc.common.IDfList'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendList($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setList {
	## METHOD: void setList(int,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1) = @_;
    my $setList = JPL::AutoLoader::getmeth('setList',['int','com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$setList($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertDouble {
	## METHOD: void insertDouble(int,double)
    my ($self,$p0,$p1) = @_;
    my $insertDouble = JPL::AutoLoader::getmeth('insertDouble',['int','double'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertDouble($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertAll {
	## METHOD: void insertAll(int,com.documentum.fc.common.IDfList)
    my ($self,$p0,$p1) = @_;
    my $insertAll = JPL::AutoLoader::getmeth('insertAll',['int','com.documentum.fc.common.IDfList'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertAll($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getElementType {
	## METHOD: int getElementType()
    my $self = shift;
    my $getElementType = JPL::AutoLoader::getmeth('getElementType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getElementType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertId {
	## METHOD: void insertId(int,com.documentum.fc.common.IDfId)
    my ($self,$p0,$p1) = @_;
    my $insertId = JPL::AutoLoader::getmeth('insertId',['int','com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertId($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setElementType {
	## METHOD: void setElementType(int)
    my ($self,$p0) = @_;
    my $setElementType = JPL::AutoLoader::getmeth('setElementType',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setElementType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getElementTypeAt {
	## METHOD: int getElementTypeAt(int)
    my ($self,$p0) = @_;
    my $getElementTypeAt = JPL::AutoLoader::getmeth('getElementTypeAt',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getElementTypeAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findBooleanIndex {
	## METHOD: int findBooleanIndex(boolean)
    my ($self,$p0) = @_;
    my $findBooleanIndex = JPL::AutoLoader::getmeth('findBooleanIndex',['boolean'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findBooleanIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendId {
	## METHOD: int appendId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $appendId = JPL::AutoLoader::getmeth('appendId',['com.documentum.fc.common.IDfId'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendValue {
	## METHOD: int appendValue(com.documentum.fc.common.IDfValue)
    my ($self,$p0) = @_;
    my $appendValue = JPL::AutoLoader::getmeth('appendValue',['com.documentum.fc.common.IDfValue'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendValue($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertString {
	## METHOD: void insertString(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $insertString = JPL::AutoLoader::getmeth('insertString',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendInt {
	## METHOD: int appendInt(int)
    my ($self,$p0) = @_;
    my $appendInt = JPL::AutoLoader::getmeth('appendInt',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendInt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendBoolean {
	## METHOD: int appendBoolean(boolean)
    my ($self,$p0) = @_;
    my $appendBoolean = JPL::AutoLoader::getmeth('appendBoolean',['boolean'],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendBoolean($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findIndex {
	## METHOD: int findIndex(java.lang.Object)
    my ($self,$p0) = @_;
    my $findIndex = JPL::AutoLoader::getmeth('findIndex',['java.lang.Object'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findValueIndex {
	## METHOD: int findValueIndex(com.documentum.fc.common.IDfValue)
    my ($self,$p0) = @_;
    my $findValueIndex = JPL::AutoLoader::getmeth('findValueIndex',['com.documentum.fc.common.IDfValue'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findValueIndex($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findListIndex {
	## METHOD: int findListIndex(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $findListIndex = JPL::AutoLoader::getmeth('findListIndex',['com.documentum.fc.common.IDfList'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findListIndex($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findStringIndex {
	## METHOD: int findStringIndex(java.lang.String)
    my ($self,$p0) = @_;
    my $findStringIndex = JPL::AutoLoader::getmeth('findStringIndex',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findStringIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findIntIndex {
	## METHOD: int findIntIndex(int)
    my ($self,$p0) = @_;
    my $findIntIndex = JPL::AutoLoader::getmeth('findIntIndex',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findIntIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findDoubleIndex {
	## METHOD: int findDoubleIndex(double)
    my ($self,$p0) = @_;
    my $findDoubleIndex = JPL::AutoLoader::getmeth('findDoubleIndex',['double'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findDoubleIndex($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertValue {
	## METHOD: void insertValue(int,com.documentum.fc.common.IDfValue)
    my ($self,$p0,$p1) = @_;
    my $insertValue = JPL::AutoLoader::getmeth('insertValue',['int','com.documentum.fc.common.IDfValue'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertValue($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asArray {
	## METHOD: [Ljava.lang.Object; asArray()
    my $self = shift;
    my $asArray = JPL::AutoLoader::getmeth('asArray',[],['[Ljava.lang.Object;']);
    my $rv = "";
    eval { $rv = $$self->$asArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asStringArray {
	## METHOD: [Ljava.lang.String; asStringArray()
    my $self = shift;
    my $asStringArray = JPL::AutoLoader::getmeth('asStringArray',[],['[Ljava.lang.String;']);
    my $rv = "";
    eval { $rv = $$self->$asStringArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asIntArray {
	## METHOD: [I asIntArray()
    my $self = shift;
    my $asIntArray = JPL::AutoLoader::getmeth('asIntArray',[],['[I']);
    my $rv = "";
    eval { $rv = $$self->$asIntArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asDoubleArray {
	## METHOD: [D asDoubleArray()
    my $self = shift;
    my $asDoubleArray = JPL::AutoLoader::getmeth('asDoubleArray',[],['[D']);
    my $rv = "";
    eval { $rv = $$self->$asDoubleArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asBooleanArray {
	## METHOD: [Z asBooleanArray()
    my $self = shift;
    my $asBooleanArray = JPL::AutoLoader::getmeth('asBooleanArray',[],['[Z']);
    my $rv = "";
    eval { $rv = $$self->$asBooleanArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asIdArray {
	## METHOD: [Lcom.documentum.fc.common.IDfId; asIdArray()
    my $self = shift;
    my $asIdArray = JPL::AutoLoader::getmeth('asIdArray',[],['[Lcom.documentum.fc.common.IDfId;']);
    my $rv = "";
    eval { $rv = $$self->$asIdArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asTimeArray {
	## METHOD: [Lcom.documentum.fc.common.IDfTime; asTimeArray()
    my $self = shift;
    my $asTimeArray = JPL::AutoLoader::getmeth('asTimeArray',[],['[Lcom.documentum.fc.common.IDfTime;']);
    my $rv = "";
    eval { $rv = $$self->$asTimeArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asValueArray {
	## METHOD: [Lcom.documentum.fc.common.IDfValue; asValueArray()
    my $self = shift;
    my $asValueArray = JPL::AutoLoader::getmeth('asValueArray',[],['[Lcom.documentum.fc.common.IDfValue;']);
    my $rv = "";
    eval { $rv = $$self->$asValueArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asListArray {
	## METHOD: [Lcom.documentum.fc.common.IDfList; asListArray()
    my $self = shift;
    my $asListArray = JPL::AutoLoader::getmeth('asListArray',[],['[Lcom.documentum.fc.common.IDfList;']);
    my $rv = "";
    eval { $rv = $$self->$asListArray(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub enumElements {
	## METHOD: java.util.Enumeration enumElements()
    my $self = shift;
    my $enumElements = JPL::AutoLoader::getmeth('enumElements',[],['java.util.Enumeration']);
    my $rv = "";
    eval { $rv = $$self->$enumElements(); };
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
