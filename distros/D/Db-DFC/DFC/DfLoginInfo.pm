# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfLoginInfo (com.documentum.fc.common.DfLoginInfo)
# ------------------------------------------------------------------ #

package DfLoginInfo;
@ISA = (IDfLoginInfo);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfLoginInfo';



sub new {
    my ($class,$li) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfLoginInfo(com.documentum.fc.common.IDfLoginInfo)
    ## CONSTRUCTOR: com.documentum.fc.common.DfLoginInfo()

    if (ref($li) =~ /IDfLoginInfo/) {
        my $new = JPL::AutoLoader::getmeth('new',['com.documentum.fc.common.IDfLoginInfo'],[]);
        eval { $rv = com::documentum::fc::common::DfLoginInfo->$new($$li); };
    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfLoginInfo->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfLoginInfo);
        return \$rv;
    }
}

sub getDomain {
	## METHOD: java.lang.String getDomain()
    my $self = shift;
    my $getDomain = JPL::AutoLoader::getmeth('getDomain',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDomain(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDomain {
	## METHOD: void setDomain(java.lang.String)
    my ($self,$p0) = @_;
    my $setDomain = JPL::AutoLoader::getmeth('setDomain',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDomain($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPassword {
	## METHOD: java.lang.String getPassword()
    my $self = shift;
    my $getPassword = JPL::AutoLoader::getmeth('getPassword',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPassword(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUser {
	## METHOD: java.lang.String getUser()
    my $self = shift;
    my $getUser = JPL::AutoLoader::getmeth('getUser',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUser(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setUser {
	## METHOD: void setUser(java.lang.String)
    my ($self,$p0) = @_;
    my $setUser = JPL::AutoLoader::getmeth('setUser',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setUser($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPassword {
	## METHOD: void setPassword(java.lang.String)
    my ($self,$p0) = @_;
    my $setPassword = JPL::AutoLoader::getmeth('setPassword',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPassword($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserArg2 {
	## METHOD: java.lang.String getUserArg2()
    my $self = shift;
    my $getUserArg2 = JPL::AutoLoader::getmeth('getUserArg2',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserArg2(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setUserArg2 {
	## METHOD: void setUserArg2(java.lang.String)
    my ($self,$p0) = @_;
    my $setUserArg2 = JPL::AutoLoader::getmeth('setUserArg2',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setUserArg2($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getUserArg1 {
	## METHOD: java.lang.String getUserArg1()
    my $self = shift;
    my $getUserArg1 = JPL::AutoLoader::getmeth('getUserArg1',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getUserArg1(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setUserArg1 {
	## METHOD: void setUserArg1(java.lang.String)
    my ($self,$p0) = @_;
    my $setUserArg1 = JPL::AutoLoader::getmeth('setUserArg1',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setUserArg1($p0); };
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
