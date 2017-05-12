#!/usr/bin/perl5

my $bounceTest = 't/bounce_test.rfc';

use t::GetWebTest;

t::GetWebTest::go("","",1,$bounceTest,'mail');
