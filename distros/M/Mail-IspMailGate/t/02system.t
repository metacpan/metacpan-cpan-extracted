# -*- perl -*-

use Mail::IspMailGate::Config ();


print "1..2\n";

my $tmpdir = $Mail::IspMailGate::Config::config->{'tmp_dir'};
if (-d $tmpdir) {
    print "ok 1\n";
} else {
    print STDERR ("The directory for temporary files, $tmpdir, doesn't",
		  " exist.\n");
    print "not ok 1\n";
}

my $cfile = "lib/Mail/IspMailGate/Config.pm";
my $uid = $Mail::IspMailGate::Config::config->{'mail_user'};
if ($uid !~ /^\d+$/) {
    $uid = getpwnam($uid)
	or die "Cannot determine UID of $uid, check mail_user in $cfile";
}
my $gid = $Mail::IspMailGate::Config::config->{'mail_group'};
if ($gid !~ /^\d+$/) {
    $gid = getgrnam($gid)
	or die "Cannot determine GID of $gid, check mail_group in $cfile";
}

$) = $( = $gid;
$> = $< = $uid;
if ($> != $uid  ||  $) != $gid) {
    die "Failed to get UID/GID $uid/$gid, have $>/$). You must run me as root.\n";
}
if (-w $tmpdir) {
    print "ok 2\n";
} else {
    print STDERR "Cannot create a file in $tmpdir, check permissions.\n";
    print "not ok 2\n";
}
