# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVDMPlatformUtils (com.documentum.operations.IDfVDMPlatformUtils)
# ------------------------------------------------------------------ #

package IDfVDMPlatformUtils;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfVDMPlatformUtils';

use constant FILE_ATTRIBUTE_READONLY => 1;
use constant FILE_ATTRIBUTE_HIDDEN => 2;
use constant FILE_ATTRIBUTE_SYSTEM => 4;
use constant FILE_ATTRIBUTE_DIRECTORY => 16;
use constant FILE_ATTRIBUTE_ARCHIVE => 32;
use constant FILE_ATTRIBUTE_NORMAL => 128;
use constant FILE_ATTRIBUTE_TEMPORARY => 256;
use constant FILE_ATTRIBUTE_COMPRESSED => 2048;
use constant FILE_ATTRIBUTE_OFFLINE => 4096;

sub sendEvent {
	## METHOD: boolean sendEvent(int,int,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,[Ljava.lang.String;)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6,$p7) = @_;
    my $sendEvent = JPL::AutoLoader::getmeth('sendEvent',['int','int','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','[Ljava.lang.String;'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$sendEvent($p0,$p1,$p2,$p3,$p4,$p5,$p6,$p7); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFileAttributes {
	## METHOD: int getFileAttributes(java.lang.String)
    my ($self,$p0) = @_;
    my $getFileAttributes = JPL::AutoLoader::getmeth('getFileAttributes',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getFileAttributes($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFileAttributes {
	## METHOD: void setFileAttributes(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $setFileAttributes = JPL::AutoLoader::getmeth('setFileAttributes',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFileAttributes($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAutorecFileTypeCode {
	## METHOD: int getAutorecFileTypeCode(java.lang.String)
    my ($self,$p0) = @_;
    my $getAutorecFileTypeCode = JPL::AutoLoader::getmeth('getAutorecFileTypeCode',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAutorecFileTypeCode($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub fileHasOLELinks {
	## METHOD: boolean fileHasOLELinks(java.lang.String)
    my ($self,$p0) = @_;
    my $fileHasOLELinks = JPL::AutoLoader::getmeth('fileHasOLELinks',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$fileHasOLELinks($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCLSIDForFile {
	## METHOD: java.lang.String getCLSIDForFile(java.lang.String)
    my ($self,$p0) = @_;
    my $getCLSIDForFile = JPL::AutoLoader::getmeth('getCLSIDForFile',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCLSIDForFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub copyFile {
	## METHOD: void copyFile(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $copyFile = JPL::AutoLoader::getmeth('copyFile',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$copyFile($p0,$p1); };
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
