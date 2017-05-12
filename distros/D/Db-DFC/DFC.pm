# ------------------------------------------------------------------ #
# Db::DFC Version 0.4
# (C) 2000-2001 M.S. Roth
#
# Perl's Object-oriented interface to Documentum's DFC
#
# Based on DFC Java classes v4.1.2.79
# ------------------------------------------------------------------- #
package Db::DFC;

$VERSION = '0.4';

use JNI;

use Db::DFC::DfClient;
use Db::DFC::DfException;
use Db::DFC::DfId;
use Db::DFC::DfList;
use Db::DFC::DfLoginInfo;
use Db::DFC::DfProperties;
use Db::DFC::DfQuery;
use Db::DFC::DfTime;
use Db::DFC::DfTrace;
use Db::DFC::DfUtil;
use Db::DFC::DfValueContext;

use Db::DFC::IDfACL;
use Db::DFC::IDfActivity;
use Db::DFC::IDfAliasSet;
use Db::DFC::IDfAssembly;
use Db::DFC::IDfAttr;
use Db::DFC::IDfAttrLine;
use Db::DFC::IDfCancelCheckoutNode;
use Db::DFC::IDfCancelCheckoutOperation;
use Db::DFC::IDfChangeDescription;
use Db::DFC::IDfCheckinNode;
use Db::DFC::IDfCheckinOperation;
use Db::DFC::IDfCheckoutNode;
use Db::DFC::IDfCheckoutOperation;
use Db::DFC::IDfClient;
use Db::DFC::IDfCollection;
use Db::DFC::IDfContainment;
use Db::DFC::IDfCopyNode;
use Db::DFC::IDfCopyOperation;
use Db::DFC::IDfDDInfo;
use Db::DFC::IDfDeleteNode;
use Db::DFC::IDfDeleteOperation;
use Db::DFC::IDfDocbaseMap;
use Db::DFC::IDfDocument;
use Db::DFC::IDfEnumeration;
use Db::DFC::IDfException;
use Db::DFC::IDfExportNode;
use Db::DFC::IDfExportOperation;
use Db::DFC::IDfFile;
use Db::DFC::IDfFolder;
use Db::DFC::IDfFormat;
use Db::DFC::IDfFormatRecognizer;
use Db::DFC::IDfGroup;
use Db::DFC::IDfId;
use Db::DFC::IDfImportNode;
use Db::DFC::IDfImportOperation;
use Db::DFC::IDfList;
use Db::DFC::IDfLoginInfo;
use Db::DFC::IDfMoveNode;
use Db::DFC::IDfMoveOperation;
use Db::DFC::IDfOperation;
use Db::DFC::IDfOperationError;
use Db::DFC::IDfOperationMonitor;
use Db::DFC::IDfOperationNode;
use Db::DFC::IDfOperationPopulator;
use Db::DFC::IDfOperationStep;
use Db::DFC::IDfPackage;
use Db::DFC::IDfPersistentObject;
use Db::DFC::IDfProcess;
use Db::DFC::IDfProperties;
use Db::DFC::IDfQuery;
use Db::DFC::IDfQueryFullText;
use Db::DFC::IDfQueryLocation;
use Db::DFC::IDfQueryMgr;
use Db::DFC::IDfQueryResultEvent;
use Db::DFC::IDfQueryResultItem;
use Db::DFC::IDfQueryResultListener;
use Db::DFC::IDfQueueItem;
use Db::DFC::IDfRelation;
use Db::DFC::IDfRelationType;
use Db::DFC::IDfRouter;
use Db::DFC::IDfSearchable;
use Db::DFC::IDfSession;
use Db::DFC::IDfSysObject;
use Db::DFC::IDfTime;
use Db::DFC::IDfType;
use Db::DFC::IDfTypedObject;
use Db::DFC::IDfUser;
use Db::DFC::IDfValidator;
use Db::DFC::IDfValue;
use Db::DFC::IDfValueAssistance;
use Db::DFC::IDfVDMNumberingScheme;
use Db::DFC::IDfVDMPlatformUtils;
use Db::DFC::IDfVersionLabels;
use Db::DFC::IDfVersionPolicy;
use Db::DFC::IDfVersionTreeLabels;
use Db::DFC::IDfVirtualDocument;
use Db::DFC::IDfVirtualDocumentNode;
use Db::DFC::IDfWorkflow;
use Db::DFC::IDfWorkflowBuilder;
use Db::DFC::IDfWorkitem;



######################################################################

use JPL::Class 'dm_JCast';
$dm_JCast = dm_JCast->new();


sub new {
    my $self = {};
    bless ($self,Db::DFC);
    return $self;
}

sub version {
    return $Db::DFC::VERSION;
}

