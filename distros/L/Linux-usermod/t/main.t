use strict;
use Test;

BEGIN { plan tests => 10 }

use Linux::usermod;

my $passwd = "t/passwd";
my $shadow = "t/shadow";
my $group = "t/group";	
my $gshadow = "t/gshadow";	
my $user = "tester";
my $uid = "65000";
my $gid = "65000";
my $comment = "tester account";
my $home = "./";
my $shell = "/dev/null";
my $gname = "noones";
my $users = $user;
my $gadm = $user;

open FH, ">$passwd" or die "can't open $passwd"; close FH;
open FH, ">$shadow" or die "can't open $shadow"; close FH;
open FH, ">$group" or die "can't open $group"; close FH;
open FH, ">$gshadow" or die "can't open $gshadow"; close FH;

$Linux::usermod::file_passwd = $passwd;
$Linux::usermod::file_shadow = $shadow;
$Linux::usermod::file_group = $group;
$Linux::usermod::file_gshadow = $gshadow;

Linux::usermod->add($user, "", $uid, $gid, $comment, $home, $shell);

Linux::usermod->grpadd($gname, $gid, $users);

my $tester = Linux::usermod->new($user);
my $grp = Linux::usermod->new($gname, 1);

$grp->set("ga", $gadm);

ok($tester) or warn "user object creation failed\n";
ok($user,	$tester->get("name")) or warn "\tuser name field unrecognized\n";
ok($uid,	$tester->get("uid")) or warn "\tuid field unrecognized\n";
ok($gid,	$tester->get("gid")) or warn "\tgid field unrecognized\n";
ok($comment,	$tester->get("comment")) or warn "\tcomment field unrecognized\n";
ok($home,	$tester->get("home")) or warn "\thome field unrecognized\n";
ok($shell,	$tester->get("shell")) or warn "\tshell field unrecognized\n";
ok($gname,	$grp->get("name")) or warn "\tgroup name field unrecognized\n";
ok($users,	$grp->get("users")) or warn "\tgroup users field unrecognized\n";
ok($gadm,	$grp->get("ga")) or warn "\tgroup administrator field unrecognized\n";

for($passwd, $shadow, $group, $gshadow){ unlink $_ }
