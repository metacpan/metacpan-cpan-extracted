# tests for Mail::PopPwd

use strict;
use vars qw($error $check $popserver $user $oldpwd $newpwd $loaded);
use Mail::PopPwd;


BEGIN {
	$| = 1;

	$error = 0;
	print "---Change Password---\n\n";

	print "-->        PwdPopServer: ";
	$popserver = <>;
	chomp $popserver;
	$error = 1 if($popserver =~ /^\s*$/);

	print "-->                User: ";
	$user = <>;
	chomp $user;
	$error = 1 if($user =~ /^\s*$/);

	print "-->            Password: ";
	$oldpwd = <>;
	chomp $oldpwd;
	$error = 1 if($oldpwd =~ /^\s*$/);

	print "-->        New Password: ";
	$newpwd = <>;
	chomp $newpwd;
	$error = 1 if($newpwd =~ /^\s*$/);

	$check = "n";
	print "-->Check Pwd (y/n)? [n]: ";
	my $ncheck = <>;
	chomp $ncheck;
	$check = $ncheck if($ncheck eq "y");

	if($error) {
		print "\nUnknown parameters\n";
		exit();
	}
        print "1..3\n";
}

END { print "not ok 1\n" unless $loaded; }

$loaded = 1;
print "ok 1\n";
my $t = 2;

my $poppwd = Mail::PopPwd->new(
	HOST   => $popserver,
	USER   => $user,
	OLDPWD => $oldpwd, 
	NEWPWD => $newpwd);

if($check eq "s") {
	$error = $poppwd->checkpwd();
	print (($error) ? "not ok $t\n" : "ok $t\n");
} else {
	print "skipped $t: check pwd off\n";
}
$t++;
$error = $poppwd->change();
print (($error) ? "not ok $t\n" : "ok $t\n");
