# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryResultListener (com.documentum.fc.client.qb.IDfQueryResultListener)
# ------------------------------------------------------------------ #

package IDfQueryResultListener;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryResultListener';


sub receiveEvent {
	## METHOD: void receiveEvent(java.lang.Object)
    my ($self,$p0) = @_;
    my $receiveEvent = JPL::AutoLoader::getmeth('receiveEvent',['java.lang.Object'],[]);
    my $rv = "";
    eval { $rv = $$self->$receiveEvent($p0); };
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
