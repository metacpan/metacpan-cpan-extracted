# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfTrace (com.documentum.fc.common.DfTrace)
# ------------------------------------------------------------------ #

package DfTrace;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfTrace';

use constant DO_TRACE => 'true';
use constant EXCEPTION_TRACE => 1;
use constant DFC_API_TRACE => 2;
use constant SERVER_REQ_TRACE => 3;
use constant SERVER_API_TRACE => 4;
use constant OBJ_NEW_TRACE => 7;
use constant OBJ_DEL_TRACE => 8;
use constant DIAG_TRACE => 6;
use constant SYS_MEM_TRACE => 10;
use constant TRACE_LEVEL_MIN => 0;
use constant TRACE_LEVEL_MAX => 10;
use constant TRACE_LEVEL_DEF => 0;
use constant TABS => "																																																																				";
use constant RESET_MSG => "An I/O Exception occurred.  The trace stream was reset to standard out";
use constant EMPTY_MSG => "";
use constant SPACES => "       ";
use constant SPACES2 => "                                                       ";
use constant TABSLENGTH => 68;


sub new {
    ## CONSTRUCTOR: com.documentum.fc.common.DfTrace()
    my $class = shift;
    my $self = com::documentum::fc::common::DfTrace;
    bless(\$self,$class);
    return \$self;
}

