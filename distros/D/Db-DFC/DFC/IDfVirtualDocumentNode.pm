# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfVirtualDocumentNode (com.documentum.fc.client.IDfVirtualDocumentNode)
# ------------------------------------------------------------------ #

package IDfVirtualDocumentNode;

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfVirtualDocumentNode';
use JPL::Class 'com.documentum.fc.client.IDfVersionTreeLabels';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfVirtualDocument';
use JPL::Class 'com.documentum.fc.client.IDfSysObject';
use JPL::Class 'com.documentum.fc.client.IDfVirtualDocumentNode';
use JPL::Class 'com.documentum.fc.common.IDfProperties';


sub getParent {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode getParent()
    my $self = shift;
    my $getParent = JPL::AutoLoader::getmeth('getParent',[],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$getParent(); };
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

sub getChildCount {
	## METHOD: int getChildCount()
    my $self = shift;
    my $getChildCount = JPL::AutoLoader::getmeth('getChildCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getChildCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChild {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode getChild(int)
    my ($self,$p0) = @_;
    my $getChild = JPL::AutoLoader::getmeth('getChild',['int'],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$getChild($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub getSelectedObject {
	## METHOD: com.documentum.fc.client.IDfSysObject getSelectedObject()
    my $self = shift;
    my $getSelectedObject = JPL::AutoLoader::getmeth('getSelectedObject',[],['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $$self->$getSelectedObject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSysObject);
        return \$rv;
    }
}

sub getVDMNumber {
	## METHOD: java.lang.String getVDMNumber()
    my $self = shift;
    my $getVDMNumber = JPL::AutoLoader::getmeth('getVDMNumber',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVDMNumber(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVirtualDocumentFromNode {
	## METHOD: com.documentum.fc.client.IDfVirtualDocument getVirtualDocumentFromNode()
    my $self = shift;
    my $getVirtualDocumentFromNode = JPL::AutoLoader::getmeth('getVirtualDocumentFromNode',[],['com.documentum.fc.client.IDfVirtualDocument']);
    my $rv = "";
    eval { $rv = $$self->$getVirtualDocumentFromNode(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocument);
        return \$rv;
    }
}

sub setFollowAssembly {
	## METHOD: void setFollowAssembly(boolean)
    my ($self,$p0) = @_;
    my $setFollowAssembly = JPL::AutoLoader::getmeth('setFollowAssembly',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFollowAssembly($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFollowAssembly {
	## METHOD: boolean getFollowAssembly()
    my $self = shift;
    my $getFollowAssembly = JPL::AutoLoader::getmeth('getFollowAssembly',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFollowAssembly(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNodeToken {
	## METHOD: java.lang.String getNodeToken()
    my $self = shift;
    my $getNodeToken = JPL::AutoLoader::getmeth('getNodeToken',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNodeToken(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAvailableVersions {
	## METHOD: com.documentum.fc.client.IDfVersionTreeLabels getAvailableVersions()
    my $self = shift;
    my $getAvailableVersions = JPL::AutoLoader::getmeth('getAvailableVersions',[],['com.documentum.fc.client.IDfVersionTreeLabels']);
    my $rv = "";
    eval { $rv = $$self->$getAvailableVersions(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVersionTreeLabels);
        return \$rv;
    }
}

sub getOverrideLateBindingValue {
	## METHOD: boolean getOverrideLateBindingValue()
    my $self = shift;
    my $getOverrideLateBindingValue = JPL::AutoLoader::getmeth('getOverrideLateBindingValue',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getOverrideLateBindingValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isVirtualDocument {
	## METHOD: boolean isVirtualDocument()
    my $self = shift;
    my $isVirtualDocument = JPL::AutoLoader::getmeth('isVirtualDocument',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isVirtualDocument(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOverrideLateBindingValue {
	## METHOD: void setOverrideLateBindingValue(boolean)
    my ($self,$p0) = @_;
    my $setOverrideLateBindingValue = JPL::AutoLoader::getmeth('setOverrideLateBindingValue',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOverrideLateBindingValue($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLateBindingValue {
	## METHOD: java.lang.String getLateBindingValue()
    my $self = shift;
    my $getLateBindingValue = JPL::AutoLoader::getmeth('getLateBindingValue',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLateBindingValue(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isFromAssembly {
	## METHOD: boolean isFromAssembly()
    my $self = shift;
    my $isFromAssembly = JPL::AutoLoader::getmeth('isFromAssembly',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isFromAssembly(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isRoot {
	## METHOD: boolean isRoot()
    my $self = shift;
    my $isRoot = JPL::AutoLoader::getmeth('isRoot',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isRoot(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRelationshipId {
	## METHOD: com.documentum.fc.common.IDfId getRelationshipId()
    my $self = shift;
    my $getRelationshipId = JPL::AutoLoader::getmeth('getRelationshipId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getRelationshipId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getAssemblyDocumentBinding {
	## METHOD: java.lang.String getAssemblyDocumentBinding()
    my $self = shift;
    my $getAssemblyDocumentBinding = JPL::AutoLoader::getmeth('getAssemblyDocumentBinding',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAssemblyDocumentBinding(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAssemblyDocumentBinding {
	## METHOD: void setAssemblyDocumentBinding(java.lang.String)
    my ($self,$p0) = @_;
    my $setAssemblyDocumentBinding = JPL::AutoLoader::getmeth('setAssemblyDocumentBinding',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAssemblyDocumentBinding($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub causesCycle {
	## METHOD: boolean causesCycle()
    my $self = shift;
    my $causesCycle = JPL::AutoLoader::getmeth('causesCycle',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$causesCycle(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isBindingBroken {
	## METHOD: boolean isBindingBroken()
    my $self = shift;
    my $isBindingBroken = JPL::AutoLoader::getmeth('isBindingBroken',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isBindingBroken(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub areChildrenCompound {
	## METHOD: boolean areChildrenCompound()
    my $self = shift;
    my $areChildrenCompound = JPL::AutoLoader::getmeth('areChildrenCompound',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$areChildrenCompound(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAssemblyParent {
	## METHOD: com.documentum.fc.client.IDfVirtualDocumentNode getAssemblyParent()
    my $self = shift;
    my $getAssemblyParent = JPL::AutoLoader::getmeth('getAssemblyParent',[],['com.documentum.fc.client.IDfVirtualDocumentNode']);
    my $rv = "";
    eval { $rv = $$self->$getAssemblyParent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocumentNode);
        return \$rv;
    }
}

sub isCompound {
	## METHOD: boolean isCompound()
    my $self = shift;
    my $isCompound = JPL::AutoLoader::getmeth('isCompound',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isCompound(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAssemblyDocument {
	## METHOD: com.documentum.fc.client.IDfSysObject getAssemblyDocument()
    my $self = shift;
    my $getAssemblyDocument = JPL::AutoLoader::getmeth('getAssemblyDocument',[],['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $$self->$getAssemblyDocument(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfSysObject);
        return \$rv;
    }
}

sub disassemble {
	## METHOD: void disassemble()
    my $self = shift;
    my $disassemble = JPL::AutoLoader::getmeth('disassemble',[],[]);
    my $rv = "";
    eval { $rv = $$self->$disassemble(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getChronId {
	## METHOD: com.documentum.fc.common.IDfId getChronId()
    my $self = shift;
    my $getChronId = JPL::AutoLoader::getmeth('getChronId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getChronId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getBinding {
	## METHOD: java.lang.String getBinding()
    my $self = shift;
    my $getBinding = JPL::AutoLoader::getmeth('getBinding',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getBinding(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setBinding {
	## METHOD: void setBinding(java.lang.String)
    my ($self,$p0) = @_;
    my $setBinding = JPL::AutoLoader::getmeth('setBinding',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setBinding($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub doesSelectedVersionMatchBinding {
	## METHOD: boolean doesSelectedVersionMatchBinding()
    my $self = shift;
    my $doesSelectedVersionMatchBinding = JPL::AutoLoader::getmeth('doesSelectedVersionMatchBinding',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$doesSelectedVersionMatchBinding(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resetSelectedVersionFromBinding {
	## METHOD: void resetSelectedVersionFromBinding()
    my $self = shift;
    my $resetSelectedVersionFromBinding = JPL::AutoLoader::getmeth('resetSelectedVersionFromBinding',[],[]);
    my $rv = "";
    eval { $rv = $$self->$resetSelectedVersionFromBinding(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSelectedVersion {
	## METHOD: void setSelectedVersion(java.lang.String)
    my ($self,$p0) = @_;
    my $setSelectedVersion = JPL::AutoLoader::getmeth('setSelectedVersion',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSelectedVersion($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCopyBehavior {
	## METHOD: int getCopyBehavior()
    my $self = shift;
    my $getCopyBehavior = JPL::AutoLoader::getmeth('getCopyBehavior',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCopyBehavior(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setCopyBehavior {
	## METHOD: void setCopyBehavior(int)
    my ($self,$p0) = @_;
    my $setCopyBehavior = JPL::AutoLoader::getmeth('setCopyBehavior',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setCopyBehavior($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub assemble {
	## METHOD: void assemble(com.documentum.fc.client.IDfSysObject)
    my ($self,$p0) = @_;
    my $assemble = JPL::AutoLoader::getmeth('assemble',['com.documentum.fc.client.IDfSysObject'],[]);
    my $rv = "";
    eval { $rv = $$self->$assemble($$p0); };
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
