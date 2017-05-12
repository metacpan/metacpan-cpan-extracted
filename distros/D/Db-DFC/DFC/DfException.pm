# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfException (com.documentum.fc.common.DfException)
# ------------------------------------------------------------------ #

package DfException;
@ISA = (IDfException);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfException';
use JPL::Class 'com.documentum.fc.common.DfException';
use JPL::Class 'com.documentum.fc.common.IDfException';
use JPL::Class 'com.documentum.fc.common.IDfProperties';

use constant DM_API_E_BADID => -65535;
use constant DM_API_E_BADATTRNAME => -65534;
use constant DM_API_E_BADATTRINDX => -65533;
use constant THREAD => ":: THREAD: ";
use constant ERRORCODE => "; ERRORCODE: ";
use constant MSG => "; MSG: ";
use constant NEXT => "; NEXT: ";
use constant DFE_ERROR_CODE => "code";
use constant DFE_THREAD_INFO => "thread";
use constant DFE_NEXT_EXPT => "next";
use constant DFE_TAIL_EXPT => "tail";


sub new {
    my ($class,$p0,$p1,$p2,$p3,$p4) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfException(java.util.ResourceBundle,int,java.lang.String,java.lang.String,java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfException(java.util.ResourceBundle,int)
    ## CONSTRUCTOR: com.documentum.fc.common.DfException(int,java.lang.String,java.lang.String,java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfException(int,java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfException(int)
    ## CONSTRUCTOR: com.documentum.fc.common.DfException()

    if (ref($p0) =~ /ResourceBundle/) {
        if ($p2 =~ /\w+/) {
            my $new = JPL::AutoLoader::getmeth('new',['java.util.ResourceBundle','int','java.lang.String','java.lang.String','java.lang.String'],[]);
            eval { $rv = com::documentum::fc::common::DfException->$new($p0,$p1,$p2,$p3,$p4); };
        } else {
            my $new = JPL::AutoLoader::getmeth('new',['java.util.ResourceBundle','int'],[]);
            eval { $rv = com::documentum::fc::common::DfException->$new($p0,$p1); };
        }

    } elsif ($p0 =~ /\d+/) {
        if ($p2 =~ /\w+/) {
            my $new = JPL::AutoLoader::getmeth('new',['int','java.lang.String','java.lang.String','java.lang.String'],[]);
            eval { $rv = com::documentum::fc::common::DfException->$new($p0,$p1,$p2,$p3); };
        } elsif ($p1 =~ /\w+/) {
            my $new = JPL::AutoLoader::getmeth('new',['int','java.lang.String'],[]);
            eval { $rv = com::documentum::fc::common::DfException->$new($p0,$p1); };
        } else {
            my $new = JPL::AutoLoader::getmeth('new',['int'],[]);
            eval { $rv = com::documentum::fc::common::DfException->$new($p0); };
        }

    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfException->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfException);
        return \$rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString()
    my $self = shift;
    my $toString = JPL::AutoLoader::getmeth('toString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

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

sub parseException {
	## METHOD: com.documentum.fc.common.IDfException parseException(java.lang.String)
    my ($self,$p0) = @_;
    my $parseException = JPL::AutoLoader::getmeth('parseException',['java.lang.String'],['com.documentum.fc.common.IDfException']);
    my $rv = "";
    eval { $rv = $$self->$parseException($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfException);
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

sub appendException {
	## METHOD: com.documentum.fc.common.DfException appendException(com.documentum.fc.common.DfException,com.documentum.fc.common.DfException,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $appendException = JPL::AutoLoader::getmeth('appendException',['com.documentum.fc.common.DfException','com.documentum.fc.common.DfException','int'],['com.documentum.fc.common.DfException']);
    my $rv = "";
    eval { $rv = $$self->$appendException($$p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,DfException);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
