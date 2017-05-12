#!/usr/bin/perl5

use t::GetWebTest;
t::GetWebTest::go("GET <URL:TEST/promed _new.html> GET <TEST/promed _new.html>

GET TEST/promed_\\
new.html",
		  "", 1);
