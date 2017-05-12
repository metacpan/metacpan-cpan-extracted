use strict;
use Test;
BEGIN { plan tests => 2 }
use File::Fingerprint::Huge;

my $fp = File::Fingerprint::Huge->new("t/testdata");

ok($fp);
if(!eval 'require Digest::CRC; Digest::CRC::crc32(12345)'){
	ok(print "CRC32 failed: $!\n");
} else {
	ok($fp->fp_crc32 eq '2735154984' ? 1 : 0, 1);
}

