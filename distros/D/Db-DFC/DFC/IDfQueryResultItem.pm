# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryResultItem (com.documentum.fc.client.qb.IDfQueryResultItem)
# ------------------------------------------------------------------ #

package IDfQueryResultItem;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryResultItem';
use JPL::Class 'com.documentum.fc.client.IDfTypedObject';


sub getValue {
	## METHOD: java.lang.String getValue(int)
    my ($self,$p0) = @_;
    my $getValue = JPL::AutoLoader::getmeth('getValue',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setValue {
	## METHOD: void setValue(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setValue = JPL::AutoLoader::getmeth('setValue',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setValue($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseName {
	## METHOD: java.lang.String getDocbaseName()
    my $self = shift;
    my $getDocbaseName = JPL::AutoLoader::getmeth('getDocbaseName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDQL {
	## METHOD: java.lang.String getDQL()
    my $self = shift;
    my $getDQL = JPL::AutoLoader::getmeth('getDQL',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDQL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypedObject {
	## METHOD: com.documentum.fc.client.IDfTypedObject getTypedObject()
    my $self = shift;
    my $getTypedObject = JPL::AutoLoader::getmeth('getTypedObject',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getTypedObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getObjectID {
	## METHOD: java.lang.String getObjectID()
    my $self = shift;
    my $getObjectID = JPL::AutoLoader::getmeth('getObjectID',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectID(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub makeTermHitFile {
	## METHOD: boolean makeTermHitFile(java.lang.String)
    my ($self,$p0) = @_;
    my $makeTermHitFile = JPL::AutoLoader::getmeth('makeTermHitFile',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$makeTermHitFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSummary {
	## METHOD: java.lang.String getSummary()
    my $self = shift;
    my $getSummary = JPL::AutoLoader::getmeth('getSummary',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSummary(); };
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
