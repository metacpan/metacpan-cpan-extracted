# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfOperationError (com.documentum.operations.IDfOperationError)
# ------------------------------------------------------------------ #

package IDfOperationError;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfOperationError';
use JPL::Class 'com.documentum.operations.IDfOperationNode';
use JPL::Class 'com.documentum.fc.common.IDfException';
use JPL::Class 'com.documentum.operations.IDfOperation';

use constant OBJECT_LOCKED_BY_OTHER_USER => 1000;
use constant COULD_NOT_LOCK_OBJECT => 1001;
use constant ERROR_ADDING_CHECKOUT_ITEM => 1002;
use constant OVERWRITE_EXISTING_FILE => 1003;
use constant DOCUMENT_HAS_NO_CONTENT => 1004;
use constant COULD_NOT_GET_CONTENT_FILE => 1005;
use constant COULD_NOT_ADD_AS_LOCAL_COPY => 1006;
use constant COULD_NOT_PATCH_REFERENCES => 1007;
use constant COULD_NOT_UNLOCK_OBJECT => 1008;
use constant COULD_NOT_DELETE_LOCAL_FILE => 1009;
use constant COULD_NOT_CREATE_OBJECT_IMPORT => 1010;
use constant ERROR_DURING_SETFILE => 1011;
use constant COULD_NOT_SAVE_NEW_IMPORT_OBJECT => 1012;
use constant COULD_NOT_CHECKIN_OBJECT => 1013;
use constant ERROR_DURING_REG_UPDATE_CHECKIN => 1014;
use constant COULD_NOT_COPY_OBJECT => 1015;
use constant COULD_NOT_LINK_TO_DESTINATION_FOLDER => 1016;
use constant COULD_NOT_RENAME_OBJECT => 1017;
use constant COULD_NOT_FIX_RELATIONSHIPS => 1018;
use constant COULD_NOT_DELETE_OBJECT => 1019;
use constant ERROR_COMPLETING_DELETION => 1020;
use constant ERROR_NOT_ALL_CD_REFS_PATCHED => 1021;
use constant FOLDER_NAME_COLLISION => 1022;
use constant CD_SCAN_CONTENT_FILE_NOT_FOUND => 1023;
use constant CD_SCAN_CONTENT_FILE_NOT_READABLE => 1024;
use constant CD_SCAN_NODE_EXCEPTION_OCCURED => 1025;
use constant INBOUND_CONTAINMENT_FIXUP_FAILED => 1026;
use constant INBOUND_RELATION_FIXUP_FAILED => 1027;
use constant ERROR_APPLYING_CD_DETECTED_ATTRS => 1028;
use constant CANT_ADD_COMPOUND_TO_VIRTUAL_CHILDREN => 1029;
use constant SOURCE_FOLDER_NOT_SPECIFIED => 1030;
use constant COULD_NOT_UNLINK_FROM_SOURCE_FOLDER => 1031;
use constant COULD_NOT_MOVE_OBJECT_ACROSS_DOCBASE => 1032;
use constant NO_PERMISSION_TO_DELETE_OBJECT => 1033;
use constant COULD_NOT_DELETE_CHECKED_OUT_OBJECT => 1034;
use constant OPERATION_ABORTED => 1035;
use constant NO_READ_PERMISSION_ON_SOURCE_OBJECT => 1036;
use constant NO_WRITE_PERMISSION_ON_DESTINATION_FOLDER => 1037;
use constant OBJECT_TYPE_NOT_PRESENT_IN_DEST_FOLDER_DOCBASE => 1038;
use constant SOURCE_FOLDER_TO_BE_COPIED_AND_DEST_FOLDER_COULD_NOT_BE_SAME => 1039;
use constant CANNOT_COPY_NEW_OBJECT_UNTIL_CHECKEDIN => 1040;
use constant COULD_NOT_ATTACH_LIFECYCLE => 1041;

sub getMessage {
	## METHOD: java.lang.String getMessage()
    my $self = shift;
    my $getMessage = JPL::AutoLoader::getmeth('getMessage',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMessage(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getException {
	## METHOD: com.documentum.fc.common.IDfException getException()
    my $self = shift;
    my $getException = JPL::AutoLoader::getmeth('getException',[],['com.documentum.fc.common.IDfException']);
    my $rv = "";
    eval { $rv = $$self->$getException(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfException);
        return \$rv;
    }
}

sub getOperation {
	## METHOD: com.documentum.operations.IDfOperation getOperation()
    my $self = shift;
    my $getOperation = JPL::AutoLoader::getmeth('getOperation',[],['com.documentum.operations.IDfOperation']);
    my $rv = "";
    eval { $rv = $$self->$getOperation(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfOperation);
        return \$rv;
    }
}

sub getErrorCode {
	## METHOD: int getErrorCode()
    my $self = shift;
    my $getErrorCode = JPL::AutoLoader::getmeth('getErrorCode',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getErrorCode(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNode {
	## METHOD: com.documentum.operations.IDfOperationNode getNode()
    my $self = shift;
    my $getNode = JPL::AutoLoader::getmeth('getNode',[],['com.documentum.operations.IDfOperationNode']);
    my $rv = "";
    eval { $rv = $$self->$getNode(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfOperationNode);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
