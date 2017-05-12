# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryResultEvent (com.documentum.fc.client.qb.IDfQueryResultEvent)
# ------------------------------------------------------------------ #

package IDfQueryResultEvent;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryResultEvent';

use constant PARTIAL_UPDATE => 0;
use constant FINISHED => 1;

sub getIncrementSize {
	## METHOD: int getIncrementSize()
    my $self = shift;
    my $getIncrementSize = JPL::AutoLoader::getmeth('getIncrementSize',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getIncrementSize(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getEventID {
	## METHOD: int getEventID()
    my $self = shift;
    my $getEventID = JPL::AutoLoader::getmeth('getEventID',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getEventID(); };
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
