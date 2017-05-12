# $Id: test.pl,v 1.3 2004/04/22 15:41:21 cvonroes Exp $
use HTTP::QuickBase;

my $qdb = HTTP::QuickBase->new();
$username="depositor";
$password="Password";

$qdb->authenticate("$username","$password");

$dbName="QuickBase KnowledgeBase and Support Center";

$dbid = $qdb->getIDbyName($dbName);

if ($dbid eq "9kaw8phg")
   {
   print "Congratulations QuickBase.pm has been successfully installed!\n";
   exit(0);
   }
else
	{
	die("QuickBase.pm is not properly installed. 
		Often this results because SSL support (Crypt:SSLeay) has not been installed for LWP. " . $qdb->errortext);
	}

