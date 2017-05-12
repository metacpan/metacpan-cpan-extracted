# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryMgr (com.documentum.fc.client.qb.IDfQueryMgr)
# ------------------------------------------------------------------ #

package IDfQueryMgr;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryMgr';
use JPL::Class 'com.documentum.fc.client.qb.IDfQueryResultItem';
use JPL::Class 'com.documentum.fc.client.qb.IDfQueryFullText';
use JPL::Class 'com.documentum.fc.client.IDfSession';
use JPL::Class 'com.documentum.fc.common.IDfList';
use JPL::Class 'com.documentum.fc.client.IDfEnumeration';
use JPL::Class 'com.documentum.fc.client.qb.IDfAttrLine';
use JPL::Class 'com.documentum.fc.client.qb.IDfQueryLocation';

use constant DC_SEARCH_E_DB_MISSING_TYPE => 8992;
use constant DC_SEARCH_E_NOT_ALL_DB_QUERIED => 8993;
use constant DC_SEARCH_E_NO_LOCATION_SPECIFIED => 8994;
use constant DC_SEARCH_E_INVALID_PARAMETER => 9024;
use constant DC_SEARCH_E_NO_DISPLAY_ATTRIBUTE => 9025;
use constant DC_SEARCH_E_NO_OBJTYPE_ATTRIBUTE => 9026;
use constant DC_SEARCH_E_SEARCH_FAILED => 9027;
use constant DC_SEARCH_E_LOGIN_FAILED => 9028;
use constant DC_SEARCH_E_SELF_TEST_FAILED => 9029;
use constant DC_SEARCH_E_NOT_IMPLEMENTED => 9030;
use constant DC_SEARCH_E_INVALID_OBJ_TYPE => 9031;
use constant DC_SEARCH_E_NOT_INITIALIZED => 9032;
use constant DC_SEARCH_E_ALREADY_SEARCHING => 9033;
use constant AND => 0;
use constant OR => 1;

