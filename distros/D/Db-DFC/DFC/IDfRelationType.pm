# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfRelationType (com.documentum.fc.client.IDfRelationType)
# ------------------------------------------------------------------ #

package IDfRelationType;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfRelationType';

use constant SYSTEM => "SYSTEM";
use constant PARENT => "PARENT";
use constant CHILD => "CHILD";
use constant NONE => "NONE";

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

sub setDescription {
	## METHOD: void setDescription(java.lang.String)
    my ($self,$p0) = @_;
    my $setDescription = JPL::AutoLoader::getmeth('setDescription',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRelationName {
	## METHOD: java.lang.String getRelationName()
    my $self = shift;
    my $getRelationName = JPL::AutoLoader::getmeth('getRelationName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getRelationName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setRelationName {
	## METHOD: void setRelationName(java.lang.String)
    my ($self,$p0) = @_;
    my $setRelationName = JPL::AutoLoader::getmeth('setRelationName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setRelationName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setParentType {
	## METHOD: void setParentType(java.lang.String)
    my ($self,$p0) = @_;
    my $setParentType = JPL::AutoLoader::getmeth('setParentType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setParentType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChildType {
	## METHOD: java.lang.String getChildType()
    my $self = shift;
    my $getChildType = JPL::AutoLoader::getmeth('getChildType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getChildType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setChildType {
	## METHOD: void setChildType(java.lang.String)
    my ($self,$p0) = @_;
    my $setChildType = JPL::AutoLoader::getmeth('setChildType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setChildType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSecurityType {
	## METHOD: java.lang.String getSecurityType()
    my $self = shift;
    my $getSecurityType = JPL::AutoLoader::getmeth('getSecurityType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSecurityType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSecurityType {
	## METHOD: void setSecurityType(java.lang.String)
    my ($self,$p0) = @_;
    my $setSecurityType = JPL::AutoLoader::getmeth('setSecurityType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSecurityType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getParentType {
	## METHOD: java.lang.String getParentType()
    my $self = shift;
    my $getParentType = JPL::AutoLoader::getmeth('getParentType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getParentType(); };
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
