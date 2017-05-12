# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVersionLabels (com.documentum.fc.client.IDfVersionLabels)
# ------------------------------------------------------------------ #

package IDfVersionLabels;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVersionLabels';
use JPL::Class 'com.documentum.fc.common.IDfId';


sub getImplicitVersionLabel {
	## METHOD: java.lang.String getImplicitVersionLabel()
    my $self = shift;
    my $getImplicitVersionLabel = JPL::AutoLoader::getmeth('getImplicitVersionLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getImplicitVersionLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabelCount {
	## METHOD: int getVersionLabelCount()
    my $self = shift;
    my $getVersionLabelCount = JPL::AutoLoader::getmeth('getVersionLabelCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabelCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabel {
	## METHOD: java.lang.String getVersionLabel(int)
    my ($self,$p0) = @_;
    my $getVersionLabel = JPL::AutoLoader::getmeth('getVersionLabel',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabel($p0); };
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

sub hasSymbolicVersionLabel {
	## METHOD: boolean hasSymbolicVersionLabel()
    my $self = shift;
    my $hasSymbolicVersionLabel = JPL::AutoLoader::getmeth('hasSymbolicVersionLabel',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasSymbolicVersionLabel(); };
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
