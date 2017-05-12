# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfQueryFullText (com.documentum.fc.client.qb.IDfQueryFullText)
# ------------------------------------------------------------------ #

package IDfQueryFullText;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::qb::IDfQueryFullText';

use constant NONE => "DC_FT_NONE";
use constant TOPICONLY => "DC_FT_TOPICONLY";
use constant ZONE => "DC_FT_ZONE";
use constant THESAURUS => "DC_FT_THESAURUS";
use constant SOUNDEX => "DC_FT_SOUNDEX";
use constant STEM => "DC_FT_STEM";
use constant LIKE => "DC_FT_LIKE";
use constant NOPROX => "DC_FT_PROX_NONE";
use constant SENTENCE => "DC_FT_PROX_SENTENCE";
use constant PARAGRAPH => "DC_FT_PROX_PARAGRAPH";
use constant NEAR => "DC_FT_PROX_NEAR";
use constant DEPREC_TYPE_NONE => "None";
use constant DEPREC_TYPE_WL => "Word List";
use constant DEPREC_TYPE_TOPIC => "Topic Query";
use constant ZOP_CONTAINS => "DC_FT_ZONE_CONTAINS";
use constant ZOP_MATCHES => "DC_FT_ZONE_MATCHES";
use constant ZOP_STARTS => "DC_FT_ZONE_STARTS";
use constant ZOP_ENDS => "DC_FT_ZONE_ENDS";
use constant ZOP_SUBSTR => "DC_FT_ZONE_SUBSTRING";

