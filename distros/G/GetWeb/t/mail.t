#!/usr/bin/perl5

my $mailTest = 't/mail_test.rfc';

use t::GetWebTest;

t::GetWebTest::go("","",1,$mailTest,'mail');
