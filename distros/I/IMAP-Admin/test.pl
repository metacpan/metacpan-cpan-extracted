# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use IMAP::Admin;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$testuser = "user.testjoebob";
$renameuser = "user.renamedjoebob";

print "Remaining tests require a connection an imap server\n";
print "Please enter the server and the admin user and password at the prompts\n";
print "Enter server: ";
chomp($server = <>);
print "Enter login: ";
chomp($login = <>);
system "stty -echo";
print "Enter password: ";
chomp($password = <>);
print "\n";
system "stty echo";
print "Test using SSL(y/n)? ";
chomp($ssl = <>);
print "Test using CRAM(y/n)? ";
chomp($cram = <>);

if ($cram eq "y") {
    $cram = 1;
} else {
    $cram = 0;
}

if ($ssl ne "n") {
    print  "Enter Port#: ";
    chomp($port = <>);
    $imap = IMAP::Admin->new('Server' => $server, 'Port' => $port,
			     'SSL' => 1, 'SSL_ca_file' => "certs/ca-cert.pem",
			     'Login' => $login, 'Password' => $password,);
} else {
    $imap = IMAP::Admin->new('Server' => $server, 'CRAM' => $cram,
			     'Login' => $login, 'Password' => $password);
}

if ($imap->error ne "No Errors") {
    print $imap->error, "\n";
    exit 0;
}
for ($err = $imap->create($testuser); $err != 0;
     $err = $imap->create($testuser)) {
	print <<EOF;
The user I was testing with ($testuser) already exists.
Please enter a email user that does not exist on $server.
EOF
	print "username: ";
	chomp($testuser = <>);
}
print "ok 2\n";
undef @list;
@list = $imap->list($testuser);
if (@list) {
    print "ok 3: found [@list]\n";
} else {
    print "not ok 3: $imap->{'Error'}\n";
}
if ($imap->{'Capability'} =~ /QUOTA/) {
    print "\nnote: your IMAP server supports QUOTA, going to try and see if I can use them\n";
    $err = $imap->set_quota($testuser, 10000);
    if ($err == 0) {
	print "ok 4\n";
    } else {
	print "not ok 4: $imap->{'Error'}\n";
    }
    undef @quota;
    @quota = $imap->get_quota($testuser);
    if (@quota) {
	print "ok 5: quota was set (@quota)\n";
	$err = $imap->set_quota($testuser, "none");
	if ($err == 0) {
	    print "ok 6: set quota to none\n";
	} else {
	    print "not ok 6: couldn't set quota to none\n";
	}
    } else {
	print "not ok 5 (skipping 6): quota set failed : $imap->{'Error'}\n";
    }
} else {
    print "skipping tests 4-6, your IMAP server doesn't support QUOTA\n";
}
if ($imap->{'Capability'} =~ /ACL/) {
    print "\nnote: your IMAP server supports ACL, setting delete permission\n";
    $err = $imap->set_acl($testuser, $login, "cd"); # create/delete
    if ($err != 0) {
	print "not ok 7: $imap->{'Error'}\n";
    } else {
	undef @acl;
	@acl = $imap->get_acl($testuser);
	if (!(@acl)) {
	    print "not ok 7: $imap->{'Error'}\n";
	} else {
	    print "ok 7: acl string [@acl]\n";
	}
    }
} else {
	print "skipping test 7, your IMAP server doesn't support ACL\n";
}
$err = $imap->delete($testuser);
if ($err == 0) {
    print "ok 8\n";
} else {
    print "not ok 8: $imap->{'Error'}\n";
}
$err = $imap->create($testuser, "default");
if ($err == 0) {
    print "ok 9 : test user created with optional partition set to default\n";
    if ($imap->{'Capability'} =~ /ACL/) {
	$err = $imap->set_acl($testuser, $login, "cd");
    }
} else {
    print "not ok 9: test user with optional partition argument failed, this might not be a problem : $imap->{'Error'}\n";
}

$subf = $testuser.".sub folder";
$err = $imap->create($subf);
if ($err == 0) {
    print "ok 10 : created sub folder (sub folder) for $testuser\n";
    if ($imap->{'Capability'} =~ /ACL/) {
	$err = $imap->set_acl($subf, $login, "cd");
	undef @acl;
	@acl = $imap->get_acl($subf);
	if (!(@acl)) {
		print "test 10 acl failed $imap->{'Error'}\n";
	} else {
		print "  test 10 acl string [@acl] <- should match test 7\n";
	}
    }
} else {
    print "not ok 10 : $imap->{'Error'}\n";
}

$what = $testuser.'.*';
undef @list;
@list = $imap->list($what);
if (!(@list)) {
    print "not ok 11 : sub folder wasn't really created\n";
} else {
    if ($list[0] eq $subf) {
	print "ok 11\n";
    } else {
	print "not ok 11 : something was created (in 10) but didn't get reported correctly [@list]\n";
    }
}
$err = $imap->h_delete($testuser);
if ($err == 0) {
    print "ok 12: hiearchically deleted $testuser\n";
} else {
    print "not ok 12: hiearchical delete failed -- $imap->{'Error'}\n";
}

undef @list;
@list = $imap->list($testuser);
if (!(@list)) {
	print "ok 13: $imap->{'Error'}\n";
} else {
	print "not ok 13: found [@list]\n";
}
$imap->close;
