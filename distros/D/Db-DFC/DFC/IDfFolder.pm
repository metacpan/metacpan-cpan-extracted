# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfFolder (com.documentum.fc.client.IDfFolder)
# ------------------------------------------------------------------ #

package IDfFolder;
@ISA = (IDfSysObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfFolder';
use JPL::Class 'com.documentum.fc.client.IDfCollection';


sub getContents {
	## METHOD: com.documentum.fc.client.IDfCollection getContents(java.lang.String)
    my ($self,$p0) = @_;
    my $getContents = JPL::AutoLoader::getmeth('getContents',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getContents($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getAncestorIdCount {
	## METHOD: int getAncestorIdCount()
    my $self = shift;
    my $getAncestorIdCount = JPL::AutoLoader::getmeth('getAncestorIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAncestorIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFolderPathCount {
	## METHOD: int getFolderPathCount()
    my $self = shift;
    my $getFolderPathCount = JPL::AutoLoader::getmeth('getFolderPathCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getFolderPathCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFolderPath {
	## METHOD: java.lang.String getFolderPath(int)
    my ($self,$p0) = @_;
    my $getFolderPath = JPL::AutoLoader::getmeth('getFolderPath',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFolderPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAncestorId {
	## METHOD: java.lang.String getAncestorId(int)
    my ($self,$p0) = @_;
    my $getAncestorId = JPL::AutoLoader::getmeth('getAncestorId',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAncestorId($p0); };
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
