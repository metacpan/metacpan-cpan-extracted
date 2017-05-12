# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVersionPolicy (com.documentum.fc.client.IDfVersionPolicy)
# ------------------------------------------------------------------ #

package IDfVersionPolicy;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVersionPolicy';

use constant DF_NEXT_MAJOR => 0;
use constant DF_NEXT_MINOR => 1;
use constant DF_SAME_VERSION => 2;
use constant DF_BRANCH_VERSION => 3;
use constant DF_CANNOT_VERSION => 4;

sub canCheckinFromFile {
	## METHOD: boolean canCheckinFromFile()
    my $self = shift;
    my $canCheckinFromFile = JPL::AutoLoader::getmeth('canCheckinFromFile',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canCheckinFromFile(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNextMinorLabel {
	## METHOD: java.lang.String getNextMinorLabel()
    my $self = shift;
    my $getNextMinorLabel = JPL::AutoLoader::getmeth('getNextMinorLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNextMinorLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLogComment {
	## METHOD: java.lang.String getLogComment()
    my $self = shift;
    my $getLogComment = JPL::AutoLoader::getmeth('getLogComment',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLogComment(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isDefaultRetainLockOnCheckin {
	## METHOD: boolean isDefaultRetainLockOnCheckin()
    my $self = shift;
    my $isDefaultRetainLockOnCheckin = JPL::AutoLoader::getmeth('isDefaultRetainLockOnCheckin',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isDefaultRetainLockOnCheckin(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDefaultCheckinVersion {
	## METHOD: int getDefaultCheckinVersion()
    my $self = shift;
    my $getDefaultCheckinVersion = JPL::AutoLoader::getmeth('getDefaultCheckinVersion',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultCheckinVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBranchLabel {
	## METHOD: java.lang.String getBranchLabel()
    my $self = shift;
    my $getBranchLabel = JPL::AutoLoader::getmeth('getBranchLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getBranchLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionSummary {
	## METHOD: java.lang.String getVersionSummary(java.lang.String)
    my ($self,$p0) = @_;
    my $getVersionSummary = JPL::AutoLoader::getmeth('getVersionSummary',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVersionSummary($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNextMajorLabel {
	## METHOD: java.lang.String getNextMajorLabel()
    my $self = shift;
    my $getNextMajorLabel = JPL::AutoLoader::getmeth('getNextMajorLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNextMajorLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSameLabel {
	## METHOD: java.lang.String getSameLabel()
    my $self = shift;
    my $getSameLabel = JPL::AutoLoader::getmeth('getSameLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSameLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canVersion {
	## METHOD: boolean canVersion(int)
    my ($self,$p0) = @_;
    my $canVersion = JPL::AutoLoader::getmeth('canVersion',['int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canVersion($p0); };
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
