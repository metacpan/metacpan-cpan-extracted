use strict;
use Test;
BEGIN { plan tests => 2 }
use File::Fingerprint::Huge;

my $fp = File::Fingerprint::Huge->new("t/testdata");

ok($fp);
if(!eval 'require Digest::CRC; Digest::CRC::crc64(12345)'){
	ok(print "CRC64 failed: $!\n");
} else {
	ok($fp->fp_crc64 eq '16850729936921025068' ? 1 : 0, 1);
}

