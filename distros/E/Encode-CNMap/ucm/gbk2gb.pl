#!/usr/bin/perl
# Generate gb2312-add.dat with given GBK and GB2312 coding

$VERSION = "0.30";

$gbk=$ARGV[0];
$gb2312=$ARGV[1];

if ($gb2312 eq '') {
	print "Usage: gbk2gb.pl <gbkcode> <gb2312code>\n" ;
	exit;
}

# Caclulate codes
use Encode;
$gbkcode=$gbk;
Encode::from_to($gbkcode, 'gbk', 'UTF-16BE');
$code=sprintf(
	"<U%s> %s |1 # %s->%s",
	join ("", map {sprintf "%02X", $_} unpack("C*", $gbkcode)),
	join ("", map {sprintf "\\x%02X", $_} unpack("C*", $gb2312)),
	$gbk,
	$gb2312
	);
print $code;

if( length($gb2312) ne 2 ) {
	printf "   [Error]Len=%d\n", length($gb2312);
	exit -1;
}
if( ord(substr($gb2312,0,1))<=160 or ord(substr($gb2312,1,1))<=160) {
	print "   [Error]Wrong Gb2312";
	exit -1;
}

# Try to find it in gb2312-add.dat
open RDAT, "gb2312-add.dat";
$find=0;
while(<RDAT>) {
	chomp;
	if( $_ eq $code) {
		print "   Exists\n";
		$find=1;
		last;
	}
}
close RDAT;

# If not found, then add it to gb2312-add.dat
if( !$find ) {
	open RDAT, ">>gb2312-add.dat";
	print RDAT $code."\n";
	close RDAT;
	print "   Added\n";
}