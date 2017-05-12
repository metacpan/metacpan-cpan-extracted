#!perl -wl
use strict;
use Mac::Comm::OT_PPP;
use Mac::Files;
my($ppp, $user, $pass, $adrs, $otstat);

$ppp = new Mac::Comm::OT_PPP;
$user = 'pudge';
$pass = 'password';
$adrs = '5551212';

$ppp->PPPdisconnect();
$ppp->PPPconnect($user,$pass,$adrs);

$otstat = $ppp->PPPstatus();
print map "$_: $$otstat{$_}\n", keys %$otstat;

print "Please wait while log is saved to desktop ...\n";
$ppp->PPPsavelog(FindFolder(kOnSystemDisk(),kDesktopFolderType()).':ppplog.txt');

print "Done.";