sub dfcException {
    print "\n\nDb::DFC caught a Java Exception:";
    print "\n" . "-"x72 . "\n";
    print JNI::ExceptionDescribe();
    print "-"x72 . "\n";
    JNI::ExceptionClear();
    die;
}

sub castToIDfDocument {
    my ($self,$obj) = @_;
    my $castToIDfDocument = JPL::AutoLoader::getmeth('castToIDfDocument',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.client.IDfDocument']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfDocument($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfDocument);
		return \$rv;
	}
}

sub castToIDfException {
    my ($self,$obj) = @_;
    my $castToIDfException = JPL::AutoLoader::getmeth('castToIDfException',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.common.IDfException']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfException($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfException);
		return \$rv;
	}
}

sub castToIDfId {
    my ($self,$obj) = @_;
    my $castToIDfId = JPL::AutoLoader::getmeth('castToIDfId',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.common.IDfId']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfId($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfId);
		return \$rv;
	}
}

sub castToIDfList {
    my ($self,$obj) = @_;
    my $castToIDfId = JPL::AutoLoader::getmeth('castToIDfList',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.common.IDfList']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfList($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfList);
		return \$rv;
	}
}

sub castToIDfSysObject {
    my ($self,$obj) = @_;
    my $castToIDfSysObject = JPL::AutoLoader::getmeth('castToIDfSysObject',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.client.IDfSysObject']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfSysObject($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfSysObject);
		return \$rv;
	}
}

sub castToIDfFolder {
    my ($self,$obj) = @_;
    my $castToIDfFolder = JPL::AutoLoader::getmeth('castToIDfFolder',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.client.IDfFolder']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfFolder($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfFolder);
		return \$rv;
	}
}

sub castToIDfOperation {
    my ($self,$obj) = @_;
    my $castToIDfOperation = JPL::AutoLoader::getmeth('castToIDfOperation',
                                              ['java.lang.Object'],
                                              ['com.documentum.operations.IDfOperation']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfOperation($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfOperation);
		return \$rv;
	}
}

sub castToIDfOperationNode {
    my ($self,$obj) = @_;
    my $castToIDfOperationNode = JPL::AutoLoader::getmeth('castToIDfOperationNode',
                                              ['java.lang.Object'],
                                              ['com.documentum.operations.IDfOperationNode']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfOperationNode($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfOperationNode);
		return \$rv;
	}
}

sub castToIDfPersistentObject {
    my ($self,$obj) = @_;
    my $castToIDfPersistentObject = JPL::AutoLoader::getmeth('castToIDfPersistentObject',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.client.IDfPersistentObject']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfPersistentObject($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfPersistentObject);
		return \$rv;
	}
}

sub castToIDfTime {
    my ($self,$obj) = @_;
    my $castToIDfTime = JPL::AutoLoader::getmeth('castToIDfTime',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.common.IDfTime']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfTime($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfTime);
		return \$rv;
	}
}

sub castToIDfTypedObject {
    my ($self,$obj) = @_;
    my $castToIDfTypedObject = JPL::AutoLoader::getmeth('castToIDfTypedObject',
                                              ['java.lang.Object'],
                                              ['com.documentum.fc.client.IDfTypedObject']);
    my $rv = "";
    eval { $rv = $dm_JCast->$castToIDfTypedObject($$obj); } ;
	if (JNI::ExceptionOccurred()) {
		dfcException();
		return;
	} else {
		bless(\$rv,IDfTypedObject);
		return \$rv;
	}
}

__END__

=head1 NAME

Db::DFC - Perl's Object-oriented interface to Documentum's DFC

=head1 SYNOPSIS

    use Db::DFC;
    $dfc = Db::DFC->new();

    $DOCBASE = "docbase";
    $USER = "user";
    $PASSWORD = "passwd";
    $DOMAIN = "domain";
    $FILE = $0;

    $dfclient = DfClient->new();
    $idfclient = $dfclient->getLocalClient();
    $idflogininfo = DfLoginInfo->new();

    $idflogininfo->setUser($USER);
    $idflogininfo->setPassword($PASSWORD);
    $idflogininfo->setDomain($DOMAIN);

    $idfsession = $idfclient->newSession($DOCBASE,$idflogininfo);

    $pobj = $idfsession->newObject("dm_document");
    $doc = $dfc->castToIDfDocument($pobj);

    $doc->setObjectName("this file");
    $doc->setContentType("crtext");
    $doc->setFile($FILE);
    $doc->save();

    print "\nDocument Id:" . $doc->getObjectId()->toString() . " created.\n";
    $idfsession->disconnect;

=head1 DESCRIPTION

    Db::DFC provides an object-oriented interface to Documentum's DFC.
    ...

=head1 AUTHOR

    m. Scott Roth, michael.s.roth@saic.com

=head1 SEE ALSO

perl(1).

=cut


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #