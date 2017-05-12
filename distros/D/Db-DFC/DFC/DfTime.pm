# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfTime (com.documentum.fc.common.DfTime)
# ------------------------------------------------------------------ #

package DfTime;
@ISA = (IDfTime);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::DfTime';

use constant DF_NULLDATE_STR => "nulldate";
use constant DF_NULLDATE => "nulldate";
use constant UNKNOWN => -1;
use constant FALSE => 0;
use constant TRUE => 1;
use constant DOCOMPARE => 2;
use constant REGIONAL_SETTINGS_TOKEN => "DEFAULT";


sub new {
    my ($class,$p0,$p1) = @_;
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.common.DfTime(java.util.Date)
    ## CONSTRUCTOR: com.documentum.fc.common.DfTime(java.lang.String,com.documentum.fc.common.DfValueContext)
    ## CONSTRUCTOR: com.documentum.fc.common.DfTime(java.lang.String,java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfTime(java.lang.String)
    ## CONSTRUCTOR: com.documentum.fc.common.DfTime()

    if (ref($p0) =~ /Date/) {
        my $new = JPL::AutoLoader::getmeth('new',['java.util.Date'],[]);
        eval { $rv = com::documentum::fc::common::DfTime->$new($p0); };
    } elsif ($p0 =~ /\w+/) {

        if (ref($p1) =~ /DfValueContext/) {
            my $new = JPL::AutoLoader::getmeth('new',['java.lang.String','com.documentum.fc.common.DfValueContext'],[]);
            eval { $rv = com::documentum::fc::common::DfTime->$new($p0,$$p1); };
        } elsif ($p1 =~ /\w+/) {
            my $new = JPL::AutoLoader::getmeth('new',['java.lang.String','java.lang.String'],[]);
            eval { $rv = com::documentum::fc::common::DfTime->$new($p0,$p1); };
        } else {
            my $new = JPL::AutoLoader::getmeth('new',['java.lang.String'],[]);
            eval { $rv = com::documentum::fc::common::DfTime->$new($p0); };
        }

    } else {
        my $new = JPL::AutoLoader::getmeth('new',[],[]);
        eval { $rv = com::documentum::fc::common::DfTime->$new(); };
    }

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfTime);
        return \$rv;
    }
}

sub compareTo {
	## METHOD: int compareTo(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $compareTo = JPL::AutoLoader::getmeth('compareTo',['com.documentum.fc.common.IDfTime'],['int']);
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

sub getYear {
	## METHOD: int getYear()
    my $self = shift;
    my $getYear = JPL::AutoLoader::getmeth('getYear',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getYear(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMonth {
	## METHOD: int getMonth()
    my $self = shift;
    my $getMonth = JPL::AutoLoader::getmeth('getMonth',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getMonth(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDate {
	## METHOD: java.util.Date getDate()
    my $self = shift;
    my $getDate = JPL::AutoLoader::getmeth('getDate',[],['java.util.Date']);
    my $rv = "";
    eval { $rv = $$self->$getDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMinutes {
	## METHOD: int getMinutes()
    my $self = shift;
    my $getMinutes = JPL::AutoLoader::getmeth('getMinutes',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getMinutes(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSeconds {
	## METHOD: int getSeconds()
    my $self = shift;
    my $getSeconds = JPL::AutoLoader::getmeth('getSeconds',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getSeconds(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isValid {
	## METHOD: boolean isValid()
    my $self = shift;
    my $isValid = JPL::AutoLoader::getmeth('isValid',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isValid(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHour {
	## METHOD: int getHour()
    my $self = shift;
    my $getHour = JPL::AutoLoader::getmeth('getHour',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getHour(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDay {
	## METHOD: int getDay()
    my $self = shift;
    my $getDay = JPL::AutoLoader::getmeth('getDay',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getDay(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asString {
	## METHOD: java.lang.String asString(java.lang.String)
    my ($self,$p0) = @_;
    my $asString = JPL::AutoLoader::getmeth('asString',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$asString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPattern {
	## METHOD: java.lang.String getPattern()
    my $self = shift;
    my $getPattern = JPL::AutoLoader::getmeth('getPattern',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPattern(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isNullDate {
	## METHOD: boolean isNullDate()
    my $self = shift;
    my $isNullDate = JPL::AutoLoader::getmeth('isNullDate',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNullDate(); };
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
