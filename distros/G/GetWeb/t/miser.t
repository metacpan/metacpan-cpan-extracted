#!/usr/bin/perl5

my $miserTest = 't/miser_test.rfc';

use t::GetWebTest;

t::GetWebTest::go("","",1,$miserTest,'mail');
