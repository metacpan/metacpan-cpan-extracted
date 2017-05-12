# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfException (com.documentum.fc.common.IDfException)
# ------------------------------------------------------------------ #

package IDfException;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfException';
use JPL::Class 'com.documentum.fc.common.IDfException';
use JPL::Class 'com.documentum.fc.common.IDfProperties';

use constant DM_NOTDFC_E_EXTERNAL => 0;
use constant DM_NOTDFC_E_JAVA => 1;
use constant DM_DFC_E_UNDEFINED => 255;
use constant DM_DFC_E_SERVER => 256;
use constant DM_DFC_E_NOT_SUPPORTED => 512;
use constant DM_DFC_E_BAD_VALUE => 513;
use constant DM_DFC_E_CLASS_NOT_FOUND => 514;
use constant DM_DFC_E_BAD_CLASS => 515;
use constant DM_DFC_E_INIT_ERROR => 516;
use constant DM_DFC_E_INIT_DMCL => 517;
use constant DM_DFC_E_BAD_INDEX => 518;
use constant DM_DFC_E_TYPE_MISMATCH => 544;
use constant DM_DFC_E_TYPE_MISMATCH_ADD => 545;
use constant DM_DFC_E_TYPE_MISMATCH_GET => 546;
use constant DM_DFC_E_TYPE_MISMATCH_COMP => 547;
use constant DM_DFCRM_E_OBJCARR_ERROR => 768;
use constant DM_DFCSESS_E_DISCONNECTED => 1024;
use constant DM_DFCSESS_E_ILLEGAL_OP => 1025;
use constant DM_DFCSESS_E_FAILED => 1026;
use constant DM_DFCSESS_E_FAILED_EX => 1027;
use constant DM_DFCSESS_E_BAD_ADOPT_SESSID => 1029;
use constant DM_DFCCOLL_E_BAD_STATE => 1280;
use constant DM_DFCCOLL_E_BAD_QUERY_TYPE => 1281;
use constant DM_DFCWF_E_APPEND_NOTE => 1312;
use constant DM_DFCWF_E_USER_LIMIT => 1314;
use constant DM_DFCWF_E_NO_USER => 1315;
use constant DM_DFCWF_E_NO_OBJECT => 1316;
use constant DM_DFCWF_E_START_FAILED => 1317;
use constant DM_DFCWF_E_INVALID_GROUP => 1318;
use constant DM_DFCWF_E_MISSING_TEMPLATE => 1319;
use constant DM_DFCWF_E_BAD_OBJECT => 1320;
use constant DM_DFCWF_E_BAD_TEMPLATE => 1321;
use constant DM_DFCBP_E_ALIAS_ALREADY_EXISTS => 1344;
use constant DM_DFCBP_E_ALIAS_NOT_EXIST => 1345;
use constant DM_DFCCTXTMGR_E_GETCONTEXT => 1408;
use constant DM_VALIDATION_E_ERROR => 1536;
use constant DM_VALIDATION_E_ATTR_RULES => 1552;
use constant DM_VALIDATION_E_USE_VALUE_ASST => 1553;
use constant DM_VALIDATION_E_EXCESS_LEN => 1554;
use constant DM_VALIDATION_E_DATATYPE => 1555;
use constant DM_VALIDATION_E_FORMAT => 1556;
use constant DM_VALIDATION_E_EXPR => 1557;
use constant DM_VALIDATION_E_ATTR_RULES_NO_VAL => 1558;
use constant DM_VALIDATION_E_OBJ_RULES => 1584;
use constant DM_VALIDATION_E_OBJ_NULL_DATA => 1585;
use constant DM_VALIDATION_E_OBJ_EXPR => 1586;
use constant DM_DFCQB_FILE_ERROR => 1792;
use constant DM_DFCQB_NO_PATH_SPECIFIED => 1793;
use constant DM_TEMPVDM_E_ERROR => 2304;
use constant errorNoPermissionToDetectExistanceOfFile => 2816;
use constant errorFileDoesNotExist => 2817;
use constant errorFileIsActuallyADirectory => 2818;
use constant errorNoPermissionToOpenFileWithReadAccess => 2819;
use constant errorReadingFile => 2820;
use constant errorCorruptedFile => 2821;
use constant errorNoPermissionToOpenExistingFileWithWriteAccess => 2822;
use constant errorWritingToExistingFile => 2823;
use constant errorNoPermissionToCreateFile => 2824;
use constant errorWritingToNewFile => 2825;
use constant errorNoPermissionToDetectExistanceOfDirectory => 2826;
use constant errorDirectoryDoesNotExist => 2827;
use constant errorDirectoryIsActuallyAFile => 2828;
use constant errorNoPermissionToCreateDirectory => 2829;
use constant DM_EXPR_E_PARSE => 3584;
use constant DM_EXPR_E_PARSE_LOAD_FAIL => 3585;
use constant DM_EXPR_E_EVALUATE => 3600;
use constant DM_EXPR_E_EVALUATOR_LOAD_FAIL => 3601;

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

sub getProperties {
	## METHOD: com.documentum.fc.common.IDfProperties getProperties()
    my $self = shift;
    my $getProperties = JPL::AutoLoader::getmeth('getProperties',[],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getProperties(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub getTailException {
	## METHOD: com.documentum.fc.common.IDfException getTailException()
    my $self = shift;
    my $getTailException = JPL::AutoLoader::getmeth('getTailException',[],['com.documentum.fc.common.IDfException']);
    my $rv = "";
    eval { $rv = $$self->$getTailException(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfException);
        return \$rv;
    }
}

sub getThreadInfo {
	## METHOD: java.lang.String getThreadInfo()
    my $self = shift;
    my $getThreadInfo = JPL::AutoLoader::getmeth('getThreadInfo',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getThreadInfo(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub getNextException {
	## METHOD: com.documentum.fc.common.IDfException getNextException()
    my $self = shift;
    my $getNextException = JPL::AutoLoader::getmeth('getNextException',[],['com.documentum.fc.common.IDfException']);
    my $rv = "";
    eval { $rv = $$self->$getNextException(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfException);
        return \$rv;
    }
}

sub setErrorCode {
	## METHOD: void setErrorCode(int)
    my ($self,$p0) = @_;
    my $setErrorCode = JPL::AutoLoader::getmeth('setErrorCode',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setErrorCode($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStackTrace {
	## METHOD: java.lang.String getStackTrace()
    my $self = shift;
    my $getStackTrace = JPL::AutoLoader::getmeth('getStackTrace',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getStackTrace(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setMessage {
	## METHOD: void setMessage(java.lang.String)
    my ($self,$p0) = @_;
    my $setMessage = JPL::AutoLoader::getmeth('setMessage',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setMessage($p0); };
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


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
