#!/usr/bin/perl5

use t::GetWebTest;
t::GetWebTest::go("GET TEST/this-is_unavailable.html GET garbage_proto:foo

GET_MISPELLED TEST/promed_new.html");
