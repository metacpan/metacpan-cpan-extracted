# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfUtil (com.documentum.fc.common.DfUtil)
# ------------------------------------------------------------------ #

package DfUtil;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfUtil';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.common.IDfId';

use constant TRUE => "T";
use constant FALSE => "F";


sub new {
    ## CONSTRUCTOR: com.documentum.fc.common.DfUtil()

    my $class = shift;
    my $self = com::documentum::fc::common::DfUtil;
    bless(\$self,$class);
    return \$self;
}

sub toString {
	## METHOD: java.lang.String toString(boolean)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['boolean'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(com.documentum.fc.common.IDfList)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['com.documentum.fc.common.IDfList'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(com.documentum.fc.common.DfObject)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['com.documentum.fc.common.DfObject'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['com.documentum.fc.common.IDfTime'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['com.documentum.fc.common.IDfId'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(double)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['double'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(java.lang.String)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toString {
	## METHOD: java.lang.String toString(int)
    my ($self,$p0) = @_;
    my $toString = JPL::AutoLoader::getmeth('toString',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toBoolean {
	## METHOD: boolean toBoolean(char)
    my ($self,$p0) = @_;
    my $toBoolean = JPL::AutoLoader::getmeth('toBoolean',['char'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$toBoolean($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toBoolean {
	## METHOD: boolean toBoolean(java.lang.String)
    my ($self,$p0) = @_;
    my $toBoolean = JPL::AutoLoader::getmeth('toBoolean',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$toBoolean($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeString {
	## METHOD: java.lang.String getTypeString(int)
    my ($self,$p0) = @_;
    my $getTypeString = JPL::AutoLoader::getmeth('getTypeString',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDFCBundleString {
	## METHOD: java.lang.String getDFCBundleString(int)
    my ($self,$p0) = @_;
    my $getDFCBundleString = JPL::AutoLoader::getmeth('getDFCBundleString',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDFCBundleString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDFCBundleString {
	## METHOD: java.lang.String getDFCBundleString(int,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getDFCBundleString = JPL::AutoLoader::getmeth('getDFCBundleString',['int','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDFCBundleString($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDFCBundleString {
	## METHOD: java.lang.String getDFCBundleString(java.lang.String)
    my ($self,$p0) = @_;
    my $getDFCBundleString = JPL::AutoLoader::getmeth('getDFCBundleString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDFCBundleString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBundleString {
	## METHOD: java.lang.String getBundleString(java.util.ResourceBundle,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getBundleString = JPL::AutoLoader::getmeth('getBundleString',['java.util.ResourceBundle','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getBundleString($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBundleString {
	## METHOD: java.lang.String getBundleString(java.util.ResourceBundle,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $getBundleString = JPL::AutoLoader::getmeth('getBundleString',['java.util.ResourceBundle','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getBundleString($p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toPseudoPtr {
	## METHOD: java.lang.String toPseudoPtr(java.lang.Object)
    my ($self,$p0) = @_;
    my $toPseudoPtr = JPL::AutoLoader::getmeth('toPseudoPtr',['java.lang.Object'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toPseudoPtr($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toPseudoPtr {
	## METHOD: java.lang.String toPseudoPtr(com.documentum.fc.common.DfObject)
    my ($self,$p0) = @_;
    my $toPseudoPtr = JPL::AutoLoader::getmeth('toPseudoPtr',['com.documentum.fc.common.DfObject'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toPseudoPtr($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1,$p2,$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1,$p2,$p3,$p4,$p5,$p6); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub buildArgs {
	## METHOD: java.lang.String buildArgs(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $buildArgs = JPL::AutoLoader::getmeth('buildArgs',['java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$buildArgs($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toQuotedString {
	## METHOD: java.lang.String toQuotedString(java.lang.String)
    my ($self,$p0) = @_;
    my $toQuotedString = JPL::AutoLoader::getmeth('toQuotedString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toQuotedString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toInt {
	## METHOD: int toInt(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $toInt = JPL::AutoLoader::getmeth('toInt',['java.lang.String','int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$toInt($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toInt {
	## METHOD: int toInt(java.lang.String)
    my ($self,$p0) = @_;
    my $toInt = JPL::AutoLoader::getmeth('toInt',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$toInt($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toId {
	## METHOD: com.documentum.fc.common.IDfId toId(java.lang.String)
    my ($self,$p0) = @_;
    my $toId = JPL::AutoLoader::getmeth('toId',['java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$toId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub toDouble {
	## METHOD: double toDouble(java.lang.String)
    my ($self,$p0) = @_;
    my $toDouble = JPL::AutoLoader::getmeth('toDouble',['java.lang.String'],['double']);
    my $rv = "";
    eval { $rv = $$self->$toDouble($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getEolString {
	## METHOD: java.lang.String getEolString()
    my $self = shift;
    my $getEolString = JPL::AutoLoader::getmeth('getEolString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getEolString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub escapeQuotedString {
	## METHOD: java.lang.String escapeQuotedString(java.lang.String)
    my ($self,$p0) = @_;
    my $escapeQuotedString = JPL::AutoLoader::getmeth('escapeQuotedString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$escapeQuotedString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDFCBundle {
	## METHOD: java.util.ResourceBundle getDFCBundle()
    my $self = shift;
    my $getDFCBundle = JPL::AutoLoader::getmeth('getDFCBundle',[],['java.util.ResourceBundle']);
    my $rv = "";
    eval { $rv = $$self->$getDFCBundle(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub substStringParams {
	## METHOD: java.lang.String substStringParams(java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $substStringParams = JPL::AutoLoader::getmeth('substStringParams',['java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$substStringParams($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub toTime {
	## METHOD: com.documentum.fc.common.IDfTime toTime(java.lang.String)
    my ($self,$p0) = @_;
    my $toTime = JPL::AutoLoader::getmeth('toTime',['java.lang.String'],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$toTime($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub sessionFormatToJavaFormat {
	## METHOD: java.lang.String sessionFormatToJavaFormat(java.lang.String)
    my ($self,$p0) = @_;
    my $sessionFormatToJavaFormat = JPL::AutoLoader::getmeth('sessionFormatToJavaFormat',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$sessionFormatToJavaFormat($p0); };
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
