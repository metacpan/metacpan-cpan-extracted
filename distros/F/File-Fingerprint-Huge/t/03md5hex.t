use strict;
use Test;
BEGIN { plan tests => 2 }
use File::Fingerprint::Huge;

my $fp = File::Fingerprint::Huge->new("t/testdata");

ok($fp);
ok($fp->fp_md5hex eq 'f8a75cb074f5555cc3bfb3afbd3b8c6d' ? 1 : 0, 1);