sub getVariant {
	## METHOD: java.lang.String getVariant()
    my $self = shift;
    my $getVariant = JPL::AutoLoader::getmeth('getVariant',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVariant(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setIgnoreCaseSearching {
	## METHOD: void setIgnoreCaseSearching(boolean)
    my ($self,$p0) = @_;
    my $setIgnoreCaseSearching = JPL::AutoLoader::getmeth('setIgnoreCaseSearching',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setIgnoreCaseSearching($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isIgnoreCaseSearching {
	## METHOD: boolean isIgnoreCaseSearching()
    my $self = shift;
    my $isIgnoreCaseSearching = JPL::AutoLoader::getmeth('isIgnoreCaseSearching',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isIgnoreCaseSearching(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isVisible {
	## METHOD: boolean isVisible()
    my $self = shift;
    my $isVisible = JPL::AutoLoader::getmeth('isVisible',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isVisible(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setVisible {
	## METHOD: void setVisible(boolean)
    my ($self,$p0) = @_;
    my $setVisible = JPL::AutoLoader::getmeth('setVisible',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVisible($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVerityString {
	## METHOD: java.lang.String getVerityString()
    my $self = shift;
    my $getVerityString = JPL::AutoLoader::getmeth('getVerityString',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVerityString(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setVerityString {
	## METHOD: void setVerityString(java.lang.String)
    my ($self,$p0) = @_;
    my $setVerityString = JPL::AutoLoader::getmeth('setVerityString',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVerityString($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setVariant {
	## METHOD: void setVariant(java.lang.String)
    my ($self,$p0) = @_;
    my $setVariant = JPL::AutoLoader::getmeth('setVariant',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setVariant($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setZone {
	## METHOD: void setZone(java.lang.String)
    my ($self,$p0) = @_;
    my $setZone = JPL::AutoLoader::getmeth('setZone',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setZone($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setZoneAttribute {
	## METHOD: void setZoneAttribute(java.lang.String)
    my ($self,$p0) = @_;
    my $setZoneAttribute = JPL::AutoLoader::getmeth('setZoneAttribute',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setZoneAttribute($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setZoneOp {
	## METHOD: void setZoneOp(java.lang.String)
    my ($self,$p0) = @_;
    my $setZoneOp = JPL::AutoLoader::getmeth('setZoneOp',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setZoneOp($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setZoneValue {
	## METHOD: void setZoneValue(java.lang.String)
    my ($self,$p0) = @_;
    my $setZoneValue = JPL::AutoLoader::getmeth('setZoneValue',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setZoneValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setInOrder {
	## METHOD: void setInOrder(boolean)
    my ($self,$p0) = @_;
    my $setInOrder = JPL::AutoLoader::getmeth('setInOrder',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setInOrder($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFindAny {
	## METHOD: void setFindAny(boolean)
    my ($self,$p0) = @_;
    my $setFindAny = JPL::AutoLoader::getmeth('setFindAny',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFindAny($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setMany {
	## METHOD: void setMany(boolean)
    my ($self,$p0) = @_;
    my $setMany = JPL::AutoLoader::getmeth('setMany',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setMany($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setNegate {
	## METHOD: void setNegate(boolean)
    my ($self,$p0) = @_;
    my $setNegate = JPL::AutoLoader::getmeth('setNegate',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setNegate($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setNearValue {
	## METHOD: void setNearValue(java.lang.String)
    my ($self,$p0) = @_;
    my $setNearValue = JPL::AutoLoader::getmeth('setNearValue',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setNearValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFindAny {
	## METHOD: boolean getFindAny()
    my $self = shift;
    my $getFindAny = JPL::AutoLoader::getmeth('getFindAny',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFindAny(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getZone {
	## METHOD: java.lang.String getZone()
    my $self = shift;
    my $getZone = JPL::AutoLoader::getmeth('getZone',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getZone(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getZoneAttribute {
	## METHOD: java.lang.String getZoneAttribute()
    my $self = shift;
    my $getZoneAttribute = JPL::AutoLoader::getmeth('getZoneAttribute',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getZoneAttribute(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getZoneOp {
	## METHOD: java.lang.String getZoneOp()
    my $self = shift;
    my $getZoneOp = JPL::AutoLoader::getmeth('getZoneOp',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getZoneOp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getZoneValue {
	## METHOD: java.lang.String getZoneValue()
    my $self = shift;
    my $getZoneValue = JPL::AutoLoader::getmeth('getZoneValue',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getZoneValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getInOrder {
	## METHOD: boolean getInOrder()
    my $self = shift;
    my $getInOrder = JPL::AutoLoader::getmeth('getInOrder',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getInOrder(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNegate {
	## METHOD: boolean getNegate()
    my $self = shift;
    my $getNegate = JPL::AutoLoader::getmeth('getNegate',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getNegate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNearValue {
	## METHOD: java.lang.String getNearValue()
    my $self = shift;
    my $getNearValue = JPL::AutoLoader::getmeth('getNearValue',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNearValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMany {
	## METHOD: boolean getMany()
    my $self = shift;
    my $getMany = JPL::AutoLoader::getmeth('getMany',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getMany(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTextCount {
	## METHOD: int getTextCount()
    my $self = shift;
    my $getTextCount = JPL::AutoLoader::getmeth('getTextCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getTextCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertText {
	## METHOD: boolean insertText(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $insertText = JPL::AutoLoader::getmeth('insertText',['java.lang.String','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$insertText($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeText {
	## METHOD: boolean removeText(int,int)
    my ($self,$p0,$p1) = @_;
    my $removeText = JPL::AutoLoader::getmeth('removeText',['int','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$removeText($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeAllText {
	## METHOD: boolean removeAllText()
    my $self = shift;
    my $removeAllText = JPL::AutoLoader::getmeth('removeAllText',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$removeAllText(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getText {
	## METHOD: java.lang.String getText(int)
    my ($self,$p0) = @_;
    my $getText = JPL::AutoLoader::getmeth('getText',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getText($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasPhrases {
	## METHOD: boolean hasPhrases()
    my $self = shift;
    my $hasPhrases = JPL::AutoLoader::getmeth('hasPhrases',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasPhrases(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasWildcards {
	## METHOD: boolean hasWildcards()
    my $self = shift;
    my $hasWildcards = JPL::AutoLoader::getmeth('hasWildcards',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasWildcards(); };
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
