#!/usr/bin/perl5

my $spoolTest = 't/spool_test.spool';

use t::GetWebTest;

$ENV{MAILBOT_TEST_COUNT} = 2;
t::GetWebTest::go("","",1,'','spool',$spoolTest);
