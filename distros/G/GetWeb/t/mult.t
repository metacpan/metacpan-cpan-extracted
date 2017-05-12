#!/usr/bin/perl5

use t::GetWebTest;
t::GetWebTest::go("
zaxasdflkjqba
begin
TEST/promed_new.html
# GET foo is commented out

TEST/promed_new.html
GET TEST/promed.html
end
GET zxcvasdfsd

");
