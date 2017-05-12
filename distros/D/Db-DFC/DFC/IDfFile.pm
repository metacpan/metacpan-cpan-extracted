# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfFile (com.documentum.operations.IDfFile)
# ------------------------------------------------------------------ #

package IDfFile;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfFile';


sub equals {
	## METHOD: boolean equals(java.lang.Object)
    my ($self,$p0) = @_;
    my $equals = JPL::AutoLoader::getmeth('equals',['java.lang.Object'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$equals($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

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

sub setName {
	## METHOD: void setName(java.lang.String)
    my ($self,$p0) = @_;
    my $setName = JPL::AutoLoader::getmeth('setName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub exists {
	## METHOD: boolean exists()
    my $self = shift;
    my $exists = JPL::AutoLoader::getmeth('exists',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$exists(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canRead {
	## METHOD: boolean canRead()
    my $self = shift;
    my $canRead = JPL::AutoLoader::getmeth('canRead',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canRead(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canWrite {
	## METHOD: boolean canWrite()
    my $self = shift;
    my $canWrite = JPL::AutoLoader::getmeth('canWrite',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canWrite(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub renameTo {
	## METHOD: void renameTo(java.lang.String)
    my ($self,$p0) = @_;
    my $renameTo = JPL::AutoLoader::getmeth('renameTo',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$renameTo($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSeparator {
	## METHOD: java.lang.String getSeparator()
    my $self = shift;
    my $getSeparator = JPL::AutoLoader::getmeth('getSeparator',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSeparator(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDirectory {
	## METHOD: java.lang.String getDirectory()
    my $self = shift;
    my $getDirectory = JPL::AutoLoader::getmeth('getDirectory',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDirectory(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDirectory {
	## METHOD: void setDirectory(java.lang.String)
    my ($self,$p0) = @_;
    my $setDirectory = JPL::AutoLoader::getmeth('setDirectory',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDirectory($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFullPath {
	## METHOD: java.lang.String getFullPath()
    my $self = shift;
    my $getFullPath = JPL::AutoLoader::getmeth('getFullPath',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFullPath(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFullPath {
	## METHOD: void setFullPath(java.lang.String)
    my ($self,$p0) = @_;
    my $setFullPath = JPL::AutoLoader::getmeth('setFullPath',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFullPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExtension {
	## METHOD: java.lang.String getExtension()
    my $self = shift;
    my $getExtension = JPL::AutoLoader::getmeth('getExtension',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getExtension(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setExtension {
	## METHOD: void setExtension(java.lang.String)
    my ($self,$p0) = @_;
    my $setExtension = JPL::AutoLoader::getmeth('setExtension',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setExtension($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub deleteFile {
	## METHOD: void deleteFile()
    my $self = shift;
    my $deleteFile = JPL::AutoLoader::getmeth('deleteFile',[],[]);
    my $rv = "";
    eval { $rv = $$self->$deleteFile(); };
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
