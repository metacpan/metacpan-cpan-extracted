# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCancelCheckoutNode (com.documentum.operations.IDfCancelCheckoutNode)
# ------------------------------------------------------------------ #

package IDfCancelCheckoutNode;
@ISA = (IDfOperationNode);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCancelCheckoutNode';
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

sub getKeepLocalFile {
	## METHOD: boolean getKeepLocalFile()
    my $self = shift;
    my $getKeepLocalFile = JPL::AutoLoader::getmeth('getKeepLocalFile',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getKeepLocalFile(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setKeepLocalFile {
	## METHOD: void setKeepLocalFile(boolean)
    my ($self,$p0) = @_;
    my $setKeepLocalFile = JPL::AutoLoader::getmeth('setKeepLocalFile',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setKeepLocalFile($p0); };
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
