# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCheckoutNode (com.documentum.operations.IDfCheckoutNode)
# ------------------------------------------------------------------ #

package IDfCheckoutNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCheckoutNode';
use JPL::Class 'com.documentum.fc.client.IDfSysObject';
use JPL::Class 'com.documentum.fc.common.IDfId';


sub getObject {
	## METHOD: com.documentum.fc.client.IDfSysObject getObject()
    my $self = shift;
    my $getObject = JPL::AutoLoader::getmeth('getObject',[],['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $$self->$getObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSysObject);
        return \$rv;
    }
}

sub getFormat {
	## METHOD: java.lang.String getFormat()
    my $self = shift;
    my $getFormat = JPL::AutoLoader::getmeth('getFormat',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFormat(); };
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

sub setFormat {
	## METHOD: void setFormat(java.lang.String)
    my ($self,$p0) = @_;
    my $setFormat = JPL::AutoLoader::getmeth('setFormat',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFormat($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFilePath {
	## METHOD: void setFilePath(java.lang.String)
    my ($self,$p0) = @_;
    my $setFilePath = JPL::AutoLoader::getmeth('setFilePath',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFilePath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFilePath {
	## METHOD: java.lang.String getFilePath()
    my $self = shift;
    my $getFilePath = JPL::AutoLoader::getmeth('getFilePath',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFilePath(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultFormat {
	## METHOD: java.lang.String getDefaultFormat()
    my $self = shift;
    my $getDefaultFormat = JPL::AutoLoader::getmeth('getDefaultFormat',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultFormat(); };
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
