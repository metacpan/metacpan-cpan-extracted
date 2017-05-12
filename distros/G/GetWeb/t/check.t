#!/usr/bin/perl5

my $checkTest = 't/check_test.rfc';

use t::GetWebTest;

t::GetWebTest::go("","",1,$checkTest,'mail');
