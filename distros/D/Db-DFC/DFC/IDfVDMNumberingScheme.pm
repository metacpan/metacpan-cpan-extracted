# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVDMNumberingScheme (com.documentum.fc.client.IDfVDMNumberingScheme)
# ------------------------------------------------------------------ #

package IDfVDMNumberingScheme;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVDMNumberingScheme';


sub getNodeNumber {
	## METHOD: java.lang.String getNodeNumber(com.documentum.fc.client.IDfVirtualDocumentNode)
    my ($self,$p0) = @_;
    my $getNodeNumber = JPL::AutoLoader::getmeth('getNodeNumber',['com.documentum.fc.client.IDfVirtualDocumentNode'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNodeNumber($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setStartingNumber {
	## METHOD: void setStartingNumber(java.lang.String)
    my ($self,$p0) = @_;
    my $setStartingNumber = JPL::AutoLoader::getmeth('setStartingNumber',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setStartingNumber($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStartingNumber {
	## METHOD: java.lang.String getStartingNumber()
    my $self = shift;
    my $getStartingNumber = JPL::AutoLoader::getmeth('getStartingNumber',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getStartingNumber(); };
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
