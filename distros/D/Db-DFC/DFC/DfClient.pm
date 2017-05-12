# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfClient (com.documentum.fc.client.DfClient)
# ------------------------------------------------------------------ #

package DfClient;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::DfClient';
use JPL::Class 'com.documentum.fc.client.IDfClient';



sub new {
    ## CONSTRUCTOR: com.documentum.fc.client.DfClient()

    my $class = shift;
    my $self = com::documentum::fc::client::DfClient;
    bless(\$self,$class);
    return \$self;
}

sub getLocalClient {
	## METHOD: com.documentum.fc.client.IDfClient getLocalClient()
    my $self = shift;
    my $getLocalClient = JPL::AutoLoader::getmeth('getLocalClient',[],['com.documentum.fc.client.IDfClient']);
    my $rv = "";
    eval { $rv = $$self->$getLocalClient(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfClient);
        return \$rv;
    }
}

sub getDFCVersion {
	## METHOD: java.lang.String getDFCVersion()
    my $self = shift;
    my $getDFCVersion = JPL::AutoLoader::getmeth('getDFCVersion',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDFCVersion(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLocalClient32 {
	## METHOD: com.documentum.fc.client.IDfClient getLocalClient32()
    my $self = shift;
    my $getLocalClient32 = JPL::AutoLoader::getmeth('getLocalClient32',[],['com.documentum.fc.client.IDfClient']);
    my $rv = "";
    eval { $rv = $$self->$getLocalClient32(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfClient);
        return \$rv;
    }
}

sub getRemoteClient {
	## METHOD: com.documentum.fc.client.IDfClient getRemoteClient(java.lang.String)
    my ($self,$p0) = @_;
    my $getRemoteClient = JPL::AutoLoader::getmeth('getRemoteClient',['java.lang.String'],['com.documentum.fc.client.IDfClient']);
    my $rv = "";
    eval { $rv = $$self->$getRemoteClient($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfClient);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
