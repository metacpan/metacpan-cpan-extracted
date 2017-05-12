# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfOperationPopulator (com.documentum.operations.IDfOperationPopulator)
# ------------------------------------------------------------------ #

package IDfOperationPopulator;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfOperationPopulator';
use JPL::Class 'com.documentum.fc.common.IDfProperties';


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

sub getProperties {
	## METHOD: com.documentum.fc.common.IDfProperties getProperties()
    my $self = shift;
    my $getProperties = JPL::AutoLoader::getmeth('getProperties',[],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getProperties(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
