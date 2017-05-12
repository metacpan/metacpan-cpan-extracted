#!/usr/bin/perl5

my $mailTest = 't/service_test.rfc';

use t::GetWebTest;

t::GetWebTest::go("","",1,$mailTest,'mail');
