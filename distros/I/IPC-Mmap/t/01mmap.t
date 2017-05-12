#
#	IPC::Mmap test script
#
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 37;

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok 1\n" unless $loaded;}

#
#	tests:
#	1. load OK
#	2. Create new read/write mmap from filename
#	3. lock it
#	4. write to it
#	5. read from it
#	6. unlock it
#	7. read from it
#	8. destroy it
#	9. create process w/ readonly mmap and read, write
#	10. create process w/ writeonly mmap and read, write
#	11. Repeat using open filehandle (POSIX only)
#	12. Repeat all using threads
#	13. Repeat all using processes: tricky for windows...
#	14. Repeat all using threads in processes
#
#use threads;
#use threads::shared;
use Time::HiRes qw(time);
use IPC::Mmap;
use FileHandle;

use strict;
use warnings;

our $testtype = 'basic filename, single thread, single process';
my $testno = 1;

sub report_result {
	my ($result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $testno # skip $testmsg for $testtype\n" :
			"ok $testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $testno # $testmsg $notokmsg for $testtype\n";
	}
	$testno++;
}

#
#	prelims: use shared test count for eventual
#	threaded tests
#
$loaded = 1;
report_result(1, 'load');
#
#	Deal w/ some peculiarities between Win32 vs. POSIX:
#
my ($mmapflags, $firstfile) = ($^O eq 'MSWin32') ?
	(MAP_SHARED|MAP_ANON, 'win32_test.trace') :
	(MAP_SHARED|MAP_FILE, 'ipc_mmap.tmp');
