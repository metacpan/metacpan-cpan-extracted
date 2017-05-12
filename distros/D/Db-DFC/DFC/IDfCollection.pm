# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCollection (com.documentum.fc.client.IDfCollection)
# ------------------------------------------------------------------ #

package IDfCollection;
@ISA = (IDfTypedObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfCollection';
use JPL::Class 'com.documentum.fc.client.IDfTypedObject';

use constant DF_WAITING_STATE => 0;
use constant DF_READY_STATE => 1;
use constant DF_CLOSED_STATE => 2;

sub next {
	## METHOD: boolean next()
    my $self = shift;
    my $next = JPL::AutoLoader::getmeth('next',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$next(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub close {
	## METHOD: void close()
    my $self = shift;
    my $close = JPL::AutoLoader::getmeth('close',[],[]);
    my $rv = "";
    eval { $rv = $$self->$close(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBytesBuffer {
	## METHOD: java.io.ByteArrayInputStream getBytesBuffer(java.lang.String,java.lang.String,java.lang.String,int)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getBytesBuffer = JPL::AutoLoader::getmeth('getBytesBuffer',['java.lang.String','java.lang.String','java.lang.String','int'],['java.io.ByteArrayInputStream']);
    my $rv = "";
    eval { $rv = $$self->$getBytesBuffer($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypedObject {
	## METHOD: com.documentum.fc.client.IDfTypedObject getTypedObject()
    my $self = shift;
    my $getTypedObject = JPL::AutoLoader::getmeth('getTypedObject',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getTypedObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getState {
	## METHOD: int getState()
    my $self = shift;
    my $getState = JPL::AutoLoader::getmeth('getState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getState(); };
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
