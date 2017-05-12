# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVirtualDocument (com.documentum.fc.client.IDfVirtualDocument)
# ------------------------------------------------------------------ #

package IDfVirtualDocument;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVirtualDocument';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfVDMNumberingScheme';
use JPL::Class 'com.documentum.fc.client.IDfVirtualDocumentNode';
use JPL::Class 'com.documentum.fc.common.IDfChangeDescription';
use JPL::Class 'com.documentum.fc.common.IDfProperties';

use constant EXCEPTION_CANT_SET_COPY_BEHAVIOR_FOR_ROOT => 2001;
use constant EXCEPTION_CANT_SET_USE_NODE_VER_LABEL_FOR_ROOT => 2002;
use constant EXCEPTION_OBJECT_IS_NOT_LOCKED => 2003;
use constant EXCEPTION_CANT_FIND_ASSEMBLY_OBJECT_TO_BE_REMOVED => 2004;
use constant EXCEPTION_BOOK_ID_DOESNT_MATCH_WITH_ASSEMBLY_PARENT_OBJECT_ID => 2005;
use constant EXCEPTION_PARENT_ID_OF_CONTAINMENT_DOESNT_MATCH_WITH_PARENT_OBJECT_ID => 2006;
use constant EXCEPTION_CANT_FIND_CONTAINMENT_OBJECT_TO_BE_REMOVED => 2007;
use constant EXCEPTION_CANT_FOLLOW_ASSEMBLY_WITHIN_AN_ASSMEBLY => 2008;
use constant EXCEPTION_CANT_SET_USE_NODE_VER_LABEL_WITHIN_AN_ASSMEBLY => 2009;
use constant EXCEPTION_CANT_GET_LATE_BINDING_VALUE => 2010;
use constant EXCEPTION_CANT_CREATE_ROOT => 2011;
use constant EXCEPTION_PARENT_NODE_CANT_BE_NULL => 2012;
use constant EXCEPTION_CHILD_CHRON_ID_CANT_BE_NULL => 2013;
use constant EXCEPTION_PARENT_OBJECT_CANT_BE_NULL => 2014;
use constant EXCEPTION_ASSEMBLY_PARENT_OBJECT_CANT_BE_NULL => 2015;
use constant EXCEPTION_CANT_REMOVE_ASSEMBLY_NODE_NO_ASSEMBLY_OBJECT => 2016;
use constant EXCEPTION_ASSEMBLY_PARENT_CANT_BE_LOCKED => 2017;
use constant EXCEPTION_CANT_SET_FOLLOW_ASSEMBLY => 2018;
use constant EXCEPTION_CANT_SET_COPY_BEHAVIOR => 2019;
use constant EXCEPTION_CANT_SET_BINDING => 2020;
use constant EXCEPTION_CANT_SET_USE_NODE_VER_LABEL => 2021;
use constant EXCEPTION_CANT_ADD_NODE => 2022;
use constant EXCEPTION_CANT_REMOVE_NODE => 2023;
use constant EXCEPTION_CANT_SET_ASSEMBLY_DOCUMENT_BINDING => 2024;
use constant ADDED_CHILD => 2501;
use constant REMOVED_CHILD => 2502;
use constant COPY_BEHAVIOR_MODIFIED => 2503;
use constant USE_NODE_VER_LABEL_MODIFIED => 2504;
use constant FOLLOW_ASSEMBLY_MODIFIED => 2505;
use constant VERSION_LABEL_MODIFIED => 2506;
use constant REMOVED_ASSEMBLY => 2507;
use constant ASSOCIATED_ASSEMBLY => 2508;
use constant ASSEMBLY_MODIFIED => 2509;
use constant REVERT_ON_RESYNC => 1;
use constant DONT_REVERT_ASSEMBLIES => 2;

