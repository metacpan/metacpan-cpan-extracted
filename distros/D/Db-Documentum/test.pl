#!/usr/local/bin/perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as `perl test.pl'

### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; $numtests = 15 ; print "\nNumber of test: 1...$numtests\n"; }
END {print "not ok 1 # Modules load.\n" unless $loaded;}
use Db::Documentum qw(:all);
use Db::Documentum::Tools qw(:all);
$loaded = 1;
$|++;
print "ok 1 # Modules load.\n";

### End of black magic.

# print version
Db::Documentum::version;

$counter = 2;
$success = 1;

if (! $OS =~ /Win/i) {
    if (! $ENV{'DMCL_CONFIG'}) {
	    print "Enter the path to your DMCL_CONFIG file: ";
	    chomp ($dmcl_config = <STDIN>);

	    if (-r $dmcl_config) {
	        $ENV{'DMCL_CONFIG'} = $dmcl_config;
	    } else {
	        die "Can't find DMCL_CONFIG '$dmcl_config': $!.  Exiting.";
	    }
	}
    print "Using '$ENV{'DMCL_CONFIG'}' as client config.\n";
}

print "Docbase name: ";
chomp ($docbase = <STDIN>);

print "Username: ";
chomp ($username = <STDIN>);

print "Password (*WARNING* password will be displayed in clear text): ";
chomp ($password = <STDIN>);

# Here's the bulk of the test suite.
print "\n\nTesting Db::Documentum module...\n";

# TEST 2
# Test DM client connect.
do_it("connect,$docbase,$username,$password",NULL,"dmAPIGet",
		"API client connection");

# TEST 3
# Test DM object creation.
do_it("create,c,dm_document",NULL,"dmAPIGet","API object creation");

# TEST 4
# Test DM set
do_it("set,c,last,object_name","Perl Module Test","dmAPISet",
		"API attribute set");
# TEST 5
# Test DM exec
do_it("link,c,last,/Temp",NULL,"dmAPIExec","API object link");

# TEST 6
# Test DM save
do_it("save,c,last",NULL,"dmAPIExec","API save.");

# TEST 7
# Test DM disconnect
do_it("disconnect,c",NULL,"dmAPIExec","API disconnect.");

###
# Here is the Tools.pm test suite
###

print "\n\nTesting Db::Documentum::Tools module...\n";

# TEST 8
# Test dm_LocateServer
$result = dm_LocateServer($docbase);
tally_results($result,"dm_LocateServer($docbase)","Locate Docbase server");

# TEST 9
# Test dm_Connect
$result = dm_Connect($docbase,$username,$password);
tally_results($result,"dm_Connect($docbase,$username)","Connection");

# TEST 10
# Test dm_CreatePath
$result = dm_CreatePath('/Temp/Db-Documentum-Test');
my $folder_id = $result;
tally_results($result,"$folder_id=dm_CreatePath('/Temp/Db-Documentum-Test')","Create a folder");

# TEST 11
# Test dm_CreateType
%ATTRS = (cat_id   =>  'CHAR(16)',
          locale   =>  'CHAR(255) REPEATING');
warn("*WARNING* This test may fail if this script has run more than once\n");
$result = dm_CreateType("my_document","dm_document",%ATTRS);
tally_results($result,"dm_CreateType('my_document')","Create new object type");

# TEST 12
# Test dm_CreateObject
$delim = $Db::Documentum::Tools::Delimiter;
%ATTRS = (object_name =>  'Perl Module Tools Test Doc',
          cat_id      =>  '1-2-3-4-5-6-7',
          locale      =>  'Virginia'.$delim.'California'.$delim.'Ottawa');
$result = dm_CreateObject("my_document",%ATTRS);
my $test_id = $result;
dmAPIExec("link,c,$result,$folder_id");
dmAPIExec("save,c,$result");
tally_results($result,"$test_id=dm_CreateObject(my_document)","Create new object");

# TEST 13
# Test dm_Copy
$result = dm_Copy($test_id);
$result = dm_Copy($test_id,'/Temp/Db-Documentum-Test/Copy-Test');
tally_results($result,"dm_Copy($test_id,/Temp/Db-Documentum-Test/Copy-Test)","Copy object");

# TEST 14
# Test dm_Move
$result = dm_Move($test_id,'/Temp/Db-Documentum-Test/Move-Test');
tally_results($result,"dm_Move($test_id,/Temp/Db-Documentum-Test/Move-Test)","Move object");

# TEST 15
# Test dm_Delete
$result = dm_Delete($folder_id);
tally_results($result,"dm_Delete($folder_id)","Delete object(s)");


dmAPIExec("disconnect,c");

# Test Summary
if ($success == $numtests) {
	print "\nAll tests completed successfully.\n";
} else {
	print "\nAll tests complete.  ", $numtests - $success, " of $numtests tests failed.\n";
	print "If tests fail and the above error output is not helpful check your server logs.\n";
}
exit;


sub do_it {
	my($method,$value,$function,$description) = @_;
	my($result);

	if ($function eq 'dmAPIGet') {
		$result = dmAPIGet($method);
	} elsif ($function eq 'dmAPIExec') {
		$result = dmAPIExec($method);
	} elsif ($function eq 'dmAPISet') {
		$result = dmAPISet($method,$value);
	} else {
		die "$0: Unknown function: $function";
	}

    tally_results($result,$function,$description);
}


sub tally_results {
    my ($r,$f,$d) = @_;

    if (! $r) { print "not "; }
	print "ok $counter # $d [$f]\n";

	if ($r) {
		$success++;
	} else {
	    print "---------------------------\n";
		print dm_LastError("c","3","all");
	    print "---------------------------\n";
	}
	$counter++;
}


