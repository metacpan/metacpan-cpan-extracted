#!/usr/bin/perl
# Show Gbk and UTF-16BE coding

$VERSION = "0.30";

$gbk=$ARGV[0];

if ($gbk eq '') {
	print "Usage: gbkcode.pl <gbkcode>\n" ;
	exit;
}

# Caclulate codes
use Encode;
$gbkcode=$gbk;
Encode::from_to($gbkcode, 'gbk', 'UTF-16BE');
$code=sprintf(
	"%s [%s] <U%s>\n",
	$gbk,
	join ("", map {sprintf "\\x%02X", $_} unpack("C*", $gbk)),
	join ("", map {sprintf "%02X", $_} unpack("C*", $gbkcode)),
	);
print $code;