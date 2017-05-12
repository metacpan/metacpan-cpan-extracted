# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfValueContext (com.documentum.fc.common.DfValueContext)
# ------------------------------------------------------------------ #

package DfValueContext;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfValueContext';



sub new {
    my ($class,$p0) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfValueContext(java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfValueContext()

    if ($p0 =~ /\w+/) {
        my $new = JPL::AutoLoader::getmeth('new',['java.lang.String'],[]);
        eval { $rv = com::documentum::fc::common::DfValueContext->$new($p0); };
    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfValueContext->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,DfValueContext);
        return \$rv;
    }
}

sub getDateFormatString {
	## METHOD: java.lang.String getDateFormatString()
    my $self = shift;
    my $getDateFormatString = JPL::AutoLoader::getmeth('getDateFormatString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDateFormatString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDateFormat {
	## METHOD: java.text.SimpleDateFormat getDateFormat()
    my $self = shift;
    my $getDateFormat = JPL::AutoLoader::getmeth('getDateFormat',[],['java.text.SimpleDateFormat']);
    my $rv = "";
    eval { $rv = $$self->$getDateFormat(); };
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
