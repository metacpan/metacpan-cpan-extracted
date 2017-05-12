# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfTime (com.documentum.fc.common.IDfTime)
# ------------------------------------------------------------------ #

package IDfTime;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::common::IDfTime';

use constant DF_TIME_PATTERN1 => "mm/dd/yy";
use constant DF_TIME_PATTERN2 => "mm/dd/yyyy";
use constant DF_TIME_PATTERN3 => "dd-mon-yy";
use constant DF_TIME_PATTERN4 => "dd-mon-yyyy";
use constant DF_TIME_PATTERN5 => "month dd yy";
use constant DF_TIME_PATTERN6 => "month dd, yy";
use constant DF_TIME_PATTERN7 => "month dd yyyy";
use constant DF_TIME_PATTERN8 => "month dd, yyyy";
use constant DF_TIME_PATTERN9 => "mon dd yy";
use constant DF_TIME_PATTERN10 => "mon dd yyyy";
use constant DF_TIME_PATTERN11 => "mm/yy";
use constant DF_TIME_PATTERN12 => "mm/yyyy";
use constant DF_TIME_PATTERN13 => "dd/mm/yy";
use constant DF_TIME_PATTERN14 => "dd/mm/yyyy";
use constant DF_TIME_PATTERN15 => "mm/yy hh:mi:ss";
use constant DF_TIME_PATTERN16 => "mm/yyyy hh:mi:ss";
use constant DF_TIME_PATTERN17 => "dd/mm/yy hh:mi:ss";
use constant DF_TIME_PATTERN18 => "dd/mm/yyyy hh:mi:ss";
use constant DF_TIME_PATTERN19 => "yy/mm";
use constant DF_TIME_PATTERN20 => "yyyy/mm";
use constant DF_TIME_PATTERN21 => "yy/mm/dd";
use constant DF_TIME_PATTERN22 => "yyyy/mm/dd";
use constant DF_TIME_PATTERN23 => "yy/mm hh:mi:ss";
use constant DF_TIME_PATTERN24 => "yyyy/mm hh:mi:ss";
use constant DF_TIME_PATTERN25 => "yy/mm/dd hh:mi:ss";
use constant DF_TIME_PATTERN26 => "yyyy/mm/dd hh:mi:ss";
use constant DF_TIME_PATTERN27 => "yy";
use constant DF_TIME_PATTERN28 => "yyyy";
use constant DF_TIME_PATTERN29 => "mon-yy";
use constant DF_TIME_PATTERN30 => "mon-yyyy";
use constant DF_TIME_PATTERN31 => "yy hh:mi:ss";
use constant DF_TIME_PATTERN32 => "yyyy hh:mi:ss";
use constant DF_TIME_PATTERN33 => "mon-yy hh:mi:ss";
use constant DF_TIME_PATTERN34 => "mon-yyyy hh:mi:ss";
use constant DF_TIME_PATTERN35 => "month yy";
use constant DF_TIME_PATTERN36 => "month yyyy";
use constant DF_TIME_PATTERN37 => "month, yy";
use constant DF_TIME_PATTERN38 => "month, yyyy";
use constant DF_TIME_PATTERN39 => "month yy hh:mi:ss";
use constant DF_TIME_PATTERN40 => "month yyyy hh:mi:ss";
use constant DF_TIME_PATTERN41 => "month, yy hh:mi:ss";
use constant DF_TIME_PATTERN42 => "month, yyyy hh:mi:ss";
use constant DF_TIME_PATTERN43 => "mm/dd/yy hh:mi:ss";
use constant DF_TIME_PATTERN44 => "mm/dd/yyyy hh:mi:ss";
use constant DF_TIME_PATTERN_DEFAULT => "";

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
