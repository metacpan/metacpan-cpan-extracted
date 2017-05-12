# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfSysObject (com.documentum.fc.client.IDfSysObject)
# ------------------------------------------------------------------ #

package IDfSysObject;
@ISA = (IDfPersistentObject);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfSysObject';
use JPL::Class 'com.documentum.fc.client.IDfVersionPolicy';
use JPL::Class 'com.documentum.fc.common.IDfId';
use JPL::Class 'com.documentum.fc.client.IDfVirtualDocument';
use JPL::Class 'com.documentum.fc.client.IDfACL';
use JPL::Class 'com.documentum.fc.common.IDfTime';
use JPL::Class 'com.documentum.fc.client.IDfVersionLabels';
use JPL::Class 'com.documentum.fc.client.IDfFormat';
use JPL::Class 'com.documentum.fc.client.IDfCollection';


sub print {
	## METHOD: java.lang.String print(java.lang.String,boolean,boolean,int,int,int)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $print = JPL::AutoLoader::getmeth('print',['java.lang.String','boolean','boolean','int','int','int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$print($p0,$p1,$p2,$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub queue {
	## METHOD: com.documentum.fc.common.IDfId queue(java.lang.String,java.lang.String,int,boolean,com.documentum.fc.common.IDfTime,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $queue = JPL::AutoLoader::getmeth('queue',['java.lang.String','java.lang.String','int','boolean','com.documentum.fc.common.IDfTime','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$queue($p0,$p1,$p2,$p3,$$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub resume {
	## METHOD: void resume(java.lang.String,boolean,boolean,boolean)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $resume = JPL::AutoLoader::getmeth('resume',['java.lang.String','boolean','boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$resume($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub suspend {
	## METHOD: void suspend(java.lang.String,boolean,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $suspend = JPL::AutoLoader::getmeth('suspend',['java.lang.String','boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$suspend($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTypeName {
	## METHOD: java.lang.String getTypeName()
    my $self = shift;
    my $getTypeName = JPL::AutoLoader::getmeth('getTypeName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTypeName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isPublic {
	## METHOD: boolean isPublic()
    my $self = shift;
    my $isPublic = JPL::AutoLoader::getmeth('isPublic',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isPublic(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPath {
	## METHOD: java.lang.String getPath(int)
    my ($self,$p0) = @_;
    my $getPath = JPL::AutoLoader::getmeth('getPath',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPath($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub mark {
	## METHOD: void mark(java.lang.String)
    my ($self,$p0) = @_;
    my $mark = JPL::AutoLoader::getmeth('mark',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$mark($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFile {
	## METHOD: java.lang.String getFile(java.lang.String)
    my ($self,$p0) = @_;
    my $getFile = JPL::AutoLoader::getmeth('getFile',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isHidden {
	## METHOD: boolean isHidden()
    my $self = shift;
    my $isHidden = JPL::AutoLoader::getmeth('isHidden',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isHidden(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContent {
	## METHOD: java.io.ByteArrayInputStream getContent()
    my $self = shift;
    my $getContent = JPL::AutoLoader::getmeth('getContent',[],['java.io.ByteArrayInputStream']);
    my $rv = "";
    eval { $rv = $$self->$getContent(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContentType {
	## METHOD: java.lang.String getContentType()
    my $self = shift;
    my $getContentType = JPL::AutoLoader::getmeth('getContentType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getContentType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setContentType {
	## METHOD: void setContentType(java.lang.String)
    my ($self,$p0) = @_;
    my $setContentType = JPL::AutoLoader::getmeth('setContentType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setContentType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub asVirtualDocument {
	## METHOD: com.documentum.fc.client.IDfVirtualDocument asVirtualDocument(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $asVirtualDocument = JPL::AutoLoader::getmeth('asVirtualDocument',['java.lang.String','boolean'],['com.documentum.fc.client.IDfVirtualDocument']);
    my $rv = "";
    eval { $rv = $$self->$asVirtualDocument($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVirtualDocument);
        return \$rv;
    }
}

sub getChronicleId {
	## METHOD: com.documentum.fc.common.IDfId getChronicleId()
    my $self = shift;
    my $getChronicleId = JPL::AutoLoader::getmeth('getChronicleId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getChronicleId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getResolutionLabel {
	## METHOD: java.lang.String getResolutionLabel()
    my $self = shift;
    my $getResolutionLabel = JPL::AutoLoader::getmeth('getResolutionLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getResolutionLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFullText {
	## METHOD: boolean getFullText()
    my $self = shift;
    my $getFullText = JPL::AutoLoader::getmeth('getFullText',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getFullText(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub resolveAlias {
	## METHOD: java.lang.String resolveAlias(java.lang.String)
    my ($self,$p0) = @_;
    my $resolveAlias = JPL::AutoLoader::getmeth('resolveAlias',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$resolveAlias($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFormat {
	## METHOD: com.documentum.fc.client.IDfFormat getFormat()
    my $self = shift;
    my $getFormat = JPL::AutoLoader::getmeth('getFormat',[],['com.documentum.fc.client.IDfFormat']);
    my $rv = "";
    eval { $rv = $$self->$getFormat(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfFormat);
        return \$rv;
    }
}

sub getACL {
	## METHOD: com.documentum.fc.client.IDfACL getACL()
    my $self = shift;
    my $getACL = JPL::AutoLoader::getmeth('getACL',[],['com.documentum.fc.client.IDfACL']);
    my $rv = "";
    eval { $rv = $$self->$getACL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfACL);
        return \$rv;
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

sub assemble {
	## METHOD: com.documentum.fc.client.IDfCollection assemble(com.documentum.fc.common.IDfId,int,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $assemble = JPL::AutoLoader::getmeth('assemble',['com.documentum.fc.common.IDfId','int','java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$assemble($$p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub setGroupName {
	## METHOD: void setGroupName(java.lang.String)
    my ($self,$p0) = @_;
    my $setGroupName = JPL::AutoLoader::getmeth('setGroupName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setGroupName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub checkoutEx {
	## METHOD: com.documentum.fc.common.IDfId checkoutEx(java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $checkoutEx = JPL::AutoLoader::getmeth('checkoutEx',['java.lang.String','java.lang.String','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$checkoutEx($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getLockDate {
	## METHOD: com.documentum.fc.common.IDfTime getLockDate()
    my $self = shift;
    my $getLockDate = JPL::AutoLoader::getmeth('getLockDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getLockDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getContentState {
	## METHOD: int getContentState(int)
    my ($self,$p0) = @_;
    my $getContentState = JPL::AutoLoader::getmeth('getContentState',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getContentState($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermitList {
	## METHOD: java.lang.String getXPermitList()
    my $self = shift;
    my $getXPermitList = JPL::AutoLoader::getmeth('getXPermitList',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getXPermitList(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zsobj_reserved9 {
	## METHOD: void zsobj_reserved9()
    my $self = shift;
    my $zsobj_reserved9 = JPL::AutoLoader::getmeth('zsobj_reserved9',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zsobj_reserved9(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub checkout {
	## METHOD: void checkout()
    my $self = shift;
    my $checkout = JPL::AutoLoader::getmeth('checkout',[],[]);
    my $rv = "";
    eval { $rv = $$self->$checkout(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub registerEvent {
	## METHOD: void registerEvent(java.lang.String,java.lang.String,int,boolean)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $registerEvent = JPL::AutoLoader::getmeth('registerEvent',['java.lang.String','java.lang.String','int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$registerEvent($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub areAttributesModifiable {
	## METHOD: boolean areAttributesModifiable()
    my $self = shift;
    my $areAttributesModifiable = JPL::AutoLoader::getmeth('areAttributesModifiable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$areAttributesModifiable(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStatus {
	## METHOD: java.lang.String getStatus()
    my $self = shift;
    my $getStatus = JPL::AutoLoader::getmeth('getStatus',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getStatus(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setStatus {
	## METHOD: void setStatus(java.lang.String)
    my ($self,$p0) = @_;
    my $setStatus = JPL::AutoLoader::getmeth('setStatus',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setStatus($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zsobj_reserved10 {
	## METHOD: void zsobj_reserved10()
    my $self = shift;
    my $zsobj_reserved10 = JPL::AutoLoader::getmeth('zsobj_reserved10',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zsobj_reserved10(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setHidden {
	## METHOD: void setHidden(boolean)
    my ($self,$p0) = @_;
    my $setHidden = JPL::AutoLoader::getmeth('setHidden',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setHidden($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub demote {
	## METHOD: void demote(java.lang.String,boolean)
    my ($self,$p0,$p1) = @_;
    my $demote = JPL::AutoLoader::getmeth('demote',['java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$demote($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeRenditionEx {
	## METHOD: void removeRenditionEx(java.lang.String,int,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $removeRenditionEx = JPL::AutoLoader::getmeth('removeRenditionEx',['java.lang.String','int','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeRenditionEx($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub prune {
	## METHOD: void prune(boolean)
    my ($self,$p0) = @_;
    my $prune = JPL::AutoLoader::getmeth('prune',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$prune($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAclRefValid {
	## METHOD: boolean getAclRefValid()
    my $self = shift;
    my $getAclRefValid = JPL::AutoLoader::getmeth('getAclRefValid',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getAclRefValid(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getGroupPermit {
	## METHOD: int getGroupPermit()
    my $self = shift;
    my $getGroupPermit = JPL::AutoLoader::getmeth('getGroupPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getGroupPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setGroupPermit {
	## METHOD: void setGroupPermit(int)
    my ($self,$p0) = @_;
    my $setGroupPermit = JPL::AutoLoader::getmeth('setGroupPermit',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setGroupPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getStorageType {
	## METHOD: java.lang.String getStorageType()
    my $self = shift;
    my $getStorageType = JPL::AutoLoader::getmeth('getStorageType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getStorageType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setStorageType {
	## METHOD: void setStorageType(java.lang.String)
    my ($self,$p0) = @_;
    my $setStorageType = JPL::AutoLoader::getmeth('setStorageType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setStorageType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendPart {
	## METHOD: com.documentum.fc.common.IDfId appendPart(com.documentum.fc.common.IDfId,java.lang.String,boolean,boolean,int)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $appendPart = JPL::AutoLoader::getmeth('appendPart',['com.documentum.fc.common.IDfId','java.lang.String','boolean','boolean','int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$appendPart($$p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub canResume {
	## METHOD: boolean canResume()
    my $self = shift;
    my $canResume = JPL::AutoLoader::getmeth('canResume',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canResume(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAliasSet {
	## METHOD: java.lang.String getAliasSet()
    my $self = shift;
    my $getAliasSet = JPL::AutoLoader::getmeth('getAliasSet',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAliasSet(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHasFrozenAssembly {
	## METHOD: boolean getHasFrozenAssembly()
    my $self = shift;
    my $getHasFrozenAssembly = JPL::AutoLoader::getmeth('getHasFrozenAssembly',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getHasFrozenAssembly(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPolicyId {
	## METHOD: com.documentum.fc.common.IDfId getPolicyId()
    my $self = shift;
    my $getPolicyId = JPL::AutoLoader::getmeth('getPolicyId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getPolicyId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getAliasSetId {
	## METHOD: com.documentum.fc.common.IDfId getAliasSetId()
    my $self = shift;
    my $getAliasSetId = JPL::AutoLoader::getmeth('getAliasSetId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAliasSetId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getComponentId {
	## METHOD: com.documentum.fc.common.IDfId getComponentId(int)
    my ($self,$p0) = @_;
    my $getComponentId = JPL::AutoLoader::getmeth('getComponentId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getComponentId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getKeywordsCount {
	## METHOD: int getKeywordsCount()
    my $self = shift;
    my $getKeywordsCount = JPL::AutoLoader::getmeth('getKeywordsCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getKeywordsCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorCount {
	## METHOD: int getAccessorCount()
    my $self = shift;
    my $getAccessorCount = JPL::AutoLoader::getmeth('getAccessorCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContentStateCount {
	## METHOD: int getContentStateCount()
    my $self = shift;
    my $getContentStateCount = JPL::AutoLoader::getmeth('getContentStateCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getContentStateCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertContent {
	## METHOD: void insertContent(java.io.ByteArrayOutputStream,int)
    my ($self,$p0,$p1) = @_;
    my $insertContent = JPL::AutoLoader::getmeth('insertContent',['java.io.ByteArrayOutputStream','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertContent($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setIsVirtualDocument {
	## METHOD: void setIsVirtualDocument(boolean)
    my ($self,$p0) = @_;
    my $setIsVirtualDocument = JPL::AutoLoader::getmeth('setIsVirtualDocument',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setIsVirtualDocument($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zsobj_reserved11 {
	## METHOD: void zsobj_reserved11()
    my $self = shift;
    my $zsobj_reserved11 = JPL::AutoLoader::getmeth('zsobj_reserved11',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zsobj_reserved11(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionPolicy {
	## METHOD: com.documentum.fc.client.IDfVersionPolicy getVersionPolicy()
    my $self = shift;
    my $getVersionPolicy = JPL::AutoLoader::getmeth('getVersionPolicy',[],['com.documentum.fc.client.IDfVersionPolicy']);
    my $rv = "";
    eval { $rv = $$self->$getVersionPolicy(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVersionPolicy);
        return \$rv;
    }
}

sub getFolderId {
	## METHOD: com.documentum.fc.common.IDfId getFolderId(int)
    my ($self,$p0) = @_;
    my $getFolderId = JPL::AutoLoader::getmeth('getFolderId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getFolderId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub attachPolicy {
	## METHOD: void attachPolicy(com.documentum.fc.common.IDfId,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $attachPolicy = JPL::AutoLoader::getmeth('attachPolicy',['com.documentum.fc.common.IDfId','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$attachPolicy($$p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zsobj_reserved8 {
	## METHOD: void zsobj_reserved8()
    my $self = shift;
    my $zsobj_reserved8 = JPL::AutoLoader::getmeth('zsobj_reserved8',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zsobj_reserved8(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelCheckout {
	## METHOD: void cancelCheckout()
    my $self = shift;
    my $cancelCheckout = JPL::AutoLoader::getmeth('cancelCheckout',[],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelCheckout(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub promote {
	## METHOD: void promote(java.lang.String,boolean,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $promote = JPL::AutoLoader::getmeth('promote',['java.lang.String','boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$promote($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub schedulePromote {
	## METHOD: void schedulePromote(java.lang.String,com.documentum.fc.common.IDfTime,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $schedulePromote = JPL::AutoLoader::getmeth('schedulePromote',['java.lang.String','com.documentum.fc.common.IDfTime','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$schedulePromote($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getImplicitVersionLabel {
	## METHOD: java.lang.String getImplicitVersionLabel()
    my $self = shift;
    my $getImplicitVersionLabel = JPL::AutoLoader::getmeth('getImplicitVersionLabel',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getImplicitVersionLabel(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelScheduledPromote {
	## METHOD: void cancelScheduledPromote(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $cancelScheduledPromote = JPL::AutoLoader::getmeth('cancelScheduledPromote',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelScheduledPromote($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canSuspend {
	## METHOD: boolean canSuspend()
    my $self = shift;
    my $canSuspend = JPL::AutoLoader::getmeth('canSuspend',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canSuspend(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAssembledFromId {
	## METHOD: com.documentum.fc.common.IDfId getAssembledFromId()
    my $self = shift;
    my $getAssembledFromId = JPL::AutoLoader::getmeth('getAssembledFromId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAssembledFromId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub isReference {
	## METHOD: boolean isReference()
    my $self = shift;
    my $isReference = JPL::AutoLoader::getmeth('isReference',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isReference(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub refreshReference {
	## METHOD: void refreshReference()
    my $self = shift;
    my $refreshReference = JPL::AutoLoader::getmeth('refreshReference',[],[]);
    my $rv = "";
    eval { $rv = $$self->$refreshReference(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelCheckoutEx {
	## METHOD: void cancelCheckoutEx(boolean,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $cancelCheckoutEx = JPL::AutoLoader::getmeth('cancelCheckoutEx',['boolean','java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelCheckoutEx($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub checkinEx {
	## METHOD: com.documentum.fc.common.IDfId checkinEx(boolean,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $checkinEx = JPL::AutoLoader::getmeth('checkinEx',['boolean','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$checkinEx($p0,$p1,$p2,$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub branch {
	## METHOD: com.documentum.fc.common.IDfId branch(java.lang.String)
    my ($self,$p0) = @_;
    my $branch = JPL::AutoLoader::getmeth('branch',['java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$branch($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getContentEx {
	## METHOD: java.io.ByteArrayInputStream getContentEx(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getContentEx = JPL::AutoLoader::getmeth('getContentEx',['java.lang.String','int'],['java.io.ByteArrayInputStream']);
    my $rv = "";
    eval { $rv = $$self->$getContentEx($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCreationDate {
	## METHOD: com.documentum.fc.common.IDfTime getCreationDate()
    my $self = shift;
    my $getCreationDate = JPL::AutoLoader::getmeth('getCreationDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getCreationDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getRetentionDate {
	## METHOD: com.documentum.fc.common.IDfTime getRetentionDate()
    my $self = shift;
    my $getRetentionDate = JPL::AutoLoader::getmeth('getRetentionDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getRetentionDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub setArchived {
	## METHOD: void setArchived(boolean)
    my ($self,$p0) = @_;
    my $setArchived = JPL::AutoLoader::getmeth('setArchived',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setArchived($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLockMachine {
	## METHOD: java.lang.String getLockMachine()
    my $self = shift;
    my $getLockMachine = JPL::AutoLoader::getmeth('getLockMachine',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLockMachine(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResumeState {
	## METHOD: int getResumeState()
    my $self = shift;
    my $getResumeState = JPL::AutoLoader::getmeth('getResumeState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getResumeState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setContentEx {
	## METHOD: boolean setContentEx(java.io.ByteArrayOutputStream,java.lang.String,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $setContentEx = JPL::AutoLoader::getmeth('setContentEx',['java.io.ByteArrayOutputStream','java.lang.String','int'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$setContentEx($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub revoke {
	## METHOD: void revoke(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $revoke = JPL::AutoLoader::getmeth('revoke',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$revoke($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPermitEx {
	## METHOD: int getPermitEx(java.lang.String)
    my ($self,$p0) = @_;
    my $getPermitEx = JPL::AutoLoader::getmeth('getPermitEx',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPermitEx($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getOwnerName {
	## METHOD: java.lang.String getOwnerName()
    my $self = shift;
    my $getOwnerName = JPL::AutoLoader::getmeth('getOwnerName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getOwnerName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOwnerName {
	## METHOD: void setOwnerName(java.lang.String)
    my ($self,$p0) = @_;
    my $setOwnerName = JPL::AutoLoader::getmeth('setOwnerName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOwnerName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLockOwner {
	## METHOD: java.lang.String getLockOwner()
    my $self = shift;
    my $getLockOwner = JPL::AutoLoader::getmeth('getLockOwner',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLockOwner(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCreatorName {
	## METHOD: java.lang.String getCreatorName()
    my $self = shift;
    my $getCreatorName = JPL::AutoLoader::getmeth('getCreatorName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCreatorName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorName {
	## METHOD: java.lang.String getAccessorName(int)
    my ($self,$p0) = @_;
    my $getAccessorName = JPL::AutoLoader::getmeth('getAccessorName',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub zsobj_reserved12 {
	## METHOD: void zsobj_reserved12()
    my $self = shift;
    my $zsobj_reserved12 = JPL::AutoLoader::getmeth('zsobj_reserved12',[],[]);
    my $rv = "";
    eval { $rv = $$self->$zsobj_reserved12(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorldPermit {
	## METHOD: int getWorldPermit()
    my $self = shift;
    my $getWorldPermit = JPL::AutoLoader::getmeth('getWorldPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getWorldPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setWorldPermit {
	## METHOD: void setWorldPermit(int)
    my ($self,$p0) = @_;
    my $setWorldPermit = JPL::AutoLoader::getmeth('setWorldPermit',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setWorldPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAuthors {
	## METHOD: java.lang.String getAuthors(int)
    my ($self,$p0) = @_;
    my $getAuthors = JPL::AutoLoader::getmeth('getAuthors',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAuthors($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setAuthors {
	## METHOD: void setAuthors(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setAuthors = JPL::AutoLoader::getmeth('setAuthors',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setAuthors($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub saveAsNew {
	## METHOD: com.documentum.fc.common.IDfId saveAsNew(boolean)
    my ($self,$p0) = @_;
    my $saveAsNew = JPL::AutoLoader::getmeth('saveAsNew',['boolean'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$saveAsNew($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setFile {
	## METHOD: void setFile(java.lang.String)
    my ($self,$p0) = @_;
    my $setFile = JPL::AutoLoader::getmeth('setFile',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendFile {
	## METHOD: void appendFile(java.lang.String)
    my ($self,$p0) = @_;
    my $appendFile = JPL::AutoLoader::getmeth('appendFile',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendFile($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub hasPermission {
	## METHOD: boolean hasPermission(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $hasPermission = JPL::AutoLoader::getmeth('hasPermission',['java.lang.String','java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$hasPermission($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabelCount {
	## METHOD: int getVersionLabelCount()
    my $self = shift;
    my $getVersionLabelCount = JPL::AutoLoader::getmeth('getVersionLabelCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabelCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getDirectDescendant {
	## METHOD: java.lang.String getDirectDescendant()
    my $self = shift;
    my $getDirectDescendant = JPL::AutoLoader::getmeth('getDirectDescendant',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDirectDescendant(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeContent {
	## METHOD: void removeContent(int)
    my ($self,$p0) = @_;
    my $removeContent = JPL::AutoLoader::getmeth('removeContent',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeContent($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getKeywords {
	## METHOD: java.lang.String getKeywords(int)
    my ($self,$p0) = @_;
    my $getKeywords = JPL::AutoLoader::getmeth('getKeywords',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getKeywords($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setKeywords {
	## METHOD: void setKeywords(int,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $setKeywords = JPL::AutoLoader::getmeth('setKeywords',['int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setKeywords($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addNote {
	## METHOD: void addNote(com.documentum.fc.common.IDfId,boolean)
    my ($self,$p0,$p1) = @_;
    my $addNote = JPL::AutoLoader::getmeth('addNote',['com.documentum.fc.common.IDfId','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$addNote($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canDemote {
	## METHOD: boolean canDemote()
    my $self = shift;
    my $canDemote = JPL::AutoLoader::getmeth('canDemote',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canDemote(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addReference {
	## METHOD: com.documentum.fc.common.IDfId addReference(com.documentum.fc.common.IDfId,java.lang.String,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $addReference = JPL::AutoLoader::getmeth('addReference',['com.documentum.fc.common.IDfId','java.lang.String','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$addReference($$p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getCurrentState {
	## METHOD: int getCurrentState()
    my $self = shift;
    my $getCurrentState = JPL::AutoLoader::getmeth('getCurrentState',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getCurrentState(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLatestFlag {
	## METHOD: boolean getLatestFlag()
    my $self = shift;
    my $getLatestFlag = JPL::AutoLoader::getmeth('getLatestFlag',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getLatestFlag(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub updatePart {
	## METHOD: void updatePart(com.documentum.fc.common.IDfId,java.lang.String,double,boolean,boolean,int)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5) = @_;
    my $updatePart = JPL::AutoLoader::getmeth('updatePart',['com.documentum.fc.common.IDfId','java.lang.String','double','boolean','boolean','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$updatePart($$p0,$p1,$p2,$p3,$p4,$p5); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCabinetId {
	## METHOD: com.documentum.fc.common.IDfId getCabinetId()
    my $self = shift;
    my $getCabinetId = JPL::AutoLoader::getmeth('getCabinetId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getCabinetId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getModifier {
	## METHOD: java.lang.String getModifier()
    my $self = shift;
    my $getModifier = JPL::AutoLoader::getmeth('getModifier',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getModifier(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHasEvents {
	## METHOD: boolean getHasEvents()
    my $self = shift;
    my $getHasEvents = JPL::AutoLoader::getmeth('getHasEvents',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getHasEvents(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContainId {
	## METHOD: com.documentum.fc.common.IDfId getContainId(int)
    my ($self,$p0) = @_;
    my $getContainId = JPL::AutoLoader::getmeth('getContainId',['int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getContainId($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getOwnerPermit {
	## METHOD: int getOwnerPermit()
    my $self = shift;
    my $getOwnerPermit = JPL::AutoLoader::getmeth('getOwnerPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getOwnerPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setOwnerPermit {
	## METHOD: void setOwnerPermit(int)
    my ($self,$p0) = @_;
    my $setOwnerPermit = JPL::AutoLoader::getmeth('setOwnerPermit',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setOwnerPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isFrozen {
	## METHOD: boolean isFrozen()
    my $self = shift;
    my $isFrozen = JPL::AutoLoader::getmeth('isFrozen',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isFrozen(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPermit {
	## METHOD: int getPermit()
    my $self = shift;
    my $getPermit = JPL::AutoLoader::getmeth('getPermit',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPermit(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorPermit {
	## METHOD: java.lang.String getAccessorPermit(int)
    my ($self,$p0) = @_;
    my $getAccessorPermit = JPL::AutoLoader::getmeth('getAccessorPermit',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermit {
	## METHOD: int getXPermit(java.lang.String)
    my ($self,$p0) = @_;
    my $getXPermit = JPL::AutoLoader::getmeth('getXPermit',['java.lang.String'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getXPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorXPermit {
	## METHOD: int getAccessorXPermit(int)
    my ($self,$p0) = @_;
    my $getAccessorXPermit = JPL::AutoLoader::getmeth('getAccessorXPermit',['int'],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorXPermit($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertPart {
	## METHOD: com.documentum.fc.common.IDfId insertPart(com.documentum.fc.common.IDfId,java.lang.String,com.documentum.fc.common.IDfId,double,boolean,boolean,boolean,int)
    my ($self,$p0,$p1,$p2,$p3,$p4,$p5,$p6,$p7) = @_;
    my $insertPart = JPL::AutoLoader::getmeth('insertPart',['com.documentum.fc.common.IDfId','java.lang.String','com.documentum.fc.common.IDfId','double','boolean','boolean','boolean','int'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$insertPart($$p0,$p1,$$p2,$p3,$p4,$p5,$p6,$p7); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getObjectName {
	## METHOD: java.lang.String getObjectName()
    my $self = shift;
    my $getObjectName = JPL::AutoLoader::getmeth('getObjectName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getObjectName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setObjectName {
	## METHOD: void setObjectName(java.lang.String)
    my ($self,$p0) = @_;
    my $setObjectName = JPL::AutoLoader::getmeth('setObjectName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setObjectName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getACLName {
	## METHOD: java.lang.String getACLName()
    my $self = shift;
    my $getACLName = JPL::AutoLoader::getmeth('getACLName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getACLName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setACLName {
	## METHOD: void setACLName(java.lang.String)
    my ($self,$p0) = @_;
    my $setACLName = JPL::AutoLoader::getmeth('setACLName',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setACLName($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPolicyName {
	## METHOD: java.lang.String getPolicyName()
    my $self = shift;
    my $getPolicyName = JPL::AutoLoader::getmeth('getPolicyName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPolicyName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getResumeStateName {
	## METHOD: java.lang.String getResumeStateName()
    my $self = shift;
    my $getResumeStateName = JPL::AutoLoader::getmeth('getResumeStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getResumeStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub addRendition {
	## METHOD: void addRendition(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $addRendition = JPL::AutoLoader::getmeth('addRendition',['java.lang.String','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$addRendition($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getExceptionStateName {
	## METHOD: java.lang.String getExceptionStateName()
    my $self = shift;
    my $getExceptionStateName = JPL::AutoLoader::getmeth('getExceptionStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getExceptionStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAuthorsCount {
	## METHOD: int getAuthorsCount()
    my $self = shift;
    my $getAuthorsCount = JPL::AutoLoader::getmeth('getAuthorsCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getAuthorsCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getReferenceCount {
	## METHOD: int getReferenceCount()
    my $self = shift;
    my $getReferenceCount = JPL::AutoLoader::getmeth('getReferenceCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getReferenceCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFolderIdCount {
	## METHOD: int getFolderIdCount()
    my $self = shift;
    my $getFolderIdCount = JPL::AutoLoader::getmeth('getFolderIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getFolderIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkCount {
	## METHOD: int getLinkCount()
    my $self = shift;
    my $getLinkCount = JPL::AutoLoader::getmeth('getLinkCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getLinkCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getLinkHighCount {
	## METHOD: int getLinkHighCount()
    my $self = shift;
    my $getLinkHighCount = JPL::AutoLoader::getmeth('getLinkHighCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getLinkHighCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFrozenAssemblyCount {
	## METHOD: int getFrozenAssemblyCount()
    my $self = shift;
    my $getFrozenAssemblyCount = JPL::AutoLoader::getmeth('getFrozenAssemblyCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getFrozenAssemblyCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBranchCount {
	## METHOD: int getBranchCount()
    my $self = shift;
    my $getBranchCount = JPL::AutoLoader::getmeth('getBranchCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getBranchCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getACLDomain {
	## METHOD: java.lang.String getACLDomain()
    my $self = shift;
    my $getACLDomain = JPL::AutoLoader::getmeth('getACLDomain',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getACLDomain(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setACLDomain {
	## METHOD: void setACLDomain(java.lang.String)
    my ($self,$p0) = @_;
    my $setACLDomain = JPL::AutoLoader::getmeth('setACLDomain',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setACLDomain($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContainIdCount {
	## METHOD: int getContainIdCount()
    my $self = shift;
    my $getContainIdCount = JPL::AutoLoader::getmeth('getContainIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getContainIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isCheckedOutBy {
	## METHOD: boolean isCheckedOutBy(java.lang.String)
    my ($self,$p0) = @_;
    my $isCheckedOutBy = JPL::AutoLoader::getmeth('isCheckedOutBy',['java.lang.String'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isCheckedOutBy($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSpecialApp {
	## METHOD: java.lang.String getSpecialApp()
    my $self = shift;
    my $getSpecialApp = JPL::AutoLoader::getmeth('getSpecialApp',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSpecialApp(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSpecialApp {
	## METHOD: void setSpecialApp(java.lang.String)
    my ($self,$p0) = @_;
    my $setSpecialApp = JPL::AutoLoader::getmeth('setSpecialApp',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSpecialApp($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabels {
	## METHOD: com.documentum.fc.client.IDfVersionLabels getVersionLabels()
    my $self = shift;
    my $getVersionLabels = JPL::AutoLoader::getmeth('getVersionLabels',[],['com.documentum.fc.client.IDfVersionLabels']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabels(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfVersionLabels);
        return \$rv;
    }
}

sub getContentSize {
	## METHOD: int getContentSize()
    my $self = shift;
    my $getContentSize = JPL::AutoLoader::getmeth('getContentSize',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getContentSize(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub destroyAllVersions {
	## METHOD: void destroyAllVersions()
    my $self = shift;
    my $destroyAllVersions = JPL::AutoLoader::getmeth('destroyAllVersions',[],[]);
    my $rv = "";
    eval { $rv = $$self->$destroyAllVersions(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRenditions {
	## METHOD: com.documentum.fc.client.IDfCollection getRenditions(java.lang.String)
    my ($self,$p0) = @_;
    my $getRenditions = JPL::AutoLoader::getmeth('getRenditions',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getRenditions($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getLocations {
	## METHOD: com.documentum.fc.client.IDfCollection getLocations(java.lang.String)
    my ($self,$p0) = @_;
    my $getLocations = JPL::AutoLoader::getmeth('getLocations',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getLocations($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub useACL {
	## METHOD: void useACL(java.lang.String)
    my ($self,$p0) = @_;
    my $useACL = JPL::AutoLoader::getmeth('useACL',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$useACL($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isLinkResolved {
	## METHOD: boolean isLinkResolved()
    my $self = shift;
    my $isLinkResolved = JPL::AutoLoader::getmeth('isLinkResolved',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isLinkResolved(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getWorkflows {
	## METHOD: com.documentum.fc.client.IDfCollection getWorkflows(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getWorkflows = JPL::AutoLoader::getmeth('getWorkflows',['java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getWorkflows($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub bindFile {
	## METHOD: void bindFile(int,com.documentum.fc.common.IDfId,int)
    my ($self,$p0,$p1,$p2) = @_;
    my $bindFile = JPL::AutoLoader::getmeth('bindFile',['int','com.documentum.fc.common.IDfId','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$bindFile($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAntecedentId {
	## METHOD: com.documentum.fc.common.IDfId getAntecedentId()
    my $self = shift;
    my $getAntecedentId = JPL::AutoLoader::getmeth('getAntecedentId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getAntecedentId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub scheduleResume {
	## METHOD: void scheduleResume(java.lang.String,com.documentum.fc.common.IDfTime,boolean,boolean)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $scheduleResume = JPL::AutoLoader::getmeth('scheduleResume',['java.lang.String','com.documentum.fc.common.IDfTime','boolean','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$scheduleResume($p0,$$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelScheduledResume {
	## METHOD: void cancelScheduledResume(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $cancelScheduledResume = JPL::AutoLoader::getmeth('cancelScheduledResume',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelScheduledResume($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCurrentStateName {
	## METHOD: java.lang.String getCurrentStateName()
    my $self = shift;
    my $getCurrentStateName = JPL::AutoLoader::getmeth('getCurrentStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCurrentStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPreviousStateName {
	## METHOD: java.lang.String getPreviousStateName()
    my $self = shift;
    my $getPreviousStateName = JPL::AutoLoader::getmeth('getPreviousStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getPreviousStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getNextStateName {
	## METHOD: java.lang.String getNextStateName()
    my $self = shift;
    my $getNextStateName = JPL::AutoLoader::getmeth('getNextStateName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getNextStateName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub scheduleSuspend {
	## METHOD: void scheduleSuspend(java.lang.String,com.documentum.fc.common.IDfTime,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $scheduleSuspend = JPL::AutoLoader::getmeth('scheduleSuspend',['java.lang.String','com.documentum.fc.common.IDfTime','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$scheduleSuspend($p0,$$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelScheduledSuspend {
	## METHOD: void cancelScheduledSuspend(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $cancelScheduledSuspend = JPL::AutoLoader::getmeth('cancelScheduledSuspend',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelScheduledSuspend($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setResolutionLabel {
	## METHOD: void setResolutionLabel(java.lang.String)
    my ($self,$p0) = @_;
    my $setResolutionLabel = JPL::AutoLoader::getmeth('setResolutionLabel',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setResolutionLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersionLabel {
	## METHOD: java.lang.String getVersionLabel(int)
    my ($self,$p0) = @_;
    my $getVersionLabel = JPL::AutoLoader::getmeth('getVersionLabel',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getVersionLabel($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setSubject {
	## METHOD: void setSubject(java.lang.String)
    my ($self,$p0) = @_;
    my $setSubject = JPL::AutoLoader::getmeth('setSubject',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setSubject($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getSubject {
	## METHOD: java.lang.String getSubject()
    my $self = shift;
    my $getSubject = JPL::AutoLoader::getmeth('getSubject',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getSubject(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getMasterDocbase {
	## METHOD: java.lang.String getMasterDocbase()
    my $self = shift;
    my $getMasterDocbase = JPL::AutoLoader::getmeth('getMasterDocbase',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getMasterDocbase(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub unfreeze {
	## METHOD: void unfreeze(boolean)
    my ($self,$p0) = @_;
    my $unfreeze = JPL::AutoLoader::getmeth('unfreeze',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$unfreeze($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCollectionForContent {
	## METHOD: com.documentum.fc.client.IDfCollection getCollectionForContent(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $getCollectionForContent = JPL::AutoLoader::getmeth('getCollectionForContent',['java.lang.String','int'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getCollectionForContent($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub setContent {
	## METHOD: boolean setContent(java.io.ByteArrayOutputStream)
    my ($self,$p0) = @_;
    my $setContent = JPL::AutoLoader::getmeth('setContent',['java.io.ByteArrayOutputStream'],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$setContent($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub appendContent {
	## METHOD: void appendContent(java.io.ByteArrayOutputStream)
    my ($self,$p0) = @_;
    my $appendContent = JPL::AutoLoader::getmeth('appendContent',['java.io.ByteArrayOutputStream'],[]);
    my $rv = "";
    eval { $rv = $$self->$appendContent($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub grant {
	## METHOD: void grant(java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2) = @_;
    my $grant = JPL::AutoLoader::getmeth('grant',['java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$grant($p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getVersions {
	## METHOD: com.documentum.fc.client.IDfCollection getVersions(java.lang.String)
    my ($self,$p0) = @_;
    my $getVersions = JPL::AutoLoader::getmeth('getVersions',['java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getVersions($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub addRenditionEx {
	## METHOD: void addRenditionEx(java.lang.String,java.lang.String,int,java.lang.String,boolean)
    my ($self,$p0,$p1,$p2,$p3,$p4) = @_;
    my $addRenditionEx = JPL::AutoLoader::getmeth('addRenditionEx',['java.lang.String','java.lang.String','int','java.lang.String','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$addRenditionEx($p0,$p1,$p2,$p3,$p4); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub revertACL {
	## METHOD: void revertACL()
    my $self = shift;
    my $revertACL = JPL::AutoLoader::getmeth('revertACL',[],[]);
    my $rv = "";
    eval { $rv = $$self->$revertACL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setPath {
	## METHOD: void setPath(java.lang.String,java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $setPath = JPL::AutoLoader::getmeth('setPath',['java.lang.String','java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setPath($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getTitle {
	## METHOD: java.lang.String getTitle()
    my $self = shift;
    my $getTitle = JPL::AutoLoader::getmeth('getTitle',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getTitle(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setTitle {
	## METHOD: void setTitle(java.lang.String)
    my ($self,$p0) = @_;
    my $setTitle = JPL::AutoLoader::getmeth('setTitle',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setTitle($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub insertFile {
	## METHOD: void insertFile(java.lang.String,int)
    my ($self,$p0,$p1) = @_;
    my $insertFile = JPL::AutoLoader::getmeth('insertFile',['java.lang.String','int'],[]);
    my $rv = "";
    eval { $rv = $$self->$insertFile($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removePart {
	## METHOD: void removePart(com.documentum.fc.common.IDfId,double,boolean)
    my ($self,$p0,$p1,$p2) = @_;
    my $removePart = JPL::AutoLoader::getmeth('removePart',['com.documentum.fc.common.IDfId','double','boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$removePart($$p0,$p1,$p2); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getApplicationType {
	## METHOD: java.lang.String getApplicationType()
    my $self = shift;
    my $getApplicationType = JPL::AutoLoader::getmeth('getApplicationType',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getApplicationType(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setApplicationType {
	## METHOD: void setApplicationType(java.lang.String)
    my ($self,$p0) = @_;
    my $setApplicationType = JPL::AutoLoader::getmeth('setApplicationType',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setApplicationType($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRemoteId {
	## METHOD: com.documentum.fc.common.IDfId getRemoteId()
    my $self = shift;
    my $getRemoteId = JPL::AutoLoader::getmeth('getRemoteId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getRemoteId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub getLogEntry {
	## METHOD: java.lang.String getLogEntry()
    my $self = shift;
    my $getLogEntry = JPL::AutoLoader::getmeth('getLogEntry',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getLogEntry(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setLogEntry {
	## METHOD: void setLogEntry(java.lang.String)
    my ($self,$p0) = @_;
    my $setLogEntry = JPL::AutoLoader::getmeth('setLogEntry',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setLogEntry($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isImmutable {
	## METHOD: boolean isImmutable()
    my $self = shift;
    my $isImmutable = JPL::AutoLoader::getmeth('isImmutable',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isImmutable(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getHasFolder {
	## METHOD: boolean getHasFolder()
    my $self = shift;
    my $getHasFolder = JPL::AutoLoader::getmeth('getHasFolder',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$getHasFolder(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub unmark {
	## METHOD: void unmark(java.lang.String)
    my ($self,$p0) = @_;
    my $unmark = JPL::AutoLoader::getmeth('unmark',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$unmark($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeRendition {
	## METHOD: void removeRendition(java.lang.String)
    my ($self,$p0) = @_;
    my $removeRendition = JPL::AutoLoader::getmeth('removeRendition',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeRendition($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub saveLock {
	## METHOD: void saveLock()
    my $self = shift;
    my $saveLock = JPL::AutoLoader::getmeth('saveLock',[],[]);
    my $rv = "";
    eval { $rv = $$self->$saveLock(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getPageCount {
	## METHOD: int getPageCount()
    my $self = shift;
    my $getPageCount = JPL::AutoLoader::getmeth('getPageCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getPageCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getComponentIdCount {
	## METHOD: int getComponentIdCount()
    my $self = shift;
    my $getComponentIdCount = JPL::AutoLoader::getmeth('getComponentIdCount',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getComponentIdCount(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub checkin {
	## METHOD: com.documentum.fc.common.IDfId checkin(boolean,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $checkin = JPL::AutoLoader::getmeth('checkin',['boolean','java.lang.String'],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$checkin($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub mount {
	## METHOD: void mount(java.lang.String)
    my ($self,$p0) = @_;
    my $mount = JPL::AutoLoader::getmeth('mount',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$mount($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub removeNote {
	## METHOD: void removeNote(com.documentum.fc.common.IDfId)
    my ($self,$p0) = @_;
    my $removeNote = JPL::AutoLoader::getmeth('removeNote',['com.documentum.fc.common.IDfId'],[]);
    my $rv = "";
    eval { $rv = $$self->$removeNote($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub canPromote {
	## METHOD: boolean canPromote()
    my $self = shift;
    my $canPromote = JPL::AutoLoader::getmeth('canPromote',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$canPromote(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub scheduleDemote {
	## METHOD: void scheduleDemote(java.lang.String,com.documentum.fc.common.IDfTime)
    my ($self,$p0,$p1) = @_;
    my $scheduleDemote = JPL::AutoLoader::getmeth('scheduleDemote',['java.lang.String','com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$scheduleDemote($p0,$$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub cancelScheduledDemote {
	## METHOD: void cancelScheduledDemote(com.documentum.fc.common.IDfTime)
    my ($self,$p0) = @_;
    my $cancelScheduledDemote = JPL::AutoLoader::getmeth('cancelScheduledDemote',['com.documentum.fc.common.IDfTime'],[]);
    my $rv = "";
    eval { $rv = $$self->$cancelScheduledDemote($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getCompoundArchitecture {
	## METHOD: java.lang.String getCompoundArchitecture()
    my $self = shift;
    my $getCompoundArchitecture = JPL::AutoLoader::getmeth('getCompoundArchitecture',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getCompoundArchitecture(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setCompoundArchitecture {
	## METHOD: void setCompoundArchitecture(java.lang.String)
    my ($self,$p0) = @_;
    my $setCompoundArchitecture = JPL::AutoLoader::getmeth('setCompoundArchitecture',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setCompoundArchitecture($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub detachPolicy {
	## METHOD: void detachPolicy()
    my $self = shift;
    my $detachPolicy = JPL::AutoLoader::getmeth('detachPolicy',[],[]);
    my $rv = "";
    eval { $rv = $$self->$detachPolicy(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub freeze {
	## METHOD: void freeze(boolean)
    my ($self,$p0) = @_;
    my $freeze = JPL::AutoLoader::getmeth('freeze',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$freeze($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isCheckedOut {
	## METHOD: boolean isCheckedOut()
    my $self = shift;
    my $isCheckedOut = JPL::AutoLoader::getmeth('isCheckedOut',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isCheckedOut(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub isSuspended {
	## METHOD: boolean isSuspended()
    my $self = shift;
    my $isSuspended = JPL::AutoLoader::getmeth('isSuspended',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isSuspended(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub unlink {
	## METHOD: void unlink(java.lang.String)
    my ($self,$p0) = @_;
    my $unlink = JPL::AutoLoader::getmeth('unlink',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$unlink($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setFullText {
	## METHOD: void setFullText(boolean)
    my ($self,$p0) = @_;
    my $setFullText = JPL::AutoLoader::getmeth('setFullText',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFullText($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getFileEx {
	## METHOD: java.lang.String getFileEx(java.lang.String,java.lang.String,int,boolean)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $getFileEx = JPL::AutoLoader::getmeth('getFileEx',['java.lang.String','java.lang.String','int','boolean'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getFileEx($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getAccessorXPermitNames {
	## METHOD: java.lang.String getAccessorXPermitNames(int)
    my ($self,$p0) = @_;
    my $getAccessorXPermitNames = JPL::AutoLoader::getmeth('getAccessorXPermitNames',['int'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getAccessorXPermitNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getXPermitNames {
	## METHOD: java.lang.String getXPermitNames(java.lang.String)
    my ($self,$p0) = @_;
    my $getXPermitNames = JPL::AutoLoader::getmeth('getXPermitNames',['java.lang.String'],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getXPermitNames($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getContentsId {
	## METHOD: com.documentum.fc.common.IDfId getContentsId()
    my $self = shift;
    my $getContentsId = JPL::AutoLoader::getmeth('getContentsId',[],['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $$self->$getContentsId(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfId);
        return \$rv;
    }
}

sub setFileEx {
	## METHOD: void setFileEx(java.lang.String,java.lang.String,int,java.lang.String)
    my ($self,$p0,$p1,$p2,$p3) = @_;
    my $setFileEx = JPL::AutoLoader::getmeth('setFileEx',['java.lang.String','java.lang.String','int','java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setFileEx($p0,$p1,$p2,$p3); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getModifyDate {
	## METHOD: com.documentum.fc.common.IDfTime getModifyDate()
    my $self = shift;
    my $getModifyDate = JPL::AutoLoader::getmeth('getModifyDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getModifyDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub getAccessDate {
	## METHOD: com.documentum.fc.common.IDfTime getAccessDate()
    my $self = shift;
    my $getAccessDate = JPL::AutoLoader::getmeth('getAccessDate',[],['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $$self->$getAccessDate(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfTime);
        return \$rv;
    }
}

sub isArchived {
	## METHOD: boolean isArchived()
    my $self = shift;
    my $isArchived = JPL::AutoLoader::getmeth('isArchived',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isArchived(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setLinkResolved {
	## METHOD: void setLinkResolved(boolean)
    my ($self,$p0) = @_;
    my $setLinkResolved = JPL::AutoLoader::getmeth('setLinkResolved',['boolean'],[]);
    my $rv = "";
    eval { $rv = $$self->$setLinkResolved($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setACL {
	## METHOD: void setACL(com.documentum.fc.client.IDfACL)
    my ($self,$p0) = @_;
    my $setACL = JPL::AutoLoader::getmeth('setACL',['com.documentum.fc.client.IDfACL'],[]);
    my $rv = "";
    eval { $rv = $$self->$setACL($$p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub link {
	## METHOD: void link(java.lang.String)
    my ($self,$p0) = @_;
    my $link = JPL::AutoLoader::getmeth('link',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$link($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getRouters {
	## METHOD: com.documentum.fc.client.IDfCollection getRouters(java.lang.String,java.lang.String)
    my ($self,$p0,$p1) = @_;
    my $getRouters = JPL::AutoLoader::getmeth('getRouters',['java.lang.String','java.lang.String'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$getRouters($p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getGroupName {
	## METHOD: java.lang.String getGroupName()
    my $self = shift;
    my $getGroupName = JPL::AutoLoader::getmeth('getGroupName',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getGroupName(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub unRegisterEvent {
	## METHOD: void unRegisterEvent(java.lang.String)
    my ($self,$p0) = @_;
    my $unRegisterEvent = JPL::AutoLoader::getmeth('unRegisterEvent',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$unRegisterEvent($p0); };
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
