# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfRouter (com.documentum.fc.client.IDfRouter)
# ------------------------------------------------------------------ #

package IDfRouter;
@ISA = (IDfSysObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfRouter';


sub start {
	## METHOD: void start(java.lang.String)
    my ($self,$p0) = @_;
    my $start = JPL::AutoLoader::getmeth('start',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$start($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub halt {
	## METHOD: void halt()
    my $self = shift;
    my $halt = JPL::AutoLoader::getmeth('halt',[],[]);
    my $rv = "";
    eval { $rv = $$self->$halt(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub reverse {
	## METHOD: void reverse(int,com.documentum.fc.common.IDfList,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $reverse = JPL::AutoLoader::getmeth('reverse',['int','com.documentum.fc.common.IDfList','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$reverse($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub end {
	## METHOD: void end()
    my $self = shift;
    my $end = JPL::AutoLoader::getmeth('end',[],[]);
    my $rv = "";
    eval { $rv = $$self->$end(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub force {
	## METHOD: void force(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $force = JPL::AutoLoader::getmeth('force',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$force($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub acquire {
	## METHOD: void acquire(int)
    my ($self,$p0) = @_;
    my $acquire = JPL::AutoLoader::getmeth('acquire',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$acquire($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub pause {
	## METHOD: void pause(int)
    my ($self,$p0) = @_;
    my $pause = JPL::AutoLoader::getmeth('pause',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$pause($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendTask {
	## METHOD: int appendTask()
    my $self = shift;
    my $appendTask = JPL::AutoLoader::getmeth('appendTask',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$appendTask(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeTask {
	## METHOD: void removeTask(int)
    my ($self,$p0) = @_;
    my $removeTask = JPL::AutoLoader::getmeth('removeTask',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeTask($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertTask {
	## METHOD: void insertTask(int)
    my ($self,$p0) = @_;
    my $insertTask = JPL::AutoLoader::getmeth('insertTask',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertTask($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub forward {
	## METHOD: void forward(int,com.documentum.fc.common.IDfList,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $forward = JPL::AutoLoader::getmeth('forward',['int','com.documentum.fc.common.IDfList','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$forward($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub reAssign {
	## METHOD: void reAssign(int,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $reAssign = JPL::AutoLoader::getmeth('reAssign',['int','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$reAssign($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resumeRouter {
	## METHOD: void resumeRouter(int)
    my ($self,$p0) = @_;
    my $resumeRouter = JPL::AutoLoader::getmeth('resumeRouter',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$resumeRouter($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub signOffRouter {
	## METHOD: void signOffRouter(int,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $signOffRouter = JPL::AutoLoader::getmeth('signOffRouter',['int','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$signOffRouter($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub validateRouter {
	## METHOD: void validateRouter(boolean)
    my ($self,$p0) = @_;
    my $validateRouter = JPL::AutoLoader::getmeth('validateRouter',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$validateRouter($p0); };
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
