use strict;
use warnings;
use Test::More qw(no_plan);
use File::Path;
use Data::Dumper;
use EAFDSS;

my($sdir)    = "./signs-testing";
my($sn)      = 'ABC02000001';
my($prm)     = './dummy.eafdss';
my($invoice) = "./invoice.txt";

rmdir($sdir);
mkdir($sdir);

my($dh) = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);

ok(defined $dh, "Defined handle");
ok($dh->isa("EAFDSS::Dummy"),  "Initialized EAFDSS::Dummy device");

my($result);
$result = $dh->Status();
ok($result,  "Operation STATUS");

$result = $dh->Report();
ok($result, "Operation REPORT");

$result = $dh->GetTime();
ok($result, "Operation GET TIME");

$result = $dh->Info();
ok($result, "Operation INFO");

open(INVOICE, ">> $invoice");
print(INVOICE "TEST OpenEAFDSS invoice Document\n");
close(INVOICE); 

$result = $dh->Sign($invoice);
ok($result, "Operation SIGN");

## Check recreation of B files
# Init device
unlink($prm);
$dh = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);
# Empty signs dir
rmtree($sdir);
# Sign a File
$result = $dh->Sign($invoice);
# Delete the b file
opendir(DIR, "$sdir/$sn");
grep { /_b.txt/ && unlink("$sdir/$sn/$_") } readdir(DIR);
closedir DIR;
# Issue a Z report
$dh->Report();
# check that there is one A file, one B file, one C file in dir
opendir(DIR, "$sdir/$sn");
my(@b) = grep { /_b.txt/ && unlink("$sdir/$sn/$_") } readdir(DIR);
closedir DIR;
ok(@b, "B Files recreation");

## Check recreation of C files
# Init device
unlink($prm);
$dh = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);
# Empty signs dir
rmtree($sdir);
# Issue a Z report
$dh->Report();
# check that there one C file in dir
opendir(DIR, "$sdir/$sn");
my(@c) = grep { /_c.txt/ } readdir(DIR);
closedir DIR;
# Empty signs dir
rmtree($sdir);
# Issue a Z report
$dh->Report();
# check that there are 2 C files in dir
opendir(DIR, "$sdir/$sn");
@c = grep { /_c.txt/ } readdir(DIR);
closedir DIR;
is(scalar @c, 2, "C Files recreation");

## check recovery handling
# Init device
unlink($prm);
$dh = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);
# Empty signs dir
rmtree($sdir);
# Sign a File
$result = $dh->Sign($invoice);
# Force CMOS error
$dh->_SetCMOSError();
# Sign a File
$result = $dh->Sign($invoice);
# check that there are two A files, two B file (one with two signatures in it), one C file in dir
opendir(DIR, "$sdir/$sn");
my(@a) = grep { /_a.txt/ } readdir(DIR);
closedir DIR;
my($bTotalSize) = 0;
opendir(DIR, "$sdir/$sn");
@b = grep { /_b.txt/ } readdir(DIR);
closedir DIR;
opendir(DIR, "$sdir/$sn");
@c = grep { /_c.txt/ } readdir(DIR);
closedir DIR;
foreach (@b) {
	$bTotalSize += -s "$sdir/$sn/$_";
}
if ( (scalar @a == 2) && (scalar @b == 2) && (scalar @c == 1) ) {
	pass("Recovery Procedure");
} else {
	fail("Recovery Procedure");
}

unlink($invoice);
unlink($prm);

rmtree($sdir);

exit;