sub closeTrace {
	## METHOD: void closeTrace()
    my $self = shift;
    my $closeTrace = JPL::AutoLoader::getmeth('closeTrace',[],[]);
    my $rv = "";
    eval { $rv = $$self->$closeTrace(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTraceTime {
	## METHOD: boolean getTraceTime()
    my $self = shift;
    my $getTraceTime = JPL::AutoLoader::getmeth('getTraceTime',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getTraceTime(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub flushTrace {
	## METHOD: void flushTrace()
    my $self = shift;
    my $flushTrace = JPL::AutoLoader::getmeth('flushTrace',[],[]);
    my $rv = "";
    eval { $rv = $$self->$flushTrace(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTraceFileName {
	## METHOD: java.lang.String getTraceFileName()
    my $self = shift;
    my $getTraceFileName = JPL::AutoLoader::getmeth('getTraceFileName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTraceFileName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTraceFileName {
	## METHOD: void setTraceFileName(java.lang.String)
    my ($self,$p0) = @_;
    my $setTraceFileName = JPL::AutoLoader::getmeth('setTraceFileName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTraceFileName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceMsg {
	## METHOD: void traceMsg(java.lang.String)
    my ($self,$p0) = @_;
    my $traceMsg = JPL::AutoLoader::getmeth('traceMsg',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$traceMsg($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceMsgCond {
	## METHOD: void traceMsgCond(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $traceMsgCond = JPL::AutoLoader::getmeth('traceMsgCond',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$traceMsgCond($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTraceThreads {
	## METHOD: boolean getTraceThreads()
    my $self = shift;
    my $getTraceThreads = JPL::AutoLoader::getmeth('getTraceThreads',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getTraceThreads(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTraceThreads {
	## METHOD: void setTraceThreads(boolean)
    my ($self,$p0) = @_;
    my $setTraceThreads = JPL::AutoLoader::getmeth('setTraceThreads',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTraceThreads($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTraceLevel {
	## METHOD: int getTraceLevel()
    my $self = shift;
    my $getTraceLevel = JPL::AutoLoader::getmeth('getTraceLevel',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTraceLevel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTraceLevel {
	## METHOD: void setTraceLevel(int)
    my ($self,$p0) = @_;
    my $setTraceLevel = JPL::AutoLoader::getmeth('setTraceLevel',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTraceLevel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTraceTime {
	## METHOD: void setTraceTime(boolean)
    my ($self,$p0) = @_;
    my $setTraceTime = JPL::AutoLoader::getmeth('setTraceTime',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTraceTime($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceDFCAPI {
	## METHOD: void traceDFCAPI(java.lang.String,java.lang.String,java.lang.Object,java.lang.String)
	## METHOD: void traceDFCAPI(java.lang.String,java.lang.String)
	## METHOD: void traceDFCAPI(java.lang.String,java.lang.String,int)
	## METHOD: void traceDFCAPI(java.lang.String,java.lang.String,java.lang.Object)
	## METHOD: void traceDFCAPI(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $rv = "";

    if ($p3) {
        my $traceDFCAPI = JPL::AutoLoader::getmeth('traceDFCAPI',['java.lang.String','java.lang.String','java.lang.Object','java.lang.String'],[]);
        eval { $rv = $$self->$traceDFCAPI($p0,$p1,$p2,$p3); };
    } elsif (! $p2) {
        my $traceDFCAPI = JPL::AutoLoader::getmeth('traceDFCAPI',['java.lang.String','java.lang.String'],[]);
        eval { $rv = $$self->$traceDFCAPI($p0,$p1); };
    } elsif (ref($p2) eq 'int') {
        my $traceDFCAPI = JPL::AutoLoader::getmeth('traceDFCAPI',['java.lang.String','java.lang.String','int'],[]);
        eval { $rv = $$self->$traceDFCAPI($p0,$p1,$p2); };
    } elsif (ref($p3) =~ /Object/i) {
        my $traceDFCAPI = JPL::AutoLoader::getmeth('traceDFCAPI',['java.lang.String','java.lang.String','java.lang.Object'],[]);
        eval { $rv = $$self->$traceDFCAPI($p0,$p1,$p2); };
    } else {
        my $traceDFCAPI = JPL::AutoLoader::getmeth('traceDFCAPI',['java.lang.String','java.lang.String','java.lang.Object'],[]);
        eval { $rv = $$self->$traceDFCAPI($p0,$p1,$p2); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceDFCAPIExit {
	## METHOD: void traceDFCAPIExit()
	## METHOD: void traceDFCAPIExit(java.lang.Object)
	## METHOD: void traceDFCAPIExit(int)
    my ($self,$p0) = @_;
    my $rv = "";

    if (ref($p0) =~ /Object/i) {
        my $traceDFCAPIExit = JPL::AutoLoader::getmeth('traceDFCAPIExit',['java.lang.Object'],[]);
        eval { $rv = $$self->$traceDFCAPIExit($p0); };
    } elsif (ref($p0) eq 'int') {
        my $traceDFCAPIExit = JPL::AutoLoader::getmeth('traceDFCAPIExit',['int'],[]);
        eval { $rv = $$self->$traceDFCAPIExit($p0); };
    } elsif (ref($p0) =~ /String/i) {
        my $traceDFCAPIExit = JPL::AutoLoader::getmeth('traceDFCAPIExit',['java.lang.String'],[]);
        eval { $rv = $$self->$traceDFCAPIExit($p0); };
    } else {
        my $traceDFCAPIExit = JPL::AutoLoader::getmeth('traceDFCAPIExit',[],[]);
        eval { $rv = $$self->$traceDFCAPIExit(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub traceException {
	## METHOD: void traceException(java.lang.String,int,java.lang.String,java.lang.String)
	## METHOD: void traceException(java.lang.String,int,java.util.ResourceBundle,java.lang.String)
	## METHOD: void traceException(java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $rv = "";

    if (! $p3) {
        my $traceException = JPL::AutoLoader::getmeth('traceException',['java.lang.String','int','java.lang.String'],[]);
        eval { $rv = $$self->$traceException($p0,$p1,$p2); };
    } elsif (ref($p2) =~ /Resource/i) {
        my $traceException = JPL::AutoLoader::getmeth('traceException',['java.lang.String','int','java.util.ResourceBundle','java.lang.String'],[]);
        eval { $rv = $$self->$traceException($p0,$p1,$p2,$p3); };
    } else {
        my $traceException = JPL::AutoLoader::getmeth('traceException',['java.lang.String','int','java.lang.String','java.lang.String'],[]);
        eval { $rv = $$self->$traceException($p0,$p1,$p2,$p3); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTraceStream {
	## METHOD: void setTraceStream(java.io.OutputStream)
    my ($self,$p0) = @_;
    my $setTraceStream = JPL::AutoLoader::getmeth('setTraceStream',['java.io.OutputStream'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTraceStream($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resetAPIStarted {
	## METHOD: void resetAPIStarted()
    my $self = shift;
    my $resetAPIStarted = JPL::AutoLoader::getmeth('resetAPIStarted',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resetAPIStarted(); };
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
