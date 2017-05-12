# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfClient (com.documentum.fc.client.IDfClient)
# ------------------------------------------------------------------ #

package IDfClient;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfClient';
use JPL::Class 'com.documentum.fc.client.IDfDocbaseMap';
use JPL::Class 'com.documentum.fc.client.IDfSession';
use JPL::Class 'com.documentum.fc.common.IDfProperties';
use JPL::Class 'com.documentum.fc.client.IDfTypedObject';


sub getContext {
	## METHOD: com.documentum.fc.common.IDfProperties getContext(java.lang.String)
    my ($self,$p0) = @_;
    my $getContext = JPL::AutoLoader::getmeth('getContext',['java.lang.String'],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getContext($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub getClientConfig {
	## METHOD: com.documentum.fc.client.IDfTypedObject getClientConfig()
    my $self = shift;
    my $getClientConfig = JPL::AutoLoader::getmeth('getClientConfig',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getClientConfig(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getServerMap {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerMap(java.lang.String)
    my ($self,$p0) = @_;
    my $getServerMap = JPL::AutoLoader::getmeth('getServerMap',['java.lang.String'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerMap($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getDocbrokerMap {
	## METHOD: com.documentum.fc.client.IDfTypedObject getDocbrokerMap()
    my $self = shift;
    my $getDocbrokerMap = JPL::AutoLoader::getmeth('getDocbrokerMap',[],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getDocbrokerMap(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub getDocbaseNameFromId {
	## METHOD: java.lang.String getDocbaseNameFromId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $getDocbaseNameFromId = JPL::AutoLoader::getmeth('getDocbaseNameFromId',['com.documentum.fc.common.IDfId'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseNameFromId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeContext {
	## METHOD: boolean removeContext(java.lang.String)
    my ($self,$p0) = @_;
    my $removeContext = JPL::AutoLoader::getmeth('removeContext',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$removeContext($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSharedSession {
	## METHOD: com.documentum.fc.client.IDfSession getSharedSession(java.lang.String,com.documentum.fc.common.IDfLoginInfo,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $getSharedSession = JPL::AutoLoader::getmeth('getSharedSession',['java.lang.String','com.documentum.fc.common.IDfLoginInfo','java.lang.String'],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$getSharedSession($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
    }
}

sub getDocbaseMapEx {
	## METHOD: com.documentum.fc.client.IDfDocbaseMap getDocbaseMapEx(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $getDocbaseMapEx = JPL::AutoLoader::getmeth('getDocbaseMapEx',['java.lang.String','java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfDocbaseMap']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseMapEx($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfDocbaseMap);
        return \$rv;
    }
}

sub getServerMapEx {
	## METHOD: com.documentum.fc.client.IDfTypedObject getServerMapEx(java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getServerMapEx = JPL::AutoLoader::getmeth('getServerMapEx',['java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $$self->$getServerMapEx($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTypedObject);
        return \$rv;
    }
}

sub unadoptDMCLSession {
	## METHOD: void unadoptDMCLSession(java.lang.String)
    my ($self,$p0) = @_;
    my $unadoptDMCLSession = JPL::AutoLoader::getmeth('unadoptDMCLSession',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$unadoptDMCLSession($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub findSession {
	## METHOD: com.documentum.fc.client.IDfSession findSession(java.lang.String)
    my ($self,$p0) = @_;
    my $findSession = JPL::AutoLoader::getmeth('findSession',['java.lang.String'],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$findSession($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
    }
}

sub getDocbaseMap {
	## METHOD: com.documentum.fc.client.IDfDocbaseMap getDocbaseMap()
    my $self = shift;
    my $getDocbaseMap = JPL::AutoLoader::getmeth('getDocbaseMap',[],['com.documentum.fc.client.IDfDocbaseMap']);
    my $rv = "";
    eval { $rv = $$self->$getDocbaseMap(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfDocbaseMap);
        return \$rv;
    }
}

sub adoptDMCLSession {
	## METHOD: com.documentum.fc.client.IDfSession adoptDMCLSession(java.lang.String)
    my ($self,$p0) = @_;
    my $adoptDMCLSession = JPL::AutoLoader::getmeth('adoptDMCLSession',['java.lang.String'],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$adoptDMCLSession($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
    }
}

sub enumSharedSessions {
	## METHOD: java.util.Enumeration enumSharedSessions(java.lang.String)
    my ($self,$p0) = @_;
    my $enumSharedSessions = JPL::AutoLoader::getmeth('enumSharedSessions',['java.lang.String'],['java.util.Enumeration']);
    my $rv = "";
    eval { $rv = $$self->$enumSharedSessions($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub newSession {
	## METHOD: com.documentum.fc.client.IDfSession newSession(java.lang.String,com.documentum.fc.common.IDfLoginInfo)
    my ($self,$p0,$p1) = @_;
    my $newSession = JPL::AutoLoader::getmeth('newSession',['java.lang.String','com.documentum.fc.common.IDfLoginInfo'],['com.documentum.fc.client.IDfSession']);
    my $rv = "";
    eval { $rv = $$self->$newSession($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSession);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
