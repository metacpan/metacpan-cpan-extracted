# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfFormat (com.documentum.fc.client.IDfFormat)
# ------------------------------------------------------------------ #

package IDfFormat;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfFormat';
use JPL::Class 'com.documentum.fc.common.IDfId';


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

sub isHidden {
	## METHOD: boolean isHidden()
    my $self = shift;
    my $isHidden = JPL::AutoLoader::getmeth('isHidden',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isHidden(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
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

sub getWin31App {
	## METHOD: java.lang.String getWin31App()
    my $self = shift;
    my $getWin31App = JPL::AutoLoader::getmeth('getWin31App',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getWin31App(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMacType {
	## METHOD: java.lang.String getMacType()
    my $self = shift;
    my $getMacType = JPL::AutoLoader::getmeth('getMacType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMacType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTopicTransform {
	## METHOD: boolean getTopicTransform()
    my $self = shift;
    my $getTopicTransform = JPL::AutoLoader::getmeth('getTopicTransform',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getTopicTransform(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTopicFormatName {
	## METHOD: java.lang.String getTopicFormatName()
    my $self = shift;
    my $getTopicFormatName = JPL::AutoLoader::getmeth('getTopicFormatName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTopicFormatName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDOSExtension {
	## METHOD: java.lang.String getDOSExtension()
    my $self = shift;
    my $getDOSExtension = JPL::AutoLoader::getmeth('getDOSExtension',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDOSExtension(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTopicFilter {
	## METHOD: java.lang.String getTopicFilter()
    my $self = shift;
    my $getTopicFilter = JPL::AutoLoader::getmeth('getTopicFilter',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTopicFilter(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCOMClassId {
	## METHOD: java.lang.String getCOMClassId()
    my $self = shift;
    my $getCOMClassId = JPL::AutoLoader::getmeth('getCOMClassId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCOMClassId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTopicFormat {
	## METHOD: com.documentum.fc.common.IDfId getTopicFormat()
    my $self = shift;
    my $getTopicFormat = JPL::AutoLoader::getmeth('getTopicFormat',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getTopicFormat(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getMacCreator {
	## METHOD: java.lang.String getMacCreator()
    my $self = shift;
    my $getMacCreator = JPL::AutoLoader::getmeth('getMacCreator',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMacCreator(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canIndex {
	## METHOD: boolean canIndex()
    my $self = shift;
    my $canIndex = JPL::AutoLoader::getmeth('canIndex',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canIndex(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMIMEType {
	## METHOD: java.lang.String getMIMEType()
    my $self = shift;
    my $getMIMEType = JPL::AutoLoader::getmeth('getMIMEType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMIMEType(); };
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
