#!/usr/bin/perl5

my $cgiTest = 't/cgi_test.in';

use t::GetWebTest;

t::GetWebTest::go("","",1,$cgiTest,'cgi');
