use strict;
use warnings;
use Test::More;
use ExtUtils::MakeMaker qw( prompt );
use File::Path;
use EAFDSS;

if ($ENV{SERIAL_EMULATOR}) {
	plan tests => 10;
} else {
	plan skip_all => 'set SERIAL_EMULATOR to enable this test';
}

my($sdir)    = "/tmp/signs-testing";
my($sn)      = 'ABC02000001';
my($prm)     = '/dev/ttyS0';
my($invoice) = "/tmp/invoice.txt";

if ($ENV{SERIAL_EMULATOR} =~ /^([A-Z]{3}[0-9]{8})\@(.+)$/ ) {
	$sn = $1;
	$prm = $2;
}
rmdir($sdir);
mkdir($sdir);

my($dh) = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::SDSP::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);

ok(defined $dh, "Defined handle");
ok($dh->isa("EAFDSS::SDSP"),  "Initialized EAFDSS::SDSP device") ||
	diag("ERROR: ", EAFDSS->error());

my($result);
$result = $dh->Status();
ok($result,  "Operation STATUS") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

$result = $dh->Report();
ok($result, "Operation REPORT") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

$result = $dh->GetTime();
ok($result, "Operation GET TIME") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

my($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my($year) = $yearOffset % 100;

$result = $dh->SetTime(sprintf("%02d/%02d/%02d %02d:%02d:%02d", $dayOfMonth, $month+1, $year, $hour, $minute, $second));
is($result, 0, "Operation SET TIME") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

$result = $dh->GetHeaders();
ok($result, "Operation GET HEADERS") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

$result = $dh->SetHeaders("0/H01/0/H02/0/H03/0/H04/0/H05/0/H06");
is($result, 0, "Operation SET HEADERS") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

$result = $dh->Info();
ok($result, "Operation INFO")||
	diag("ERROR: ", $dh->errMessage($dh->error()));

open(INVOICE, ">> $invoice");
print(INVOICE "TEST OpenEAFDSS invoice Document\n");
close(INVOICE); 

$result = $dh->Sign($invoice);
ok($result, "Operation SIGN") ||
	diag("ERROR: ", $dh->errMessage($dh->error()));

unlink($invoice);

rmtree($sdir);

exit;
