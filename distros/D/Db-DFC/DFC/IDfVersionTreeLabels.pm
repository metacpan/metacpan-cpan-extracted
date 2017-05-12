# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVersionTreeLabels (com.documentum.fc.client.IDfVersionTreeLabels)
# ------------------------------------------------------------------ #

package IDfVersionTreeLabels;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVersionTreeLabels';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfVersionLabels';


sub getVersion {
	## METHOD: com.documentum.fc.client.IDfVersionLabels getVersion(int)
    my ($self,$p0) = @_;
    my $getVersion = JPL::AutoLoader::getmeth('getVersion',['int'],['com.documentum.fc.client.IDfVersionLabels']);
    my $rv = "";
    eval { $rv = $$self->$getVersion($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVersionLabels);
        return \$rv;
    }
}

sub getChronicleId {
	## METHOD: com.documentum.fc.common.IDfId getChronicleId()
    my $self = shift;
    my $getChronicleId = JPL::AutoLoader::getmeth('getChronicleId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getChronicleId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getVersionLabelCount {
	## METHOD: int getVersionLabelCount(boolean,boolean)
    my ($self,$p0,$p1) = @_;
    my $getVersionLabelCount = JPL::AutoLoader::getmeth('getVersionLabelCount',['boolean','boolean'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabelCount($p0,$p1); };
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

sub invalidate {
	## METHOD: void invalidate()
    my $self = shift;
    my $invalidate = JPL::AutoLoader::getmeth('invalidate',[],[]);
    my $rv = "";
    eval { $rv = $$self->$invalidate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionCount {
	## METHOD: int getVersionCount()
    my $self = shift;
    my $getVersionCount = JPL::AutoLoader::getmeth('getVersionCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVersionCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getObjectIdFromVersionLabel {
	## METHOD: com.documentum.fc.common.IDfId getObjectIdFromVersionLabel(java.lang.String)
    my ($self,$p0) = @_;
    my $getObjectIdFromVersionLabel = JPL::AutoLoader::getmeth('getObjectIdFromVersionLabel',['java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getObjectIdFromVersionLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
