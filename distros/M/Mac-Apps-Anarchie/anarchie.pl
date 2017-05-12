#!perl
#Anarchie.pm tests

#set your variables
$host	= 'host.com';
$user	= 'anonymous';
$pass	= 'user@host.com';

$file	= 'pub/test.txt';
$dsktp	= 'PowerPudge:Desktop Folder:';
#depending on the tests you run, you might have to create
#these files/folders beforehand
$file2	= $dsktp.'newfile.txt';
$file3	= $dsktp.'newfile3.txt';
$file4	= $dsktp.'newfile:';
$url	= "ftp://$user:$pass\@$host/$file";

use Mac::Apps::Anarchie;
$ftp = new Mac::Apps::Anarchie;
#un-comment to use Fetch instead of Archie
#$ftp->useagent('FTCh');
$ftp->switchapp(1,'R*ch');

#these are required for non-URL methods if they are not explcitly included in 
#method call.  if pass and user are omitted, default to e-mail address 'anonymous'
$ftp->host($host);
$ftp->user($user);
$ftp->pass($pass);

&test2;
#&test3a;

sub test1a { #Anarchie
	$ftp->mkdir('/pub/test1');
	$ftp->mkdir('/pub/test2');
	$ftp->rename('/pub/test3','/pub/test1');
	$ftp->remove('/pub/test2');
	$ftp->list($file2,'/pub/');
	$ftp->sendcommand('DELE /pub/test3');
	$ftp->nlist($file3,'/pub/');
}

sub test1b { #Anarchie
	$ftp->mkdirURL("ftp://$host".'/pub/test1');
	$ftp->mkdirURL("ftp://$host".'/pub/test2');
	$ftp->renameURL('/pub/test3',"ftp://$host/".'/pub/test1');
	$ftp->removeURL("ftp://$host".'/pub/test2');
	$ftp->listURL($file2,"ftp://$host".'/pub/');
	$ftp->sendcommandURL("ftp://$host".'/DELE /pub/test3');
	$ftp->nlistURL($file3,"ftp://$host".'/pub/');
}

sub test2 { #Anarchie
	$ftp->find('.*mac.*perl.*','archie.au',40,1,2);
	$ftp->macsearch('mac-perl');
}

sub test3a { #Anarchie
	$ftp->store($file2,$file);
	$ftp->fetch($file3,$file,0);
	$ftp->remove($file);
}

sub test3b { #Anarchie
	$ftp->storeURL($file2,$url);
	$ftp->fetchURL($file3,$url,0);
	$ftp->removeURL($url);
}

sub test3c { #Anarchie
	$ftp->storeURL($file3,$url);
	$ftp->geturl($url);
	$ftp->geturl($url,$file4);
}

sub test4a { #Fetch
	$ftp->mkdir('/pub/test1');	sleep(2);
	$ftp->rename('/pub/test3','/pub/test1');	sleep(2);
	$ftp->sendcommand('DELE /pub/test3');	sleep(2);
	$ftp->list('nofile','/pub/');	sleep(2);
}

sub test4b { #Fetch
	$ftp->mkdirURL("ftp://$host".'/pub/test1');
	$ftp->renameURL('/pub/test3',"ftp://$host".'/pub/test1');
	$ftp->sendcommandURL("ftp://$host".'/DELE /pub/test3');
	$ftp->listURL('nofile',"ftp://$host".'/pub/');
}

sub test5a { #Fetch
	$ftp->store($file2,$file);
	$ftp->fetch($file4,$file);
	$ftp->remove($file);
}

sub test5b { #Fetch
	$ftp->storeURL($file2,$url);
	$ftp->fetchURL($file4,$url);
	$ftp->removeURL($url);
}

sub test5c { #Fetch
	$ftp->storeURL($file3,$url);
	$ftp->geturl($url);
}



#Try these out as you wish ...
#$ftp->open('Bookmarks');
#$ftp->quit;
#$ftp->showabout;
#$ftp->close;
#$ftp->closeall;
#$ftp->undo;
#$ftp->cut;
#$ftp->copyclip;
#$ftp->paste;
#$ftp->clear;
#$ftp->selectall;
#$ftp->showtranscript;
#$ftp->showarchie;
#$ftp->showget;
#$ftp->updateserverlist;
#$ftp->showlog;
#$ftp->showmacsearch;
#$ftp->showtips;

