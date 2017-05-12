# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfSearchable (com.documentum.fc.common.IDfSearchable)
# ------------------------------------------------------------------ #

package IDfSearchable;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfSearchable';


sub getKeyCount {
	## METHOD: int getKeyCount()
    my $self = shift;
    my $getKeyCount = JPL::AutoLoader::getmeth('getKeyCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getKeyCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getKeyAt {
	## METHOD: double getKeyAt(int)
    my ($self,$p0) = @_;
    my $getKeyAt = JPL::AutoLoader::getmeth('getKeyAt',['int'],['double']);
    my $rv = "";
    eval { $rv = $$self->$getKeyAt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isInSortedOrder {
	## METHOD: boolean isInSortedOrder()
    my $self = shift;
    my $isInSortedOrder = JPL::AutoLoader::getmeth('isInSortedOrder',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isInSortedOrder(); };
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
