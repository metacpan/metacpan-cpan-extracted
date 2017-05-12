# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfDeleteOperation (com.documentum.operations.IDfDeleteOperation)
# ------------------------------------------------------------------ #

package IDfDeleteOperation;
@ISA = (IDfOperation);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfDeleteOperation';
use JPL::Class 'com.documentum.fc.common.IDfList';

use constant SELECTED_VERSIONS => 0;
use constant UNUSED_VERSIONS => 1;
use constant ALL_VERSIONS => 2;

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

sub setVersionDeletionPolicy {
	## METHOD: void setVersionDeletionPolicy(int)
    my ($self,$p0) = @_;
    my $setVersionDeletionPolicy = JPL::AutoLoader::getmeth('setVersionDeletionPolicy',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVersionDeletionPolicy($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionDeletionPolicy {
	## METHOD: int getVersionDeletionPolicy()
    my $self = shift;
    my $getVersionDeletionPolicy = JPL::AutoLoader::getmeth('getVersionDeletionPolicy',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVersionDeletionPolicy(); };
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
