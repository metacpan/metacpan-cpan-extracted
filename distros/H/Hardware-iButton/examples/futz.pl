#!/usr/bin/perl -w

use POSIX qw(tcsendbreak);
use IO::File;
$s = new IO::File "+</dev/ttyS8";

$s->blocking(0);
$s->autoflush(1);

sleep(1);

$len = $s->sysread($in, 100);
if ($len) {
    print " got ($len): ";
    print join(',', map {sprintf("0x%02x",$_);} (unpack("C*", $in)));
    print "\n";
}

while (1) {
    print "send: ";
    $in = <>;
    if ($in =~ /^q/) {
	print "quitting\n";
	$s->close();
	exit(0);
    }
    if ($in =~ /^break/) {
	print "sending break..\n";
	tcsendbreak($s, 0);
	$in = '';
    }
    while ($in =~ /^(\w\w)/) {
	$out = hex($1);
	$outstr = sprintf('%c', $out);
	$s->syswrite($outstr, 1);
	printf(" sent 0x%02x\n", $out);
	$in = substr($in, 2);
    }
    sleep(1);
    $len = $s->sysread($in2, 100);
    if ($len) {
	print " got ($len): ";
	print join(',', map {sprintf("0x%02x",$_);} (unpack("C*", $in2)));
	print "\n";
    }
}