#
#	open scope, so we can test destroy on exit
#
{

#
#	create w/ filename, but wo/ a backing file
#	(works for both Win32 and POSIX)
#
my $mmap = IPC::Mmap->new($firstfile, 10000,
	PROT_READ|PROT_WRITE, $mmapflags);
report_result(defined($mmap), 'create from filename');

unless (defined($mmap)) {
#	skip the rest
	report_result('skip', 'no mmap, skipping')
		while ($testno <= $tests);
	exit 0;
}
#
#	test accessors
#
my $addr = $mmap->getAddress();
report_result(defined($addr), 'getAddress()');

my $len = $mmap->getLength();
report_result(defined($len) && ($len == 10000), 'getLength()');
#
#	lock it
#
my $result;
#my $result = $mmap->lock();
#report_result($result, 'lock mmap area');
#
#	write to it: no length
#
$result = $mmap->write('A' x 2000, 100);
report_result((defined($result) && ($result == 2000)), 'simple write');
#
#	write to it: short length
#
$result = $mmap->write('B' x 2000, 100, 30);
report_result((defined($result) && ($result == 30)), 'short write');
#
#	write to it: long length
#
$result = $mmap->write('C' x 2000, 100, 300000);
report_result((defined($result) && ($result == 2000)), 'long write');
#
#	write to it: too long length
#
$result = $mmap->write('D' x 20000, 100, );
report_result((defined($result) && ($result == 10000 - 100)), 'too long write');
#
#	write to it: bad offset
#
eval {
	$result = $mmap->write('E' x 200, 200000 );
};
report_result(defined($@) && (!defined($result)), 'bad offset write');
my $value;
#
#	read from it: no length
#
$result = $mmap->read($value, 100);
report_result((defined($result) && ($result == 10000 - 100) &&
	defined($value) && (length($value) == $result)),
	'simple read', '', 'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) );
#
#	read from  it: short length
#
$result = $mmap->read($value, 100, 30);
report_result((defined($result) && ($result == 30) &&
	defined($value) && (length($value) == $result)),
	'short read', '', 'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) );
#
#	read from it: too long length
#
$result = $mmap->read($value, 100, 300000);
report_result((defined($result) && ($result == 10000 - 100) &&
	defined($value) && (length($value) == $result)),
	'long read', '', 'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) );
#
#	read from it: bad offset
#
eval {
	$result = $mmap->read($value, 200000, );
};
report_result(defined($@) && (!defined($result)), 'bad offset read');
#
#	pack something
#
$result = $mmap->pack(1000, 'l n S d a20', 123456, 2345, 5432, 123.456789, 'Z' x 20);
report_result(defined($result) && ($result == 36), 'pack()');

#
#	then unpack it
#
my @vals = $mmap->unpack(1000, 36, 'l n S d a20');
report_result(scalar @vals == 5, 'got 5 values back');
report_result($vals[0] == 123456 , '1st value correct');
report_result($vals[1] == 2345 , '2nd value correct');
report_result($vals[2] == 5432 , '3rd value correct');
report_result($vals[3] == 123.456789 , '4th value correct');
report_result($vals[4] eq ('Z' x 20) , '5th value correct');

#
#	unlock it
#
#$result = $mmap->unlock();
#report_result($result, 'unlock mmap area');
#
#	unmap on exit
#
}
report_result(1, 'unmap');
#
#	open scope, so we can test destroy on exit
{
#
#	now repeat with PROT_READ
#	create w/ filename and *with* a backing file
#
my $mmap = IPC::Mmap->new('ipc_mmap.tmp', 0, PROT_READ, $mmapflags);
report_result(defined($mmap), 'create with backing file');

unless (defined($mmap)) {
#	skip the rest
	report_result('skip', 'no mmap, skipping')
		while ($testno <= $tests);
	exit 0;
}
#
#	lock it
#
my $result = $mmap->lock();
report_result($result, 'lock mmap area');
#
#	write to it: no length
#
eval {
	$result = $mmap->write('A' x 2000, 100);
};
report_result((!defined($result)), 'write to readonly');
#
#	get length
#
my $maplen = $mmap->getLength();
report_result(defined($maplen), 'getLength()');
#
#	get filename
#
my $fname = $mmap->getFilename();
report_result(defined($fname) && ($fname eq 'ipc_mmap.tmp'), 'getFilename()');
#
#	read from it: no length
#
my $value;
$result = $mmap->read($value, 100);
report_result((defined($result) && defined($value) &&
	($result == $maplen - 100) &&
	(length($value) == $result)), 'simple read', '',
	'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) . " result is $result" );
#
#	read from  it: short length
#
$result = $mmap->read($value, 100, 30);
report_result((defined($result) && ($result == 30) &&
	defined($value) && (length($value) == $result)),
	'short read', '', 'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) );
#
#	read from it: too long length
#
$result = $mmap->read($value, 100, 300000);
report_result((defined($result) && 	($result == $maplen - 100) &&
	defined($value) && (length($value) == $result)),
	'long read', '', 'length of value: ' . length($value) .
		' value: ' . substr($value, 0, 20) );
#
#	read from it: bad offset
#
eval {
	$result = $mmap->read($value, 200000, );
};
report_result((!defined($result)), 'bad offset read');
#
#	unlock it
#
$result = $mmap->unlock();
report_result($result, 'unlock mmap area');
#
#	unmap on exit
#
}
report_result(1, 'unmap');
#
#	dispose of file
#
unlink('ipc_mmap.tmp');

if (($^O eq 'darwin') || ($^O=~/bsd/)) {
#	skip the rest
	report_result('skip', "write-only mmap not supported on $^O")
		while ($testno <= $tests);
	exit 0;
}
else
{
#
#	write-only test
#
#	create w/ filename
#
my $mmap = IPC::Mmap->new('ipc_mmap.tmp', 10000, PROT_WRITE, MAP_SHARED|MAP_FILE);
report_result(defined($mmap), 'create from filename');

unless (defined($mmap)) {
#	skip the rest
	report_result('skip', 'no mmap, skipping')
		while ($testno <= $tests);
	exit 0;
}
#
#	lock it
#
my $result = $mmap->lock();
report_result($result, 'lock mmap area');
#
#	write to it: no length
#
$result = $mmap->write('A' x 2000, 100);
report_result((defined($result) && ($result == 2000)), 'simple write');
#
#	read from it: no length
#
my $value;
eval {
	$result = $mmap->read($value, 100);
};
report_result((!defined($result)), 'read to write-only');
#
#	unmap on exit
#
}
report_result(1, 'unmap');

unlink 'ipc_mmap.tmp';
