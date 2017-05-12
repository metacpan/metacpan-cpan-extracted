# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfCheckoutOperation (com.documentum.operations.IDfCheckoutOperation)
# ------------------------------------------------------------------ #

package IDfCheckoutOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfCheckoutOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';


sub getDestinationDirectory {
	## METHOD: java.lang.String getDestinationDirectory()
    my $self = shift;
    my $getDestinationDirectory = JPL::AutoLoader::getmeth('getDestinationDirectory',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDestinationDirectory(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultDestinationDirectory {
	## METHOD: java.lang.String getDefaultDestinationDirectory()
    my $self = shift;
    my $getDefaultDestinationDirectory = JPL::AutoLoader::getmeth('getDefaultDestinationDirectory',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultDestinationDirectory(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDestinationDirectory {
	## METHOD: void setDestinationDirectory(java.lang.String)
    my ($self,$p0) = @_;
    my $setDestinationDirectory = JPL::AutoLoader::getmeth('setDestinationDirectory',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDestinationDirectory($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjects {
	## METHOD: com.documentum.fc.common.IDfList getObjects()
    my $self = shift;
    my $getObjects = JPL::AutoLoader::getmeth('getObjects',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getObjects(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
