
use strict;

use Test;
use File::Storage::Stat;

BEGIN {
    plan tests => 86;
}

my $fss = File::Storage::Stat->new({FilePath => './t/testfile'});

my @ret;
for (my $i = 0;$i < 4200000000;$i += 100000000) {
    $fss->set($i, $i);
    @ret = $fss->get;
    ok($ret[0], $i);
    ok($ret[1], $i);
}

$fss->set(5000000000, -10000);
@ret = $fss->get;
ok($ret[0], 0);
ok($ret[1], 0);
