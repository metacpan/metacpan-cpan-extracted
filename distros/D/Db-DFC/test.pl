#!/usr/local/bin/perl

use Db::DFC;

#$JPL::DEBUG=1;
$|=1;

$DOCBASE = "";
$DOMAIN = "";
$USER = "";
$PASSWORD = "";

if ($DOCBASE !~ /.+/) {
    print "\n\n\n\nPlease edit the test.pl file to include logon info before running 'nmake test'.\n\n";
    exit;
}    

$COUNTER  = 0;
$SUCCESSES = 0;
$FAILURES = 0;


$dfc = Db::DFC->new();
print "\n\nusing Db::DFC v" . $dfc->version() . "\n\n";


print "\nInstantiate Classes...\n";
$dfclient = testIt(DfClient->new(),"DfClient->new()");
$idflogininfo = testIt(DfLoginInfo->new(),"DfLoginInfo->new()");
$idfquery = testIt(DfQuery->new(),"DfQuery->new()");
$idfid = testIt(DfId->new(DF_NULLID_STR),"DfId->new()");
$idfprop = testIt(DfProperties->new(),"DfProperties->new()");
$idftime = testIt(DfTime->new(),"DfTime->new()");
$idflist = testIt(DfList->new(),"IDfList->new()");
$idfe = testIt(DfException->new(),"DfException->new()");


## ===== DfClient ===== ##
print "\n\nTesting DfClient...\n";
testIt($dfclient->getDFCVersion(),"DfClient->getDFCVersion()");
$idfclient = testIt($dfclient->getLocalClient(),"DfClient->getLocalClient()");
$idfclient32 = testIt($dfclient->getLocalClient32(),"DfClient->getLocalClient32()");


## ===== IDfLoginInfo ===== ##
print "\n\nTesting IDfLoginInfo...\n";
testIt($idflogininfo->setUser($USER),"IDfLoginInfo->setUser()");
testIt($idflogininfo->getUser(),"IDfLoginInfo->getUser()");
testIt($idflogininfo->setPassword($PASSWORD),"IDfLoginInfo->setPassword()");
testIt($idflogininfo->getPassword(),"IDfLloginInfo->getPassword()");
testIt($idflogininfo->setDomain($DOMAIN),"IDfLoginInfo->setDomain()");
testIt($idflogininfo->getDomain(),"IDfLoginInfo->getDomain()");
$idflogin2 = testIt(DfLoginInfo->new($idflogininfo),"DfLoginInfo->new(IDfLoginInfo)");


## ===== IDfClient ===== ##
print "\n\nTesting IDfClient...\n";
testIt($idfclient->getClientConfig(),"IDfClient->getClientConfig()");
testIt($idfclient->getDocbaseMap(),"IDfClient->getDocbaseMap()");
testIt($idfclient->getServerMap($DOCBASE),"IDfClient->getServerMap()");
$idfsession = testIt($idfclient->newSession($DOCBASE,$idflogininfo),"IDfClient->newSession()");


## ===== IDfSession ===== ##
print "\n\nTesting IDfSession...\n";
testIt($idfsession->getDBMSName(),"IDfSession->getDBMSName()");
testIt($idfsession->describe("TYPE","dm_document"),"IDfSession->describe()");
testIt($idfsession->getConnectionConfig(),"IDfSession->getConnectionConfig()");
testIt($idfsession->getDefaultACL(),"IDfSession->getDefaultACL()");
testIt($idfsession->getDMCLSessionId(),"IDfSession->getDMCLSessionId()");
testIt($idfsession->getDocbaseId(),"IDfSession->getDocbaseId()");
testIt($idfsession->getDocbaseName(),"IDfSession->getDocbaseName()");
testIt($idfsession->getDocbaseOwnerName(),"IDfSession->getDocbaseOwnerName()");
testIt($idfsession->getFormat("crtext"),"IDfSession->getFormat()");
testIt($idfsession->getGroup("docu"),"IDfSession->getGroup()");
testIt($idfsession->getLoginTicket(),"IDfSession->getLoginTicket()");
testIt($idfsession->getServerVersion(),"IDfSession->getServerVersion()");
testIt($idfsession->getSessionId(),"IDfSession->getSessionId()");
testIt($idfsession->getDocbaseScope(),"IDfSession->getDocbaseScope()");
testIt($idfsession->getLoginUserName(),"IDfSession->getLoginUserName()");
testIt($idfsession->getSecurityMode(),"IDfSession->getSecurityMode()");
$idfperobj = testIt($idfsession->newObject("dm_document"),"IDfSession->newObject()");


## ===== IDfDocument ===== ##
print "\n\nTesting IDfDocument...\n";
$idfdoc = $dfc->castToIDfDocument($idfperobj);
testIt($idfdoc->setObjectName("Db-DFC Test Object"),"IDfDocument->setObjectName()");
testIt($idfdoc->getObjectName(),"IDfDocument->getObjectName()");
testIt($idfdoc->save(),"IDfDocument->save()");


## ===== IDfQuery ===== ##
print "\n\nTesting IDfQuery...\n";
testIt($idfquery->setDQL("select object_name from dm_sysobject where owner_name = user"),
                         "IDfQuery->setDQL()");
testIt($idfquery->getDQL(),"IDfQuery->getDQL()");
$idfcol = testIt($idfquery->execute($idfsession,0),"IDfQuery->execute()");


## ===== IDfProperties ===== ##
print "\n\nTesting IDfProperties...\n";
testIt($idfprop->getCount(),"IDfProperties->getCount()");


## ===== IDfTime ===== ##
print "\n\nTesting IDfTime...\n";
testIt($idftime->toString(),"IDfTime->toString()");


## ===== IDfList ===== ##
print "\n\nTesting IDfList...\n";
$idflist = testIt(DfList->new([1,2,3]),"IDfList->new()");
$idflist = testIt(DfList->new(['a','b','c',"abc"]),"IDfList->new()");


## ===== IDfException ===== ##
print "\n\nTesting IDfException...\n";

print "\n\n$COUNTER Tests:  $SUCCESSES Successes, $FAILURES Failures.\n\n";

$idfsession->disconnect();
exit;


sub testIt {
    my ($rv,$desc) = @_;
    $COUNTER++;

    print "\n$COUNTER ";

    if ((! ref($rv)) && ($rv !~ /.+/)) {
        print "NOT ";
        $FAILURES++;
    } else {
        print "    ";
        $SUCCESSES++;
    }

    print "OK :";
    print " $desc";

    if (ref($rv) =~ /^java/) {
        $rv =~ s/\n/ /g;
        if (length($rv) > 30) {
            $rv = substr($rv,0,30);
            $rv .= "...";
        }
        print " = \'$rv\'";
    }

    return $rv;
}

