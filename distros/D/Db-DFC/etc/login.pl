#!/usr/local/bin/perl
# login.pl

use Db::DFC;
use Cwd;

$DOCBASE = "";
$USER = "";
$PASSWORD = "";
$DOMAIN = "";
$FILE = cwd() . "/" . $0;

$dfclient = DfClient->new();
$idfclient = $dfclient->getLocalClient();
$idflogininfo = DfLoginInfo->new();

$idflogininfo->setUser($USER);
$idflogininfo->setPassword($PASSWORD);
$idflogininfo->setDomain($DOMAIN);

$idfsession = $idfclient->newSession($DOCBASE,$idflogininfo);

$pobj = $idfsession->newObject("dm_document");
$doc = Db::DFC::castToIDfDocument($pobj);

$doc->setObjectName("doc1");
$doc->setContentType("crtext");
$doc->setFile($FILE);
$doc->save();

print "\nDocument Id:" . $doc->getObjectId()->toString() . " created.\n";
$idfsession->disconnect;
exit;

