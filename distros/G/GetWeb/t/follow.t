#!/usr/bin/perl5

use t::GetWebTest;
t::GetWebTest::go("TEST/promed_old.html FOLLOW 1 FOLLOW 1 GET TEST/promed.html FOLLOW 3");
