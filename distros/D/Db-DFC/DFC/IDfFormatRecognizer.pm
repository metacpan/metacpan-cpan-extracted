# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfFormatRecognizer (com.documentum.operations.IDfFormatRecognizer)
# ------------------------------------------------------------------ #

package IDfFormatRecognizer;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::operations::IDfFormatRecognizer';
use JPL::Class 'com.documentum.fc.common.IDfList';


sub getDefaultSuggestedFileFormat {
	## METHOD: java.lang.String getDefaultSuggestedFileFormat()
    my $self = shift;
    my $getDefaultSuggestedFileFormat = JPL::AutoLoader::getmeth('getDefaultSuggestedFileFormat',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDefaultSuggestedFileFormat(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSuggestedFileFormats {
	## METHOD: com.documentum.fc.common.IDfList getSuggestedFileFormats()
    my $self = shift;
    my $getSuggestedFileFormats = JPL::AutoLoader::getmeth('getSuggestedFileFormats',[],['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $$self->$getSuggestedFileFormats(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfList);
        return \$rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
