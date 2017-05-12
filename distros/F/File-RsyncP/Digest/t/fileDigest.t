# $Id: test.pl,v 1.1 2000/08/27 23:12:24 mikem Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..16\n";}
END {print "not ok 1\n" unless $loaded;}
use File::RsyncP::Digest;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MD4Test;

# 2: Constructor

print (($md4 = new File::RsyncP::Digest) ? "ok 2\n" : "not ok 2\n");

# 3: Basic test data as defined in RFC 1320 (buggy version)

%data26 = (
	 ""	=> "0123456789abcdeffedcba9876543210",
	 "a"	=> "bde52cb31de33e46245e05fbdbd6fb24",
	 "abc"	=> "a448017aaf21d8525fc10ae87aa6729d",
	 "message digest"
		=> "d9130a8164549fe818874806e1c7014b",
	 "abcdefghijklmnopqrstuvwxyz"
		=> "d79e1c308aa5bbcdeea8ed63df412da9",
	 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
		=> "043f8582f241db351ce627e153e7f0e4",
	 "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		=> "e33b4ddc9c38f2199c3e7b164fcc0536",
	 # From draft-ietf-pppext-mschap-00.txt:
	 "\x4D\x00\x79\x00\x50\x00\x77\x00" => "fc156af7edcd6c0edde3337d427f4eac",
);

$failed = 0;
foreach (sort(keys(%data26)))
{
    $md4->reset;
    $md4->protocol(26);
    $md4->add($_);
    $digest = $md4->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne $data26{$_})
    {
	$failed++;
    }
}
print ($failed ? "not ok 3\n" : "ok 3\n");

# 4: Various flavours of file-handle to addfile

open(F, "<$0");

$md4->reset;

$md4->addfile(F);
$hex = $md4->hexdigest;
print ($hex ne '' ? "ok 4\n" : "not ok 4\n");

$orig = $hex;

# 5: Fully qualified with ' operator

seek(F, 0, 0);
$md4->reset;
$md4->addfile(MD4Test'F);
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 5\n" : "not ok 5\n");

# 6: Fully qualified with :: operator

seek(F, 0, 0);
$md4->reset;
$md4->addfile(MD4Test::F);
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 6\n" : "not ok 6\n");

# 7: Type glob

seek(F, 0, 0);
$md4->reset;
$md4->addfile(*F);
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 7\n" : "not ok 7\n");

# 8: Type glob reference (the prefered mechanism)

seek(F, 0, 0);
$md4->reset;
$md4->addfile(\*F);
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 8\n" : "not ok 8\n");

# 9: File-handle passed by name (really the same as 6)

seek(F, 0, 0);
$md4->reset;
$md4->addfile("MD4Test::F");
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 9\n" : "not ok 9\n");

# 10: Other ways of reading the data -- line at a time

seek(F, 0, 0);
$md4->reset;
while (<F>)
{
    $md4->add($_);
}
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 10\n" : "not ok 10\n");

# 11: Input lines as a list to add()

seek(F, 0, 0);
$md4->reset;
$md4->add(<F>);
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 11\n" : "not ok 11\n");

# 12: Random chunks up to 128 bytes

seek(F, 0, 0);
$md4->reset;
while (read(F, $hexata, (rand % 128) + 1))
{
    $md4->add($hexata);
}
$hex = $md4->hexdigest;
print ($hex eq $orig ? "ok 12\n" : "not ok 12\n");

# 13: All the data at once

seek(F, 0, 0);
$md4->reset;
undef $/;
$data = <F>;
$hex = $md4->hexhash($data);
print ($hex eq $orig ? "ok 13\n" : "not ok 13\n");

close(F);

# 14: Using static member function

$hex = File::RsyncP::Digest->hexhash($data);
print ($hex eq $orig ? "ok 14\n" : "not ok 14\n");

# 15: Basic test data as defined in RFC 1320 (non-buggy version)

%data27 = (
	 ""	=> "31d6cfe0d16ae931b73c59d7e0c089c0",
	 "a"	=> "bde52cb31de33e46245e05fbdbd6fb24",
	 "abc"	=> "a448017aaf21d8525fc10ae87aa6729d",
	 "message digest"
		=> "d9130a8164549fe818874806e1c7014b",
	 "abcdefghijklmnopqrstuvwxyz"
		=> "d79e1c308aa5bbcdeea8ed63df412da9",
	 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
		=> "043f8582f241db351ce627e153e7f0e4",
	 "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		=> "e33b4ddc9c38f2199c3e7b164fcc0536",
	 # From draft-ietf-pppext-mschap-00.txt:
	 "\x4D\x00\x79\x00\x50\x00\x77\x00" => "fc156af7edcd6c0edde3337d427f4eac",
);

$failed = 0;
foreach (sort(keys(%data27)))
{
    $md4->reset;
    $md4->protocol(27);
    $md4->add($_);
    $digest = $md4->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne $data27{$_})
    {
	$failed++;
    }
}
print ($failed ? "not ok 15\n" : "ok 15\n");

# 16: test data using both buggy and non-buggy versions

%data27 = (
	 ""	=> "31d6cfe0d16ae931b73c59d7e0c089c0",
	 "a"	=> "bde52cb31de33e46245e05fbdbd6fb24",
	 "abc"	=> "a448017aaf21d8525fc10ae87aa6729d",
	 "message digest"
		=> "d9130a8164549fe818874806e1c7014b",
	 "abcdefghijklmnopqrstuvwxyz"
		=> "d79e1c308aa5bbcdeea8ed63df412da9",
	 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
		=> "043f8582f241db351ce627e153e7f0e4",
	 "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		=> "e33b4ddc9c38f2199c3e7b164fcc0536",
	 # From draft-ietf-pppext-mschap-00.txt:
	 "\x4D\x00\x79\x00\x50\x00\x77\x00" => "fc156af7edcd6c0edde3337d427f4eac",
);

$failed = 0;
foreach (sort(keys(%data27)))
{
    $md4->reset;
    $md4->protocol(27);
    $md4->add($_);
    $digest = $md4->digest2;
    $hex = unpack("H*", $digest);
    if ($hex ne "$data26{$_}$data27{$_}" )
    {
	$failed++;
    }
}
print ($failed ? "not ok 16\n" : "ok 16\n");