sub find {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode find(com.documentum.fc.client.IDfVirtualDocumentNode,java.lang.String,java.lang.String,int)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $find = JPL::AutoLoader::getmeth('find',['com.documentum.fc.client.IDfVirtualDocumentNode','java.lang.String','java.lang.String','int'],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$find($$p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
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

sub getId {
	## METHOD: com.documentum.fc.common.IDfId getId()
    my $self = shift;
    my $getId = JPL::AutoLoader::getmeth('getId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getRootNode {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode getRootNode()
    my $self = shift;
    my $getRootNode = JPL::AutoLoader::getmeth('getRootNode',[],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$getRootNode(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub getNumberingScheme {
	## METHOD: com.documentum.fc.client.IDfVDMNumberingScheme getNumberingScheme()
    my $self = shift;
    my $getNumberingScheme = JPL::AutoLoader::getmeth('getNumberingScheme',[],['com.documentum.fc.client.IDfVDMNumberingScheme']);
    my $rv = "";
    eval { $rv = $$self->$getNumberingScheme(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVDMNumberingScheme);
        return \$rv;
    }
}

sub removeAllChangeDescriptions {
	## METHOD: void removeAllChangeDescriptions(java.lang.String)
    my ($self,$p0) = @_;
    my $removeAllChangeDescriptions = JPL::AutoLoader::getmeth('removeAllChangeDescriptions',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeAllChangeDescriptions($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChangeDescription {
	## METHOD: com.documentum.fc.common.IDfChangeDescription getChangeDescription(int)
    my ($self,$p0) = @_;
    my $getChangeDescription = JPL::AutoLoader::getmeth('getChangeDescription',['int'],['com.documentum.fc.common.IDfChangeDescription']);
    my $rv = "";
    eval { $rv = $$self->$getChangeDescription($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfChangeDescription);
        return \$rv;
    }
}

sub getUniqueObjectIdCount {
	## METHOD: int getUniqueObjectIdCount()
    my $self = shift;
    my $getUniqueObjectIdCount = JPL::AutoLoader::getmeth('getUniqueObjectIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getUniqueObjectIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resync {
	## METHOD: void resync(com.documentum.fc.client.IDfSession,com.documentum.fc.common.IDfId,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $resync = JPL::AutoLoader::getmeth('resync',['com.documentum.fc.client.IDfSession','com.documentum.fc.common.IDfId','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$resync($$p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeNode {
	## METHOD: void removeNode(com.documentum.fc.client.IDfVirtualDocumentNode)
    my ($self,$p0) = @_;
    my $removeNode = JPL::AutoLoader::getmeth('removeNode',['com.documentum.fc.client.IDfVirtualDocumentNode'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeNode($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resetSelectedVersionsFromBinding {
	## METHOD: void resetSelectedVersionsFromBinding()
    my $self = shift;
    my $resetSelectedVersionsFromBinding = JPL::AutoLoader::getmeth('resetSelectedVersionsFromBinding',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resetSelectedVersionsFromBinding(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNodeFromNodeId {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode getNodeFromNodeId(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $getNodeFromNodeId = JPL::AutoLoader::getmeth('getNodeFromNodeId',['com.documentum.fc.common.IDfId'],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$getNodeFromNodeId($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub removeChangeDescription {
	## METHOD: void removeChangeDescription(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $removeChangeDescription = JPL::AutoLoader::getmeth('removeChangeDescription',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeChangeDescription($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChangeDescriptionCount {
	## METHOD: int getChangeDescriptionCount()
    my $self = shift;
    my $getChangeDescriptionCount = JPL::AutoLoader::getmeth('getChangeDescriptionCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getChangeDescriptionCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addNode {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode addNode(com.documentum.fc.client.IDfVirtualDocumentNode,com.documentum.fc.client.IDfVirtualDocumentNode,com.documentum.fc.common.IDfId,java.lang.String,boolean,boolean)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $addNode = JPL::AutoLoader::getmeth('addNode',['com.documentum.fc.client.IDfVirtualDocumentNode','com.documentum.fc.client.IDfVirtualDocumentNode','com.documentum.fc.common.IDfId','java.lang.String','boolean','boolean'],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$addNode($$p0,$$p1,$$p2,$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub getUniqueObjectId {
	## METHOD: com.documentum.fc.common.IDfId getUniqueObjectId(int)
    my ($self,$p0) = @_;
    my $getUniqueObjectId = JPL::AutoLoader::getmeth('getUniqueObjectId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getUniqueObjectId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub addChangeDescription {
	## METHOD: void addChangeDescription(int,com.documentum.fc.common.IDfId,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $addChangeDescription = JPL::AutoLoader::getmeth('addChangeDescription',['int','com.documentum.fc.common.IDfId','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$addChangeDescription($p0,$$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addNodeToNode {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode addNodeToNode(com.documentum.fc.client.IDfVirtualDocumentNode,com.documentum.fc.client.IDfVirtualDocumentNode,com.documentum.fc.client.IDfVirtualDocumentNode)
    my ($self,$p0,$p1,$p2) = @_;
    my $addNodeToNode = JPL::AutoLoader::getmeth('addNodeToNode',['com.documentum.fc.client.IDfVirtualDocumentNode','com.documentum.fc.client.IDfVirtualDocumentNode','com.documentum.fc.client.IDfVirtualDocumentNode'],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$addNodeToNode($$p0,$$p1,$$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub setIncludeBrokenBindings {
	## METHOD: void setIncludeBrokenBindings(boolean)
    my ($self,$p0) = @_;
    my $setIncludeBrokenBindings = JPL::AutoLoader::getmeth('setIncludeBrokenBindings',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setIncludeBrokenBindings($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getIncludeBrokenBindings {
	## METHOD: boolean getIncludeBrokenBindings()
    my $self = shift;
    my $getIncludeBrokenBindings = JPL::AutoLoader::getmeth('getIncludeBrokenBindings',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getIncludeBrokenBindings(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setNumberingScheme {
	## METHOD: void setNumberingScheme(com.documentum.fc.client.IDfVDMNumberingScheme)
    my ($self,$p0) = @_;
    my $setNumberingScheme = JPL::AutoLoader::getmeth('setNumberingScheme',['com.documentum.fc.client.IDfVDMNumberingScheme'],[]);
    my $rv = "";
    eval { $rv = $$self->$setNumberingScheme($$p0); };
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
