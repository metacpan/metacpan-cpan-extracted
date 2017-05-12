# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfValueAssistance (com.documentum.fc.client.IDfValueAssistance)
# ------------------------------------------------------------------ #

package IDfValueAssistance;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfValueAssistance';
use JPL::Class 'com.documentum.fc.common.IDfList';


sub getDisplayValue {
	## METHOD: java.lang.String getDisplayValue(java.lang.String)
    my ($self,$p0) = @_;
    my $getDisplayValue = JPL::AutoLoader::getmeth('getDisplayValue',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDisplayValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDisplayValues {
	## METHOD: com.documentum.fc.common.IDfList getDisplayValues()
    my $self = shift;
    my $getDisplayValues = JPL::AutoLoader::getmeth('getDisplayValues',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getDisplayValues(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub isValidForObject {
	## METHOD: boolean isValidForObject(com.documentum.fc.client.IDfPersistentObject)
    my ($self,$p0) = @_;
    my $isValidForObject = JPL::AutoLoader::getmeth('isValidForObject',['com.documentum.fc.client.IDfPersistentObject'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isValidForObject($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActualValue {
	## METHOD: java.lang.String getActualValue(java.lang.String)
    my ($self,$p0) = @_;
    my $getActualValue = JPL::AutoLoader::getmeth('getActualValue',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getActualValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getActualValues {
	## METHOD: com.documentum.fc.common.IDfList getActualValues()
    my $self = shift;
    my $getActualValues = JPL::AutoLoader::getmeth('getActualValues',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getActualValues(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}

sub isValidForDependentValues {
	## METHOD: boolean isValidForDependentValues(com.documentum.fc.common.IDfProperties)
    my ($self,$p0) = @_;
    my $isValidForDependentValues = JPL::AutoLoader::getmeth('isValidForDependentValues',['com.documentum.fc.common.IDfProperties'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isValidForDependentValues($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isListComplete {
	## METHOD: boolean isListComplete()
    my $self = shift;
    my $isListComplete = JPL::AutoLoader::getmeth('isListComplete',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isListComplete(); };
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
