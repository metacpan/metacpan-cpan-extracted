# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfAttr (com.documentum.fc.common.IDfAttr)
# ------------------------------------------------------------------ #

package IDfAttr;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfAttr';

use constant DM_BOOLEAN => 0;
use constant DM_INTEGER => 1;
use constant DM_STRING => 2;
use constant DM_ID => 3;
use constant DM_TIME => 4;
use constant DM_DOUBLE => 5;
use constant DM_UNDEFINED => 6;

sub getName {
	## METHOD: java.lang.String getName()
    my $self = shift;
    my $getName = JPL::AutoLoader::getmeth('getName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLength {
	## METHOD: int getLength()
    my $self = shift;
    my $getLength = JPL::AutoLoader::getmeth('getLength',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getLength(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDataType {
	## METHOD: int getDataType()
    my $self = shift;
    my $getDataType = JPL::AutoLoader::getmeth('getDataType',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDataType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRepeating {
	## METHOD: boolean isRepeating()
    my $self = shift;
    my $isRepeating = JPL::AutoLoader::getmeth('isRepeating',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRepeating(); };
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
