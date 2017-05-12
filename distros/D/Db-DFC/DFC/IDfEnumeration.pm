# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfEnumeration (com.documentum.fc.client.IDfEnumeration)
# ------------------------------------------------------------------ #

package IDfEnumeration;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfEnumeration';


sub nextElement {
	## METHOD: java.lang.Object nextElement()
    my $self = shift;
    my $nextElement = JPL::AutoLoader::getmeth('nextElement',[],['java.lang.Object']);
    my $rv = "";
    eval { $rv = $$self->$nextElement(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasMoreElements {
	## METHOD: boolean hasMoreElements()
    my $self = shift;
    my $hasMoreElements = JPL::AutoLoader::getmeth('hasMoreElements',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasMoreElements(); };
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