sub save {
	## METHOD: boolean save(java.lang.String)
    my ($self,$p0) = @_;
    my $save = JPL::AutoLoader::getmeth('save',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$save($p0); };
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

sub open {
	## METHOD: boolean open(java.lang.String)
    my ($self,$p0) = @_;
    my $open = JPL::AutoLoader::getmeth('open',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$open($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub initialize {
	## METHOD: void initialize(com.documentum.fc.client.IDfSession)
    my ($self,$p0) = @_;
    my $initialize = JPL::AutoLoader::getmeth('initialize',['com.documentum.fc.client.IDfSession'],[]);
    my $rv = "";
    eval { $rv = $$self->$initialize($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLocation {
	## METHOD: com.documentum.fc.client.qb.IDfQueryLocation getLocation(int)
    my ($self,$p0) = @_;
    my $getLocation = JPL::AutoLoader::getmeth('getLocation',['int'],['com.documentum.fc.client.qb.IDfQueryLocation']);
    my $rv = "";
    eval { $rv = $$self->$getLocation($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfQueryLocation);
        return \$rv;
    }
}

sub isForm {
	## METHOD: boolean isForm()
    my $self = shift;
    my $isForm = JPL::AutoLoader::getmeth('isForm',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isForm(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertHiddenAttr {
	## METHOD: void insertHiddenAttr(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $insertHiddenAttr = JPL::AutoLoader::getmeth('insertHiddenAttr',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertHiddenAttr($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAttrLines {
	## METHOD: boolean removeAttrLines(int,int,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $removeAttrLines = JPL::AutoLoader::getmeth('removeAttrLines',['int','int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$removeAttrLines($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTargetID {
	## METHOD: void setTargetID(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $setTargetID = JPL::AutoLoader::getmeth('setTargetID',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTargetID($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAttrLineGroupOp {
	## METHOD: boolean setAttrLineGroupOp(int,int)
    my ($self,$p0,$p1) = @_;
    my $setAttrLineGroupOp = JPL::AutoLoader::getmeth('setAttrLineGroupOp',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$setAttrLineGroupOp($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrLineGroupOp {
	## METHOD: int getAttrLineGroupOp(int)
    my ($self,$p0) = @_;
    my $getAttrLineGroupOp = JPL::AutoLoader::getmeth('getAttrLineGroupOp',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAttrLineGroupOp($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addIDfQueryResultListener {
	## METHOD: void addIDfQueryResultListener(com.documentum.fc.client.qb.IDfQueryResultListener)
    my ($self,$p0) = @_;
    my $addIDfQueryResultListener = JPL::AutoLoader::getmeth('addIDfQueryResultListener',['com.documentum.fc.client.qb.IDfQueryResultListener'],[]);
    my $rv = "";
    eval { $rv = $$self->$addIDfQueryResultListener($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAllResultItems {
	## METHOD: com.documentum.fc.common.IDfList getAllResultItems()
    my $self = shift;
    my $getAllResultItems = JPL::AutoLoader::getmeth('getAllResultItems',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getAllResultItems(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub getErrorDocbaseName {
	## METHOD: java.lang.String getErrorDocbaseName(int)
    my ($self,$p0) = @_;
    my $getErrorDocbaseName = JPL::AutoLoader::getmeth('getErrorDocbaseName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getErrorDocbaseName($p0); };
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

sub setSession {
	## METHOD: void setSession(com.documentum.fc.client.IDfSession)
    my ($self,$p0) = @_;
    my $setSession = JPL::AutoLoader::getmeth('setSession',['com.documentum.fc.client.IDfSession'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSession($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResultItemCount {
	## METHOD: int getResultItemCount()
    my $self = shift;
    my $getResultItemCount = JPL::AutoLoader::getmeth('getResultItemCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getResultItemCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSortAttrCount {
	## METHOD: int getSortAttrCount()
    my $self = shift;
    my $getSortAttrCount = JPL::AutoLoader::getmeth('getSortAttrCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getSortAttrCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllLocations {
	## METHOD: void removeAllLocations()
    my $self = shift;
    my $removeAllLocations = JPL::AutoLoader::getmeth('removeAllLocations',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllLocations(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub splitAttrLineGroup {
	## METHOD: boolean splitAttrLineGroup(int,int)
    my ($self,$p0,$p1) = @_;
    my $splitAttrLineGroup = JPL::AutoLoader::getmeth('splitAttrLineGroup',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$splitAttrLineGroup($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isServerSorting {
	## METHOD: boolean isServerSorting()
    my $self = shift;
    my $isServerSorting = JPL::AutoLoader::getmeth('isServerSorting',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isServerSorting(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isQueryMgrSorting {
	## METHOD: boolean isQueryMgrSorting()
    my $self = shift;
    my $isQueryMgrSorting = JPL::AutoLoader::getmeth('isQueryMgrSorting',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isQueryMgrSorting(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDocbaseSortDescending {
	## METHOD: void setDocbaseSortDescending(boolean)
    my ($self,$p0) = @_;
    my $setDocbaseSortDescending = JPL::AutoLoader::getmeth('setDocbaseSortDescending',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDocbaseSortDescending($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeSortAttrs {
	## METHOD: void removeSortAttrs(int,int)
    my ($self,$p0,$p1) = @_;
    my $removeSortAttrs = JPL::AutoLoader::getmeth('removeSortAttrs',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeSortAttrs($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSearchedDocbases {
	## METHOD: com.documentum.fc.common.IDfList getSearchedDocbases()
    my $self = shift;
    my $getSearchedDocbases = JPL::AutoLoader::getmeth('getSearchedDocbases',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getSearchedDocbases(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub removeLocations {
	## METHOD: void removeLocations(int,int)
    my ($self,$p0,$p1) = @_;
    my $removeLocations = JPL::AutoLoader::getmeth('removeLocations',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeLocations($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResultItem {
	## METHOD: com.documentum.fc.client.qb.IDfQueryResultItem getResultItem(int)
    my ($self,$p0) = @_;
    my $getResultItem = JPL::AutoLoader::getmeth('getResultItem',['int'],['com.documentum.fc.client.qb.IDfQueryResultItem']);
    my $rv = "";
    eval { $rv = $$self->$getResultItem($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfQueryResultItem);
        return \$rv;
    }
}

sub isDocbaseSortDescending {
	## METHOD: boolean isDocbaseSortDescending()
    my $self = shift;
    my $isDocbaseSortDescending = JPL::AutoLoader::getmeth('isDocbaseSortDescending',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDocbaseSortDescending(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setIgnoreCaseSearching {
	## METHOD: void setIgnoreCaseSearching(boolean)
    my ($self,$p0) = @_;
    my $setIgnoreCaseSearching = JPL::AutoLoader::getmeth('setIgnoreCaseSearching',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setIgnoreCaseSearching($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertAttrLine {
	## METHOD: com.documentum.fc.client.qb.IDfAttrLine insertAttrLine(int,int,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertAttrLine = JPL::AutoLoader::getmeth('insertAttrLine',['int','int','int'],['com.documentum.fc.client.qb.IDfAttrLine']);
    my $rv = "";
    eval { $rv = $$self->$insertAttrLine($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfAttrLine);
        return \$rv;
    }
}

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

sub setObjectType {
	## METHOD: int setObjectType(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectType = JPL::AutoLoader::getmeth('setObjectType',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$setObjectType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertDisplayAttr {
	## METHOD: void insertDisplayAttr(int,java.lang.String,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertDisplayAttr = JPL::AutoLoader::getmeth('insertDisplayAttr',['int','java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertDisplayAttr($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHiddenAttr {
	## METHOD: java.lang.String getHiddenAttr(int)
    my ($self,$p0) = @_;
    my $getHiddenAttr = JPL::AutoLoader::getmeth('getHiddenAttr',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getHiddenAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setHiddenAttr {
	## METHOD: void setHiddenAttr(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setHiddenAttr = JPL::AutoLoader::getmeth('setHiddenAttr',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setHiddenAttr($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findHiddenAttr {
	## METHOD: int findHiddenAttr(java.lang.String)
    my ($self,$p0) = @_;
    my $findHiddenAttr = JPL::AutoLoader::getmeth('findHiddenAttr',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findHiddenAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub startSearch {
	## METHOD: int startSearch()
    my $self = shift;
    my $startSearch = JPL::AutoLoader::getmeth('startSearch',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$startSearch(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub stopSearch {
	## METHOD: void stopSearch()
    my $self = shift;
    my $stopSearch = JPL::AutoLoader::getmeth('stopSearch',[],[]);
    my $rv = "";
    eval { $rv = $$self->$stopSearch(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSearchFinished {
	## METHOD: boolean isSearchFinished()
    my $self = shift;
    my $isSearchFinished = JPL::AutoLoader::getmeth('isSearchFinished',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSearchFinished(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDisplayAttrWidth {
	## METHOD: int getDisplayAttrWidth(int)
    my ($self,$p0) = @_;
    my $getDisplayAttrWidth = JPL::AutoLoader::getmeth('getDisplayAttrWidth',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDisplayAttrWidth($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllResultItems {
	## METHOD: void removeAllResultItems()
    my $self = shift;
    my $removeAllResultItems = JPL::AutoLoader::getmeth('removeAllResultItems',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllResultItems(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDisplayAttrWidth {
	## METHOD: void setDisplayAttrWidth(int,int)
    my ($self,$p0,$p1) = @_;
    my $setDisplayAttrWidth = JPL::AutoLoader::getmeth('setDisplayAttrWidth',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDisplayAttrWidth($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDisplayAttr {
	## METHOD: java.lang.String getDisplayAttr(int)
    my ($self,$p0) = @_;
    my $getDisplayAttr = JPL::AutoLoader::getmeth('getDisplayAttr',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDisplayAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDisplayAttr {
	## METHOD: void setDisplayAttr(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setDisplayAttr = JPL::AutoLoader::getmeth('setDisplayAttr',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDisplayAttr($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findDisplayAttr {
	## METHOD: int findDisplayAttr(java.lang.String)
    my ($self,$p0) = @_;
    my $findDisplayAttr = JPL::AutoLoader::getmeth('findDisplayAttr',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findDisplayAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertSortAttr {
	## METHOD: void insertSortAttr(int,java.lang.String,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $insertSortAttr = JPL::AutoLoader::getmeth('insertSortAttr',['int','java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertSortAttr($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertLocation {
	## METHOD: com.documentum.fc.client.qb.IDfQueryLocation insertLocation(int)
    my ($self,$p0) = @_;
    my $insertLocation = JPL::AutoLoader::getmeth('insertLocation',['int'],['com.documentum.fc.client.qb.IDfQueryLocation']);
    my $rv = "";
    eval { $rv = $$self->$insertLocation($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfQueryLocation);
        return \$rv;
    }
}

sub setSortAttrDescend {
	## METHOD: void setSortAttrDescend(int,boolean)
    my ($self,$p0,$p1) = @_;
    my $setSortAttrDescend = JPL::AutoLoader::getmeth('setSortAttrDescend',['int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSortAttrDescend($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getInformation {
	## METHOD: java.lang.String getInformation()
    my $self = shift;
    my $getInformation = JPL::AutoLoader::getmeth('getInformation',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getInformation(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setInformation {
	## METHOD: void setInformation(java.lang.String)
    my ($self,$p0) = @_;
    my $setInformation = JPL::AutoLoader::getmeth('setInformation',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setInformation($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getErrorDQL {
	## METHOD: java.lang.String getErrorDQL(int)
    my ($self,$p0) = @_;
    my $getErrorDQL = JPL::AutoLoader::getmeth('getErrorDQL',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getErrorDQL($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFindHidden {
	## METHOD: boolean getFindHidden()
    my $self = shift;
    my $getFindHidden = JPL::AutoLoader::getmeth('getFindHidden',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFindHidden(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFindHidden {
	## METHOD: void setFindHidden(boolean)
    my ($self,$p0) = @_;
    my $setFindHidden = JPL::AutoLoader::getmeth('setFindHidden',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFindHidden($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSortAttrDescend {
	## METHOD: boolean isSortAttrDescend(int)
    my ($self,$p0) = @_;
    my $isSortAttrDescend = JPL::AutoLoader::getmeth('isSortAttrDescend',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSortAttrDescend($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllHiddenAttrs {
	## METHOD: void removeAllHiddenAttrs()
    my $self = shift;
    my $removeAllHiddenAttrs = JPL::AutoLoader::getmeth('removeAllHiddenAttrs',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllHiddenAttrs(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isIgnoreCaseSearching {
	## METHOD: boolean isIgnoreCaseSearching()
    my $self = shift;
    my $isIgnoreCaseSearching = JPL::AutoLoader::getmeth('isIgnoreCaseSearching',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isIgnoreCaseSearching(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setIgnoreCaseSorting {
	## METHOD: void setIgnoreCaseSorting(boolean)
    my ($self,$p0) = @_;
    my $setIgnoreCaseSorting = JPL::AutoLoader::getmeth('setIgnoreCaseSorting',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setIgnoreCaseSorting($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAvailObjectTypes {
	## METHOD: com.documentum.fc.client.IDfEnumeration getAvailObjectTypes()
    my $self = shift;
    my $getAvailObjectTypes = JPL::AutoLoader::getmeth('getAvailObjectTypes',[],['com.documentum.fc.client.IDfEnumeration']);
    my $rv = "";
    eval { $rv = $$self->$getAvailObjectTypes(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfEnumeration);
        return \$rv;
    }
}

sub setSortedByDocbase {
	## METHOD: void setSortedByDocbase(boolean)
    my ($self,$p0) = @_;
    my $setSortedByDocbase = JPL::AutoLoader::getmeth('setSortedByDocbase',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSortedByDocbase($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFindAllVersions {
	## METHOD: void setFindAllVersions(boolean)
    my ($self,$p0) = @_;
    my $setFindAllVersions = JPL::AutoLoader::getmeth('setFindAllVersions',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFindAllVersions($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFindAllVersions {
	## METHOD: boolean getFindAllVersions()
    my $self = shift;
    my $getFindAllVersions = JPL::AutoLoader::getmeth('getFindAllVersions',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFindAllVersions(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrLine {
	## METHOD: com.documentum.fc.client.qb.IDfAttrLine getAttrLine(int,int)
    my ($self,$p0,$p1) = @_;
    my $getAttrLine = JPL::AutoLoader::getmeth('getAttrLine',['int','int'],['com.documentum.fc.client.qb.IDfAttrLine']);
    my $rv = "";
    eval { $rv = $$self->$getAttrLine($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfAttrLine);
        return \$rv;
    }
}

sub copyAttrLine {
	## METHOD: boolean copyAttrLine(int,int)
    my ($self,$p0,$p1) = @_;
    my $copyAttrLine = JPL::AutoLoader::getmeth('copyAttrLine',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$copyAttrLine($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub joinAttrLineGroups {
	## METHOD: boolean joinAttrLineGroups(int,int)
    my ($self,$p0,$p1) = @_;
    my $joinAttrLineGroups = JPL::AutoLoader::getmeth('joinAttrLineGroups',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$joinAttrLineGroups($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseName {
	## METHOD: java.lang.String getDocbaseName()
    my $self = shift;
    my $getDocbaseName = JPL::AutoLoader::getmeth('getDocbaseName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getErrorMessage {
	## METHOD: java.lang.String getErrorMessage(int)
    my ($self,$p0) = @_;
    my $getErrorMessage = JPL::AutoLoader::getmeth('getErrorMessage',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getErrorMessage($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSortAttr {
	## METHOD: java.lang.String getSortAttr(int)
    my ($self,$p0) = @_;
    my $getSortAttr = JPL::AutoLoader::getmeth('getSortAttr',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSortAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSortAttr {
	## METHOD: void setSortAttr(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setSortAttr = JPL::AutoLoader::getmeth('setSortAttr',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSortAttr($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findSortAttr {
	## METHOD: int findSortAttr(java.lang.String)
    my ($self,$p0) = @_;
    my $findSortAttr = JPL::AutoLoader::getmeth('findSortAttr',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$findSortAttr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllAttrLines {
	## METHOD: void removeAllAttrLines()
    my $self = shift;
    my $removeAllAttrLines = JPL::AutoLoader::getmeth('removeAllAttrLines',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllAttrLines(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeIDfQueryResultListener {
	## METHOD: void removeIDfQueryResultListener(com.documentum.fc.client.qb.IDfQueryResultListener)
    my ($self,$p0) = @_;
    my $removeIDfQueryResultListener = JPL::AutoLoader::getmeth('removeIDfQueryResultListener',['com.documentum.fc.client.qb.IDfQueryResultListener'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeIDfQueryResultListener($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHiddenAttrCount {
	## METHOD: int getHiddenAttrCount()
    my $self = shift;
    my $getHiddenAttrCount = JPL::AutoLoader::getmeth('getHiddenAttrCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getHiddenAttrCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getErrorCount {
	## METHOD: int getErrorCount()
    my $self = shift;
    my $getErrorCount = JPL::AutoLoader::getmeth('getErrorCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getErrorCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDisplayAttrCount {
	## METHOD: int getDisplayAttrCount()
    my $self = shift;
    my $getDisplayAttrCount = JPL::AutoLoader::getmeth('getDisplayAttrCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDisplayAttrCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLocationCount {
	## METHOD: int getLocationCount()
    my $self = shift;
    my $getLocationCount = JPL::AutoLoader::getmeth('getLocationCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getLocationCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAttrLineCount {
	## METHOD: int getAttrLineCount()
    my $self = shift;
    my $getAttrLineCount = JPL::AutoLoader::getmeth('getAttrLineCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAttrLineCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub constructDefault {
	## METHOD: void constructDefault(int)
    my ($self,$p0) = @_;
    my $constructDefault = JPL::AutoLoader::getmeth('constructDefault',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$constructDefault($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDQL {
	## METHOD: java.lang.String getDQL()
    my $self = shift;
    my $getDQL = JPL::AutoLoader::getmeth('getDQL',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDQL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSortedByDocbase {
	## METHOD: boolean isSortedByDocbase()
    my $self = shift;
    my $isSortedByDocbase = JPL::AutoLoader::getmeth('isSortedByDocbase',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSortedByDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllDisplayAttrs {
	## METHOD: void removeAllDisplayAttrs()
    my $self = shift;
    my $removeAllDisplayAttrs = JPL::AutoLoader::getmeth('removeAllDisplayAttrs',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllDisplayAttrs(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setServerSorting {
	## METHOD: void setServerSorting(boolean)
    my ($self,$p0) = @_;
    my $setServerSorting = JPL::AutoLoader::getmeth('setServerSorting',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setServerSorting($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setQueryMgrSorting {
	## METHOD: void setQueryMgrSorting(boolean)
    my ($self,$p0) = @_;
    my $setQueryMgrSorting = JPL::AutoLoader::getmeth('setQueryMgrSorting',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setQueryMgrSorting($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isIgnoreCaseSorting {
	## METHOD: boolean isIgnoreCaseSorting()
    my $self = shift;
    my $isIgnoreCaseSorting = JPL::AutoLoader::getmeth('isIgnoreCaseSorting',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isIgnoreCaseSorting(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeHiddenAttrs {
	## METHOD: void removeHiddenAttrs(int,int)
    my ($self,$p0,$p1) = @_;
    my $removeHiddenAttrs = JPL::AutoLoader::getmeth('removeHiddenAttrs',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeHiddenAttrs($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub reSort {
	## METHOD: boolean reSort()
    my $self = shift;
    my $reSort = JPL::AutoLoader::getmeth('reSort',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$reSort(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFullText {
	## METHOD: com.documentum.fc.client.qb.IDfQueryFullText getFullText()
    my $self = shift;
    my $getFullText = JPL::AutoLoader::getmeth('getFullText',[],['com.documentum.fc.client.qb.IDfQueryFullText']);
    my $rv = "";
    eval { $rv = $$self->$getFullText(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfQueryFullText);
        return \$rv;
    }
}

sub removeAllFullText {
	## METHOD: void removeAllFullText()
    my $self = shift;
    my $removeAllFullText = JPL::AutoLoader::getmeth('removeAllFullText',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllFullText(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeDisplayAttrs {
	## METHOD: void removeDisplayAttrs(int,int)
    my ($self,$p0,$p1) = @_;
    my $removeDisplayAttrs = JPL::AutoLoader::getmeth('removeDisplayAttrs',['int','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeDisplayAttrs($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllSortAttrs {
	## METHOD: void removeAllSortAttrs()
    my $self = shift;
    my $removeAllSortAttrs = JPL::AutoLoader::getmeth('removeAllSortAttrs',[],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllSortAttrs(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub moveAttrLine {
	## METHOD: boolean moveAttrLine(int,int,int,int)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $moveAttrLine = JPL::AutoLoader::getmeth('moveAttrLine',['int','int','int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$moveAttrLine($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub pasteAttrLine {
	## METHOD: boolean pasteAttrLine(int,int)
    my ($self,$p0,$p1) = @_;
    my $pasteAttrLine = JPL::AutoLoader::getmeth('pasteAttrLine',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$pasteAttrLine($p0,$p1); };
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
