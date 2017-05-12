# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfChangeDescription (com.documentum.fc.common.IDfChangeDescription)
# ------------------------------------------------------------------ #

package IDfChangeDescription;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfChangeDescription';
use JPL::Class 'com.documentum.fc.common.IDfId';


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

sub getDescription {
	## METHOD: java.lang.String getDescription()
    my $self = shift;
    my $getDescription = JPL::AutoLoader::getmeth('getDescription',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDescription(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContextTag {
	## METHOD: java.lang.String getContextTag()
    my $self = shift;
    my $getContextTag = JPL::AutoLoader::getmeth('getContextTag',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getContextTag(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChangeSequenceNumber {
	## METHOD: int getChangeSequenceNumber()
    my $self = shift;
    my $getChangeSequenceNumber = JPL::AutoLoader::getmeth('getChangeSequenceNumber',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getChangeSequenceNumber(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCode {
	## METHOD: int getCode()
    my $self = shift;
    my $getCode = JPL::AutoLoader::getmeth('getCode',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCode(); };
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
