#!/usr/bin/perl5

my $quotaTest = 't/quota_test.rfc';

my $quotaPattern = 't/quotaTestRoot/quota/quota*';

system("/bin/rm $quotaPattern 2> /dev/null");

use t::GetWebTest;
$t::GetWebTest::gRoot =~ s/testRoot/quotaTestRoot/
    or die "could not fix gRoot";

t::GetWebTest::go("","",1,$quotaTest,'mail');
