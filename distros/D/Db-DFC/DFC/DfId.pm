# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfId (com.documentum.fc.common.DfId)
# ------------------------------------------------------------------ #

package DfId;
@ISA = (IDfId);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfId';

use constant DF_NULLID_STR => "0000000000000000";
use constant DF_NULLID => 0000000000000000;


sub new {
    my ($class,$p0) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfId(java.lang.String)

    my $new = JPL::AutoLoader::getmeth('new',['java.lang.String'],[]);

    if ($p0 =~ /\w+/) {
        eval { $rv = com::documentum::fc::common::DfId->$new($p0); };
    } else {
        eval { $rv = com::documentum::fc::common::DfId->$new(DF_NULLID_STR); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfId);
        return \$rv;
    }
}

sub compareTo {
	## METHOD: int compareTo(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $compareTo = JPL::AutoLoader::getmeth('compareTo',['com.documentum.fc.common.IDfId'],['int']);
    my $rv = "";
    eval { $rv = $$self->$compareTo($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

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

sub toString {
	## METHOD: java.lang.String toString()
    my $self = shift;
    my $toString = JPL::AutoLoader::getmeth('toString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$toString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getId {
	## METHOD: java.lang.String getId()
    my $self = shift;
    my $getId = JPL::AutoLoader::getmeth('getId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDocbaseId {
	## METHOD: java.lang.String getDocbaseId()
    my $self = shift;
    my $getDocbaseId = JPL::AutoLoader::getmeth('getDocbaseId',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypePart {
	## METHOD: int getTypePart()
    my $self = shift;
    my $getTypePart = JPL::AutoLoader::getmeth('getTypePart',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTypePart(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isNull {
	## METHOD: boolean isNull()
    my $self = shift;
    my $isNull = JPL::AutoLoader::getmeth('isNull',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNull(); };
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
